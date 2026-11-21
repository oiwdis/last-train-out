"""Rotate single-factor controls through build 111's normal cold High workload."""
import argparse
import json
from pathlib import Path
import platform
import plistlib
import shutil
import tempfile
import time

from benchmark_release import measure
from compare_environments import digest, select_user

PACK = 'deea300ff4f73d2b3ec76e1dd667d6fb35c5ff8b2637604b164f64934520c138'
LEGACY_FOG = '5b1849a9e6d1daba4577c090e6b978d4bde2cb90df909336f01bd807820cf614'
TREATMENTS = ('control', 'legacy_fog', 'corridor_hidden', 'platform_start')
FIXTURE = Path(__file__).with_name('vulkan_world_probe.gd').resolve()


def read_report(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('legacy_shader', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('--reverse', action='store_true')
    parser.add_argument('--camera-pair', action='store_true',
                        help='Repeat the unmodified and platform-first cameras 16 times each.')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    contents = args.app.resolve() / 'Contents'
    shader = args.legacy_shader.resolve()
    original, = (contents / 'Resources').glob('*.pck')
    info = plistlib.loads((contents / 'Info.plist').read_bytes())
    if digest(original) != PACK or digest(shader) != LEGACY_FOG:
        raise ValueError('Expected the signed build 111 data and the PR 6 fog shader.')
    started = time.time()
    rows = []
    treatments = ('control', 'platform_start') if args.camera_pair else TREATMENTS
    repeats = 32 // len(treatments)
    summary = {'host': platform.platform(), 'bundle': info, 'pack_sha256': PACK,
               'legacy_shader_sha256': LEGACY_FOG, 'fixture_sha256': digest(FIXTURE),
               'reverse': args.reverse, 'treatments': treatments, 'repeats_per_treatment': repeats,
               'runs': rows, 'complete': False}
    options = treatments[::-1] if args.reverse else treatments
    with tempfile.TemporaryDirectory(prefix='lto-world-cold-') as tmp:
        project = Path(tmp)
        pack = project / original.name
        shutil.copyfile(original, pack)
        assert digest(pack) == PACK
        for repeat in range(repeats):
            offset = repeat % len(options)
            for arm in options[offset:] + options[:offset]:
                name = f'{repeat + 1:02d}-{arm}'
                user = select_user(project, project.name + '-' + name)
                assert not user.exists()
                flags = ['--graphics=high', '--profile-phases', '--treatment=' + arm]
                if arm == 'legacy_fog':
                    flags.append('--legacy-shader=' + str(shader))
                row = measure(str(contents / 'MacOS' / info['CFBundleExecutable']), project,
                              out, name, FIXTURE, flags, 180, ['--main-pack', str(pack)], user / 'shader_cache')
                records = out / (name + '.json.world.jsonl')
                marks = [json.loads(line) for line in records.read_text().splitlines()] if records.exists() else []
                if any(Path(mark['user_dir']) != user for mark in marks):
                    raise RuntimeError('Private app data was not selected.')
                changed = next((m['affected'] for m in marks if m['phase'] == 'prepare'), -1)
                applied = changed == 0
                if arm == 'legacy_fog':
                    applied = changed == 6
                elif arm == 'corridor_hidden':
                    applied = changed > 0
                elif arm == 'platform_start':
                    applied = applied and any(m['phase'] == 'platform_camera' for m in marks)
                record = read_report(out / (name + '.json'))
                ready = (record.get('mission_ready') is True and record.get('preset') == 2
                         and (record.get('renderer'), record.get('driver')) == ('forward_plus', 'vulkan')
                         and len(record.get('first_frames_ms', [])) == 30)
                messages = row['engine_diagnostics']
                row.update(treatment=arm, markers=marks, treatment_applied=applied,
                           device_loss=any('VK_ERROR_DEVICE_LOST' in m or 'device was lost' in m
                                           or 'kIOGPUCommandBufferCallbackErrorTimeout' in m for m in messages),
                           passed=(applied and ready and row['returncode'] == 0 and
                                   not row['timed_out'] and not messages))
                rows.append(row)
                (out / 'series.json').write_text(json.dumps(summary, indent=2) + '\n')
    for path in (Path.home() / 'Library/Logs/DiagnosticReports').glob('*.ips'):
        if path.stat().st_mtime >= started and 'last train out' in path.name.lower():
            crash = out / 'crash-reports'
            crash.mkdir(exist_ok=True)
            shutil.copy2(path, crash / path.name)
    summary['complete'] = True
    (out / 'series.json').write_text(json.dumps(summary, indent=2) + '\n')
    return int(any(not row['passed'] for row in rows))


if __name__ == '__main__':
    raise SystemExit(main())
