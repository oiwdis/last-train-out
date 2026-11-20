"""Sample the packaged Metal player across Warehouse A entry and repeat without observers."""
import argparse
import json
from pathlib import Path
import platform
import plistlib
import shutil
import subprocess
import tempfile
import time
import uuid

from benchmark_release import measure
from metal_trace import metal_signposts
from renderer_diagnostics import engine_diagnostics
from stress_release import digest


TARGETS = {
    'Low/Warehouse A/entry', 'Medium/Warehouse A/entry', 'High/Warehouse A/entry',
    'Low/Locomotive cab/steady',
}
MATRIX_ARGS = ['--suite=matrix', '--samples=180', '--warmup=60']


def capture(chooser, pack, out):
    marker = out / 'active-stage.json'
    report = out / 'sampled.json'
    cmd = [str(chooser), 'metal', '--main-pack', str(pack), '--path', str(pack.parent), '--verbose',
           '--audio-driver', 'Dummy', '--resolution', '960x540', '--position', '32,64',
           '--script', 'res://scripts/diagnostics/integration_benchmark.gd', '--', '--graphics=low',
           '--out=' + str(report), '--trace-stage=' + str(marker), *MATRIX_ARGS]
    stages, samples = {}, {}
    deadline = time.monotonic() + 600
    with metal_signposts(out), (out / 'sampled.log').open('w') as log, (out / 'sampler.log').open('w') as sampler_log:
        player = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
        try:
            while player.poll() is None and time.monotonic() < deadline:
                try:
                    stage = json.loads(marker.read_bytes())
                except (FileNotFoundError, ValueError):
                    time.sleep(.01)
                    continue
                phase = stage['phase']
                if phase not in stages:
                    stages[phase] = dict(stage, marker_wall_ns=marker.stat().st_mtime_ns, observer_wall_ns=time.time_ns())
                    if phase in TARGETS:
                        name = phase.lower().replace('/', '-').replace(' ', '-')
                        samples[phase] = subprocess.Popen(['/usr/bin/sample', str(player.pid), '1', '2',
                            '-file', str(out / (name + '.sample.txt'))], stdout=sampler_log, stderr=subprocess.STDOUT)
                time.sleep(.01)
        finally:
            timed_out = player.poll() is None
            if timed_out:
                player.kill()
            player.wait()
            codes = {}
            for phase, sampler in samples.items():
                try:
                    codes[phase] = sampler.wait(timeout=12)
                except subprocess.TimeoutExpired:
                    sampler.kill()
                    codes[phase] = sampler.wait()
    return dict(command=cmd, pid=player.pid, code=player.returncode, timed_out=timed_out, stages=stages,
                samplers=codes, diagnostics=engine_diagnostics((out / 'sampled.log').read_text(errors='replace').splitlines()))


def reached_all_views(path):
    if not path.is_file():
        return False
    data = json.loads(path.read_bytes())
    return (data.get('driver') == 'metal' and data.get('renderer') == 'forward_plus'
            and data.get('runtime_binary') == 'LastTrainOutMetal' and len(data.get('results', [])) == 72)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    opt = parser.parse_args()
    if platform.system() != 'Darwin' or platform.machine() != 'arm64':
        parser.error('This experiment uses the native Apple Silicon Metal player.')
    app, out = opt.app.resolve(), opt.output.resolve()
    out.mkdir(parents=True)
    chooser = app / 'Contents/MacOS/choose-renderer'
    resources = app / 'Contents/Resources'
    original, = resources.glob('*.pck')
    user = 'LTO-Metal-Entry-' + uuid.uuid4().hex
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    result = dict(build=info['LTOBuildNumber'], revision=info['LTOBuildCommit'], host=platform.platform(),
                  note='Sampled first on the fresh host. Timing acceptance uses the independent unprofiled release matrix.')
    result['pack_sha256'] = digest(original)
    with tempfile.TemporaryDirectory() as work:
        pack = Path(work) / original.name
        shutil.copy2(original, pack)
        (pack.parent / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + user + '"\n')
        profiled = capture(chooser, pack, out)
        result['sampled'] = profiled
        (out / 'entry-profile.json').write_text(json.dumps(result, indent=2))
        result['unprofiled'] = measure(str(chooser), pack.parent, out, 'repeat', 'integration_benchmark.gd', MATRIX_ARGS, 600,
                                       ['metal', '--main-pack', str(pack)], Path.home() / 'Library/Application Support' / user / 'shader_cache')
    result['complete'] = (profiled['code'] == 0 and not profiled['diagnostics'] and not profiled['timed_out']
                          and set(profiled['samplers']) == TARGETS and not any(profiled['samplers'].values())
                          and len(list(out.glob('*.sample.txt'))) == len(TARGETS)
                          and reached_all_views(out / 'sampled.json') and reached_all_views(out / 'repeat.json')
                          and result['unprofiled']['returncode'] == 0 and not result['unprofiled']['engine_diagnostics'])
    (out / 'entry-profile.json').write_text(json.dumps(result, indent=2))
    return int(not result['complete'])


if __name__ == '__main__':
    raise SystemExit(main())
