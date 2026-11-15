#!/usr/bin/env python3
"""Matched source revisions on hosted Mac; not a physical 2020 M1 result."""
import json
import platform
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
godot, original, previous, destination = sys.argv[1:]
output = Path(destination).resolve()
output.mkdir(parents=True, exist_ok=True)
host = {'platform': platform.platform(), 'machine': platform.machine(),
        'requested_resolution': '(960, 540)', 'samples': 120, 'warmup_frames': 60,
        'scope': 'hosted windowed runner; not physical 2020 M1 fullscreen'}
(output/'host.json').write_text(json.dumps(host, indent=2))
for name, project in [('milestone25', Path(original).resolve()), ('previous26', Path(previous).resolve()), ('final26', root)]:
    # Run identical diagnostics, including warmup, against every source revision.
    if project != root:
        (project/'scripts/diagnostics').mkdir(exist_ok=True)
        shutil.copy2(root/'scripts/diagnostics/render_benchmark.gd', project/'scripts/diagnostics/render_benchmark.gd')
        shutil.copy2(root/'tools/benchmark_milestone25.gd', project/'tools/benchmark_milestone25.gd')
        shutil.copy2(root/'tools/profile_finalization.gd', project/'tools/profile_finalization.gd')
    for suite in ['presets', 'route'] + ([] if name == 'milestone25' else ['ablations']):
        stem = name+'-'+suite
        script = 'tools/profile_finalization.gd' if suite == 'ablations' else 'tools/benchmark_milestone25.gd'
        command = [godot, '--path', str(project), '--audio-driver', 'Dummy', '--resolution', '960x540', '--position', '32,64', '--script', script, '--', '--suite='+suite, '--samples=120', '--warmup=60', '--out='+str(output/(stem+'.json'))]
        with (output/(stem+'.log')).open('w') as log:
            subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=300)
        result = json.loads((output/(stem+'.json')).read_text())
        assert result['fixed_fps'] is False
        assert result['resolution'] == host['requested_resolution'], 'desktop resized the benchmark window'
        assert len(result['results']) == {'presets':6, 'route':3, 'ablations':12}[suite]
        print(stem, result['processor'], result['adapter'], result['renderer'])
        for row in result['results']:
            print(row.get('view', 'Warehouse B'), row['case'], 'median_ms', row.get('median_frame_ms', row.get('median_ms')), 'p95_ms', row.get('p95_frame_ms', row.get('p95_ms')))
