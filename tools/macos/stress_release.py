#!/usr/bin/env python3
"""Bounded exported-app stress; every attempt is retained, never retried to pass.

Cold means a new writable application cache, not a cold OS or an unbaked pack.
Run on a disposable test account/CI runner. Owned cache directories are retained
for inspection; this never clears the player's normal data or modifies the app.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import shutil
import subprocess
import time
import uuid


def inventory(directory):
    files = list(directory.rglob('*')) if directory.exists() else []
    return {'files': sum(p.is_file() for p in files),
            'bytes': sum(p.stat().st_size for p in files if p.is_file())}


def digest(path):
    value = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(chunk)
    return value.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--series', choices=['mixed', 'high', 'low-medium'], default='mixed',
                        help='Run all three series on separate idle runners for the full 3.5.3 matrix.')
    options = parser.parse_args()
    app, out = options.app.resolve(), options.destination.resolve()
    out.mkdir(parents=True, exist_ok=True)
    # Refuse to overwrite an earlier series: a rerun must get its own evidence.
    index = out / 'stress.json'
    if index.exists():
        raise SystemExit('Choose a new output directory; the previous series is retained.')
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    binary = app / 'Contents/MacOS' / info['CFBundleExecutable']
    packs = list((app / 'Contents/Resources').glob('*.pck'))
    if len(packs) != 1:
        raise SystemExit('Expected exactly one exported application pack.')
    # Godot 4.5.1 reads override.cfg beside an explicit --main-pack. Copy the
    # exact pack bytes into a private directory, outside the signed app bundle.
    private = out / 'pack'
    private.mkdir()
    pack = private / packs[0].name
    shutil.copy2(packs[0], pack)
    assert digest(pack) == digest(packs[0])
    token = 'LTO-353-stress-' + uuid.uuid4().hex
    started = time.monotonic()
    wall_start = time.time()
    metadata = {'source': os.environ.get('SOURCE_SHA', ''), 'bundle': info,
                'host': platform.platform(), 'architecture': platform.machine(),
                'pack_sha256': digest(pack), 'resolution': '960x540 windowed',
                'cache_conditions': 'fresh writable app caches; baked shaders retained; OS/driver/filesystem shared',
                'scope': 'exported runtime rendering/lifetime fixtures, not physical M1 acceptance',
                'deadline_seconds': 2400, 'series': options.series, 'runs': []}

    def attempt(name, user_name, script, args, timeout=180, headless=False):
        report = out / (name + '.json')
        user_dir = Path.home() / 'Library/Application Support' / user_name
        assert user_name.startswith(token) and user_dir.name == user_name
        (private / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                               'config/custom_user_dir_name="' + user_name + '"\n')
        command = [str(binary), '--verbose', '--main-pack', str(pack),
                   '--audio-driver', 'Dummy', '--resolution', '960x540',
                   '--position', '32,64', '--script', 'res://scripts/diagnostics/' + script,
                   '--', '--out=' + str(report), *args]
        if headless:
            command.insert(1, '--headless')
        row = {'name': name, 'command': command, 'user_directory': str(user_dir),
               'cache_before': inventory(user_dir / 'shader_cache'), 'rss': []}
        remaining = metadata['deadline_seconds'] - (time.monotonic() - started)
        if remaining < 5:
            row.update(skipped='series deadline exhausted', returncode=None)
        else:
            launch = time.monotonic()
            row['timed_out'] = False
            with (out / (name + '.log')).open('w') as stream:
                process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT)
                try:
                    while process.poll() is None:
                        elapsed = time.monotonic() - launch
                        if elapsed > min(timeout, remaining):
                            row['timed_out'] = True
                            process.kill()
                            process.wait()
                            break
                        memory = subprocess.run(['ps', '-o', 'rss=', '-p', str(process.pid)],
                                                capture_output=True, text=True, timeout=5)
                        if memory.stdout.strip():
                            row['rss'].append({'seconds': elapsed, 'bytes': int(memory.stdout.strip()) * 1024})
                        time.sleep(.5)
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait()
            lines = (out / (name + '.log')).read_text(errors='replace').splitlines()
            row.update(returncode=process.returncode, wall_seconds=time.monotonic()-launch,
                       peak_rss_bytes=max((r['bytes'] for r in row['rss']), default=0),
                       cache_after=inventory(user_dir / 'shader_cache'),
                       cache_events=[line for line in lines if 'PSO cache' in line],
                       device_loss=any('Vulkan device was lost' in line or 'VK_ERROR_DEVICE_LOST' in line
                                       or 'kIOGPUCommandBufferCallbackErrorTimeout' in line for line in lines),
                       diagnostics=[line for line in lines if line.startswith(('ERROR:', 'SCRIPT ERROR:',
                                    'WARNING:', 'Leaked instance:', 'Resource still in use:'))])
            if report.exists():
                try:
                    data = json.loads(report.read_text())
                except (ValueError, OSError) as error:
                    # A crash can interrupt report writing. Preserve that failed
                    # attempt and continue the predetermined remaining matrix.
                    row['report_error'] = str(error)
                    data = {}
                # A failed override would measure the wrong cache and could touch
                # normal settings. Stop the entire series in that case.
                if 'user_data_directory' in data and Path(data['user_data_directory']) != user_dir:
                    row['isolation_error'] = data['user_data_directory']
                if script == 'startup_probe.gd':
                    preset = next(a.split('=', 1)[1] for a in args if a.startswith('--graphics='))
                    row['preset'] = preset
                    frames = data.get('first_frames_ms', [])
                    row['complete'] = (data.get('mission_ready') is True and len(frames) == 30
                                       and data.get('preset') == ['low', 'medium', 'high'].index(preset))
                    row['first_frames_worst_ms'] = max(frames, default=None)
                    row['ready_ms'] = next((e['ticks_ms'] for e in data.get('events', []) if e['phase'] == 'mission_ready'), None)
                elif script == 'integration_benchmark.gd':
                    row['complete'] = len(data.get('results', [])) == 72
                else:
                    row['complete'] = data.get('complete', False) and data.get('failed', 1) == 0
                row['renderer'] = data.get('renderer')
                row['driver'] = data.get('driver')
                if not headless and (row['renderer'], row['driver']) != ('forward_plus', 'vulkan'):
                    row['complete'] = False
                    row['backend_mismatch'] = True
        metadata['runs'].append(row)
        index.write_text(json.dumps(metadata, indent=2))
        print(name, 'exit', row['returncode'], 'complete', row.get('complete', False), flush=True)
        if row.get('isolation_error'):
            raise RuntimeError('Cache isolation failed; entire remaining series cancelled.')
        return row

    probe = attempt('isolation-preflight', token + '-preflight', 'startup_probe.gd',
                    ['--graphics=low'], headless=True)
    if not probe.get('complete') or probe.get('returncode') != 0:
        raise RuntimeError('Cannot verify private application data; stress series not started.')
    # The original 31-process series stays intact. The other two groups bring
    # each cache condition to exactly 20 High, 10 Medium and 10 Low launches.
    presets = {
        'mixed': ['low', 'medium', 'high'] * 3 + ['low'],
        'high': ['high'] * 17,
        'low-medium': ['medium', 'low'] * 6 + ['medium'],
    }[options.series]
    warm = token + '-warm'
    for condition in ['cold', 'warm']:
        if condition == 'warm':
            attempt('warm-seed-matrix', warm, 'integration_benchmark.gd',
                    ['--graphics=low', '--suite=matrix', '--samples=24', '--warmup=8'], 300)
        for number, preset in enumerate(presets, 1):
            name = f'{condition}-{number}'
            attempt(name, token + '-' + name if condition == 'cold' else warm,
                    'startup_probe.gd', ['--graphics=' + preset, '--profile-phases'])
    if options.series == 'mixed':
        for number in range(1, 4):
            attempt(f'cycles-{number}', warm, 'preparation_stress.gd',
                    ['--graphics=low', '--scenario=cycles'], 300)
            attempt(f'exit-preparing-{number}', warm, 'preparation_stress.gd',
                    ['--graphics=high', '--scenario=exit-during-preparation'])
            attempt(f'station-entries-{number}', warm, 'integration_benchmark.gd',
                    ['--graphics=low', '--suite=matrix', '--samples=24', '--warmup=8'], 300)
    # Crash reports are evidence, not a replacement for per-attempt logs.
    reports = Path.home() / 'Library/Logs/DiagnosticReports'
    for path in reports.glob('*'):
        if path.is_file() and path.stat().st_mtime >= wall_start and any(s in path.name.lower() for s in ('godot', 'last train', 'lasttrain')):
            crash = out / 'crash-reports'
            crash.mkdir(exist_ok=True)
            shutil.copy2(path, crash / path.name)
    metadata['complete'] = True
    metadata['wall_seconds'] = time.monotonic() - started
    metadata['passed'] = all(r.get('returncode') == 0 and r.get('complete', False)
                             and not r.get('diagnostics') and not r.get('timed_out', False)
                             and not r.get('device_loss', False) for r in metadata['runs'])
    index.write_text(json.dumps(metadata, indent=2))
    # The pack is already retained in the release artifact. Preserve its hash,
    # override and all measurements without duplicating hundreds of megabytes.
    pack.unlink()
    raise SystemExit(0 if metadata['passed'] else 1)


if __name__ == '__main__':
    main()
