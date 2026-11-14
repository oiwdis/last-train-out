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
host = {'platform': platform.platform(), 'machine': platform.machine(),
        'requested_resolution': '(960, 540)',
        'scope': 'hosted windowed runner; not physical 2020 M1 fullscreen'}
(output/'host.json').write_text(json.dumps(host, indent=2))
matched_resolution = None
for name, project in [('before', Path(baseline).resolve()), ('after', root)]:
    command = [godot, '--path', str(project), '--audio-driver', 'Dummy', '--resolution', '960x540', '--position', '32,64', '--script', 'res://tools/benchmark_milestone25.gd', '--', '--suite=presets', '--samples=24', '--out='+str(output/(name+'.json'))]
    with (output/(name+'.log')).open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=240)
    result = json.loads((output/(name+'.json')).read_text())
    assert result['fixed_fps'] is False
    # Stay below the hosted desktop's usable bounds; its window manager can
    # otherwise clamp successive windows to slightly different heights.
    assert result['resolution'] == host['requested_resolution'], 'desktop resized the benchmark window'
    if matched_resolution is None:
        matched_resolution = result['resolution']
    assert result['resolution'] == matched_resolution, 'before/after viewport sizes differ'
    host['actual_resolution'] = matched_resolution
    (output/'host.json').write_text(json.dumps(host, indent=2))
    assert len(result['results']) == 6
    print(name, result['processor'], result['adapter'], result['renderer'])
    for row in result['results']:
        print(row['view'], row['case'], 'median_ms', row['median_frame_ms'], 'p95_ms', row['p95_frame_ms'])
