"""Counterbalance packaged, fresh-user native Metal launches and exercise the normal loading scene."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import time
import uuid

from benchmark_release import measure
from stress_release import digest
from renderer_diagnostics import engine_diagnostics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('first', choices=('seed', 'local'))
    parser.add_argument('baseline', type=Path, help='Freshly downloaded verified 3.5.3 final app')
    options = parser.parse_args()
    app, out = options.app.resolve(), options.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    resources = app / 'Contents/Resources'
    pack, = resources.glob('*.pck')
    chooser = str(app / 'Contents/MacOS/choose-renderer')
    profile = plistlib.loads((resources / 'MetalShaders/Profile.plist').read_bytes())
    token = 'LTO-354-startup-' + uuid.uuid4().hex
    order = [options.first, 'local' if options.first == 'seed' else 'seed']
    attempts = []
    with tempfile.TemporaryDirectory() as tmp:
        folder = Path(tmp)
        target = folder / pack.name
        shutil.copy2(pack, target)

        def select(name):
            user = token + '-' + name
            (folder / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                                 f'config/custom_user_dir_name="{user}"\n')
            return Path.home() / 'Library/Application Support' / user

        previous = options.baseline.resolve()
        original, = (previous / 'Contents/Resources').glob('*.pck')
        if digest(original) != '4ef40667bc6c00acc93a5b5eb5ccdfb28c609573815c351288435e00fd5af2d5':
            raise RuntimeError('The 3.5.3 control pack is not the verified final PCK.')
        previous_pack = folder / 'original.pck'
        shutil.copy2(original, previous_pack)
        previous_info = plistlib.loads((previous / 'Contents/Info.plist').read_bytes())
        previous_binary = str(previous / 'Contents/MacOS' / previous_info['CFBundleExecutable'])

        def baseline(condition):
            user = select('original')
            name = 'original-' + condition
            record = measure(previous_binary, folder, out, name, 'startup_probe.gd',
                             ['--graphics=high', '--profile-phases'], 210,
                             ['--main-pack', str(previous_pack), '--rendering-method', 'forward_plus', '--rendering-driver', 'metal'],
                             user / 'shader_cache')
            data = json.loads((out / (name + '.json')).read_text()) if record['report_exists'] else {}
            record['passed'] = (not record['returncode'] and record.get('mission_ready') and not record['engine_diagnostics']
                                and data.get('driver') == 'metal' and data.get('user_data_directory') == str(user))
            attempts.append(record)
            (out / 'startup.json').write_text(json.dumps(attempts, indent=2))

        flags = ['metal', '--main-pack', str(target)]
        for stage in ('cold', 'warm'):
            prior_first = (options.first == 'local') == (stage == 'cold')
            if prior_first: baseline(stage)
            for mode in order if stage == 'cold' else reversed(order):
                user = select(mode)
                os.environ['LTO_METAL_SHADER_SEED'] = '1' if mode == 'seed' else '0'
                name = stage + '-' + mode
                record = measure(chooser, folder, out, name, 'startup_probe.gd', ['--graphics=high', '--profile-phases'],
                                 200, flags, user / 'shader_cache')
                report = out / (name + '.json')
                data = json.loads(report.read_text()) if report.exists() else {}
                log = (out / (name + '.log')).read_text(errors='replace')
                record['passed'] = (not record['returncode'] and record.get('mission_ready') and not record['engine_diagnostics']
                                    and data.get('driver') == 'metal' and data.get('user_data_directory') == str(user))
                record['cache_selection'] = [s for s in log.splitlines() if s.startswith('[renderer] Metal shader')]
                if mode == 'seed' and stage == 'cold':
                    record['passed'] &= any(f"{len(profile['files'])} installed, 0 existing, 0 unavailable" in msg
                                             for msg in record['cache_selection'])
                if mode == 'local':
                    record['passed'] &= any('compiling locally' in msg for msg in record['cache_selection'])
                attempts.append(record)
                (out / 'startup.json').write_text(json.dumps(attempts, indent=2))
            if not prior_first: baseline(stage)
        # Compare the former origin fog view against the same seeded geometry
        # on an already-conditioned host. Both use fresh writable directories.
        for mode in (('origin', 'platform') if options.first == 'seed' else ('platform', 'origin')):
            user = select('camera-' + mode)
            os.environ['LTO_METAL_SHADER_SEED'] = '1'
            os.environ['LTO_METAL_WARMUP_CONTROL'] = '1' if mode == 'origin' else '0'
            name = 'camera-' + mode
            record = measure(chooser, folder, out, name, 'startup_probe.gd', ['--graphics=high', '--profile-phases'],
                             200, flags, user / 'shader_cache')
            data = json.loads((out / (name + '.json')).read_text()) if record['report_exists'] else {}
            record['passed'] = (not record['returncode'] and record.get('mission_ready') and not record['engine_diagnostics']
                                and data.get('driver') == 'metal' and data.get('user_data_directory') == str(user))
            attempts.append(record)
            (out / 'startup.json').write_text(json.dumps(attempts, indent=2))
        os.environ.pop('LTO_METAL_WARMUP_CONTROL', None)
        # Exercise the player's threaded loading scene and real transition, on
        # a separate private cache. Only the final diagnostic observer exits.
        os.environ.pop('LTO_METAL_SHADER_SEED', None)
        user = select('normal')
        for n in (1, 2, 3):
            name = 'player-entry-' + str(n)
            dest = out / (name + '.json')
            cmd = [chooser, *flags, '--resolution', '960x540', '--audio-driver', 'Dummy', '--verbose',
                   'res://scenes/main/journey_loading.tscn', '--', '--graphics=high', '--profile-phases',
                   '--lto-launch-report=' + str(dest)]
            with (out / (name + '.log')).open('w') as log:
                proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
                try:
                    if n == 3:
                        # Keep the profiled repetition separate from ordinary timing.
                        time.sleep(1)
                        subprocess.run(['sample', str(proc.pid), '4', '10', '-file', str(out / 'player-entry.sample.txt')],
                                       stdout=log, stderr=subprocess.STDOUT, timeout=20)
                    proc.wait(timeout=210)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()
            data = json.loads(dest.read_text()) if dest.exists() else {}
            diag = engine_diagnostics((out / (name + '.log')).read_text(errors='replace').splitlines())
            attempts.append({'name':name, 'returncode':proc.returncode, 'profiled':n == 3, 'diagnostics':diag,
                             'passed':proc.returncode == 0 and not diag and data.get('ready') is True
                             and data.get('driver') == 'metal' and data.get('user_dir') == str(user)
                             and bool(data.get('load', {}).get('progress'))})
            (out / 'startup.json').write_text(json.dumps(attempts, indent=2))
    print('Packaged shader groups:', len(profile['files']), 'attempts:', [(r['name'], r['passed']) for r in attempts])
    return int(any(not r['passed'] for r in attempts))


if __name__ == '__main__':
    raise SystemExit(main())
