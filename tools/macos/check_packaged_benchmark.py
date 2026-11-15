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
report = destination/'packaged-benchmark.json'
command = [str((app/'Contents/MacOS'/executable).resolve()), '--audio-driver', 'Dummy', '--resolution', '960x540', '--script', 'res://scripts/diagnostics/render_benchmark.gd', '--', '--suite=presets', '--warmup=8', '--samples=24', '--out='+str(report.resolve())]
with (destination/'packaged-benchmark.log').open('w') as log:
    subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
data = json.loads(report.read_text())
assert len(data['results']) == 6 and data['fixed_fps'] is False
assert data['renderer'] == 'forward_plus'
print('Packaged diagnostic launched and reported all six preset/view combinations.')
