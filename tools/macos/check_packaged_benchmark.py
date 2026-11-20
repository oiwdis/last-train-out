#!/usr/bin/env python3
"""Check that a freshly downloaded app includes the manual M1 diagnostic."""
import json
import plistlib
import subprocess
import sys
from pathlib import Path

from renderer_diagnostics import engine_diagnostics

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
    diagnostics = engine_diagnostics(lines)
    assert not diagnostics, 'Packaged diagnostic emitted errors/warnings: ' + '\n'.join(diagnostics)
    data = json.loads(report.read_text())
    assert len(data['results']) == count and data['fixed_fps'] is False
    driver = data.get('driver', data.get('rendering_driver'))
    assert (data['renderer'], driver) == ('forward_plus', 'vulkan'), 'Fresh app used a different graphics backend'
    print('Packaged diagnostic reported', count, suite, 'cases.')
