#!/usr/bin/env python3
"""Compare both Forward+ drivers from one universal pack on an Apple Silicon host."""
import argparse
import json
from pathlib import Path
import platform
import plistlib
import shutil
import tempfile
import time
import uuid

from benchmark_release import measure
from stress_release import digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('out', type=Path)
    options = parser.parse_args()
    app, out = options.app.resolve(), options.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    binary = str(app / 'Contents/MacOS' / info['CFBundleExecutable'])
    pack, = (app / 'Contents/Resources').glob('*.pck')
    start = time.time()
    token = 'LTO-353-drivers-' + uuid.uuid4().hex
    summary = {
        'pack_sha256': digest(pack), 'os': platform.platform(), 'runs': [], 'preflights': [],
        'complete': False, 'samples': 180, 'settling_frames': 60, 'resolution': '960x540',
    }
    index = out / 'drivers.json'
    with tempfile.TemporaryDirectory(prefix='lto353-drivers-') as temp:
        directory = Path(temp)
        target = directory / pack.name
        shutil.copy2(pack, target)
        assert digest(target) == summary['pack_sha256']
        # Reverse driver order on the second timing pass. Capture separately.
        attempts = [
            ('vulkan', 'matrix-1'), ('metal', 'matrix-1'), ('metal', 'matrix-2'),
            ('vulkan', 'matrix-2'), ('vulkan', 'visual'), ('metal', 'visual'),
        ]
        for driver, stage in attempts:
            name = driver + '-' + stage
            user = token + '-' + driver
            (directory / 'override.cfg').write_text(
                '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + user + '"\n'
            )
            cache = Path.home() / 'Library/Application Support' / user / 'shader_cache'
            flags = ['--main-pack', str(target), '--rendering-method', 'forward_plus', '--rendering-driver', driver]
            if stage == 'matrix-1':
                probe = driver + '-isolation'
                record = measure(binary, directory, out, probe, 'startup_probe.gd', [], 60, ['--headless', *flags], cache)
                summary['preflights'].append(record)
                index.write_text(json.dumps(summary, indent=2))
                if record['returncode'] or not record.get('mission_ready'):
                    raise RuntimeError('Headless isolation preflight failed.')
                preflight = json.loads((out / (probe + '.json')).read_text())
                if Path(preflight['user_data_directory']).name != user:
                    raise RuntimeError('Export did not use its private writable directory.')
            args = ['--suite=matrix', '--samples=180', '--warmup=60']
            if stage == 'visual':
                args = ['--suite=matrix', '--samples=24', '--warmup=8', '--shots=' + str(out / (driver + '-shots'))]
            chooser = app / 'Contents/MacOS/choose-renderer'
            executable = str(chooser) if chooser.exists() else binary
            render_flags = [driver, '--main-pack', str(target)] if chooser.exists() else flags
            row = measure(executable, directory, out, name, 'integration_benchmark.gd', args, 600, render_flags, cache)
            report = out / (name + '.json')
            data = json.loads(report.read_text()) if report.exists() and not row.get('report_error') else {}
            row['actual'] = [data.get('renderer'), data.get('driver')]
            row['passed'] = (row['returncode'] == 0 and row.get('complete_matrix', False)
                             and row['actual'] == ['forward_plus', driver] and not row['engine_diagnostics'])
            summary['runs'].append(row)
            index.write_text(json.dumps(summary, indent=2))
    for report in (Path.home() / 'Library/Logs/DiagnosticReports').glob('*.ips'):
        if report.stat().st_mtime >= start and 'last train' in report.name.lower():
            (out / 'crash-reports').mkdir(exist_ok=True)
            shutil.copy2(report, out / 'crash-reports' / report.name)
    summary['complete'] = True
    index.write_text(json.dumps(summary, indent=2))
    return int(any(not row['passed'] for row in summary['runs']))


if __name__ == '__main__':
    raise SystemExit(main())
