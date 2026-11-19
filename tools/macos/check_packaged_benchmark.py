#!/usr/bin/env python3
"""Check that a freshly downloaded app includes the manual M1 diagnostic."""
import json
import plistlib
import subprocess
import sys
from pathlib import Path
app, destination = map(Path, sys.argv[1:])
destination.mkdir(parents=True, exist_ok=True)
with (app/'Contents/Info.plist').open('rb') as f:
    executable = plistlib.load(f)['CFBundleExecutable']
for suite, count in [('presets', 6), ('route', 3), ('matrix', 72)]:
    report = destination/('packaged-benchmark-'+suite+'.json')
    script = 'integration_benchmark.gd' if suite == 'matrix' else 'render_benchmark.gd'
    command = [str((app/'Contents/MacOS'/executable).resolve()), '--audio-driver', 'Dummy', '--resolution', '960x540', '--script', 'res://scripts/diagnostics/'+script, '--', '--suite='+suite, '--warmup=8', '--samples=24', '--out='+str(report.resolve())]
    with (destination/('packaged-benchmark-'+suite+'.log')).open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
    lines = (destination/('packaged-benchmark-'+suite+'.log')).read_text().splitlines()
    diagnostics = [line for line in lines if line.startswith(('ERROR:', 'SCRIPT ERROR:',
                   'WARNING:', 'Leaked instance:', 'Resource still in use:'))]
    assert not diagnostics, 'Packaged diagnostic emitted errors/warnings: ' + '\n'.join(diagnostics)
    data = json.loads(report.read_text())
    assert len(data['results']) == count and data['fixed_fps'] is False
    assert data['renderer'] == 'forward_plus'
    print('Packaged diagnostic reported', count, suite, 'cases.')
