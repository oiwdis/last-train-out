#!/usr/bin/env python3
"""Run matched windowed samples on the hosted Mac; never substitute these for a user's M1."""
import json
import platform
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
godot, baseline, output = sys.argv[1:]
output = Path(output).resolve()
output.mkdir(parents=True, exist_ok=True)
(output/'host.json').write_text(json.dumps({'platform': platform.platform(), 'machine': platform.machine(), 'scope': 'hosted runner, 1280x720 window; not physical 2020 M1 fullscreen'}, indent=2))
for name, project in [('before', Path(baseline).resolve()), ('after', root)]:
    command = [godot, '--path', str(project), '--audio-driver', 'Dummy', '--resolution', '1280x720', '--script', 'res://tools/benchmark_milestone25.gd', '--', '--suite=presets', '--samples=24', '--out='+str(output/(name+'.json'))]
    with (output/(name+'.log')).open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=240)
    result = json.loads((output/(name+'.json')).read_text())
    assert result['fixed_fps'] is False and result['resolution'] == '(1280, 720)'
    assert len(result['results']) == 6
    print(name, result['processor'], result['adapter'], result['renderer'])
    for row in result['results']:
        print(row['view'], row['case'], 'median_ms', row['median_frame_ms'], 'p95_ms', row['p95_frame_ms'])
