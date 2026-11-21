"""Compare only the first fog camera on later High switches in the signed build 117."""
import argparse
import json
import platform
import plistlib
import shutil
import tempfile
import time
from pathlib import Path

from benchmark_release import measure
from compare_environments import digest, select_user
from compare_vulkan_world import read_report

PACK = '9a0c1163fce19c8469777e99d2619530692ff21e091d013774a6b87149a7feb0'
FIXTURE = Path(__file__).with_name('vulkan_preset_probe.gd').resolve()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--reverse', action='store_true')
    args = parser.parse_args()
    contents = args.app.resolve() / 'Contents'
    info = plistlib.loads((contents / 'Info.plist').read_bytes())
    binary = contents / 'MacOS' / info['CFBundleExecutable']
    original, = (contents / 'Resources').glob('*.pck')
    if digest(original) != PACK or str(info['LTOBuildNumber']) != '117':
        raise ValueError('Expected the unmodified build 117 game pack.')
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    order = ['every_high', 'startup_only']
    if args.reverse:
        order.reverse()
    rows = []
    summary = {'host': platform.platform(), 'reverse': args.reverse, 'pack_sha256': PACK,
               'executable_sha256': digest(binary), 'fixture_sha256': digest(FIXTURE),
               'runs': rows, 'complete': False}
    started = time.time()
    with tempfile.TemporaryDirectory(prefix='lto-preset-camera-') as temp:
        project = Path(temp)
        pack = project / original.name
        shutil.copyfile(original, pack)
        for index in range(4):
            for policy in (order if index % 2 == 0 else order[::-1]):
                name = f'{index + 1:02d}-{policy}'
                user = select_user(project, project.name + '-' + name)
                if user.exists():
                    raise RuntimeError('Expected a fresh application data directory.')
                flags = ['--graphics=low', '--scenario=cycles', '--profile-phases']
                if policy == 'startup_only':
                    flags.append('--startup-camera-only')
                row = measure(str(binary), project, out, name, FIXTURE, flags, 360,
                              ['--main-pack', str(pack)], user / 'shader_cache')
                file = out / (name + '.json.cameras.jsonl')
                cameras = [json.loads(line) for line in file.read_text().splitlines()] if file.exists() else []
                if any(Path(camera['user_dir']) != user for camera in cameras):
                    raise RuntimeError('Application data isolation failed.')
                high = [camera for camera in cameras if camera['preset'] == 2]
                applied = bool(high) and all(camera['preparation'] > 1 and not camera['origin_before']
                                             and camera['origin_after'] == (policy == 'startup_only') for camera in high)
                report = read_report(out / (name + '.json'))
                healthy = (report.get('complete') and report.get('failed') == 0 and
                           report.get('driver') == 'vulkan' and report.get('scenario') == 'cycles')
                row.update(policy=policy, later_high_views=len(high), treatment_observed=applied,
                           device_loss=any('device was lost' in s or 'VK_ERROR_DEVICE_LOST' in s
                                           or 'kIOGPUCommandBufferCallbackErrorTimeout' in s for s in row['engine_diagnostics']),
                           passed=bool(applied and len(high) >= 3 and healthy and row['returncode'] == 0
                                       and not row['timed_out'] and not row['engine_diagnostics']))
                rows.append(row)
                (out / 'series.json').write_text(json.dumps(summary, indent=2) + '\n')
    for report in (Path.home() / 'Library/Logs/DiagnosticReports').glob('*.ips'):
        if report.stat().st_mtime >= started and 'last train out' in report.name.lower():
            folder = out / 'crash-reports'
            folder.mkdir(exist_ok=True)
            shutil.copy2(report, folder / report.name)
    summary['complete'] = True
    (out / 'series.json').write_text(json.dumps(summary, indent=2) + '\n')
    return int(any(not row['passed'] for row in rows))


if __name__ == '__main__':
    raise SystemExit(main())
