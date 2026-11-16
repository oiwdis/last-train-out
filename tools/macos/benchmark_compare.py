#!/usr/bin/env python3
"""Matched source revisions on hosted Mac; not a physical 2020 M1 result."""
import json
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path

root = Path(__file__).resolve().parents[2]
probe_enabled = '--skin-probe' in sys.argv[1:]
godot, original, previous, destination = [arg for arg in sys.argv[1:] if arg != '--skin-probe']
output = Path(destination).resolve()
output.mkdir(parents=True, exist_ok=True)
host = {'platform': platform.platform(), 'machine': platform.machine(),
        'requested_resolution': '(960, 540)', 'samples': 600, 'warmup_frames': 120,
        'scope': 'hosted windowed runner; not physical 2020 M1 fullscreen'}
(output/'host.json').write_text(json.dumps(host, indent=2))
for name, project in [('final26', root), ('milestone25', Path(original).resolve()), ('previous26', Path(previous).resolve())]:
    # Run identical diagnostics, including warmup, against every source revision.
    if project != root:
        (project/'scripts/diagnostics').mkdir(exist_ok=True)
        shutil.copy2(root/'scripts/diagnostics/render_benchmark.gd', project/'scripts/diagnostics/render_benchmark.gd')
        shutil.copy2(root/'tools/benchmark_milestone25.gd', project/'tools/benchmark_milestone25.gd')
        shutil.copy2(root/'tools/profile_finalization.gd', project/'tools/profile_finalization.gd')
    for suite in ['presets', 'route'] + ([] if name == 'milestone25' else ['ablations']):
        stem = name+'-'+suite
        script = 'tools/profile_finalization.gd' if suite == 'ablations' else 'tools/benchmark_milestone25.gd'
        command = [godot, '--path', str(project), '--audio-driver', 'Dummy', '--resolution', '960x540', '--position', '32,64', '--script', script, '--', '--suite='+suite, '--samples=600', '--warmup=120', '--out='+str(output/(stem+'.json'))]
        with (output/(stem+'.log')).open('w') as log:
            subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=300)
        result = json.loads((output/(stem+'.json')).read_text())
        assert result['fixed_fps'] is False
        assert result['resolution'] == host['requested_resolution'], 'desktop resized the benchmark window'
        assert len(result['results']) == {'presets':6, 'route':3, 'ablations':12}[suite]
        print(stem, result['processor'], result['adapter'], result['renderer'])
        for row in result['results']:
            print(row.get('view', 'Warehouse B'), row['case'], 'median_ms', row.get('median_frame_ms', row.get('median_ms')), 'p95_ms', row.get('p95_frame_ms', row.get('p95_ms')))

# The unsafe optional effect was isolated in run 24. Do not routinely leave its
# Metal compiler service work competing with release validation after a timeout.
if not probe_enabled:
    sys.exit(0)

# Explicit forensic mode: isolate the separate-specular render path.
# A bounded diagnostic timeout is evidence, not a successful game benchmark.
probe = [godot, '--path', str(root), '--audio-driver', 'Dummy', '--resolution', '960x540',
         '--script', 'tools/profile_finalization.gd', '--', '--suite=skin_probe',
         '--samples=24', '--warmup=8', '--out='+str(output/'skin-probe.json')]
started = time.monotonic()
with (output/'skin-probe.log').open('w') as log:
    process = subprocess.Popen(probe, stdout=log, stderr=subprocess.STDOUT)
    try:
        code = process.wait(timeout=90)
        status = {'completed':code == 0, 'exit_code':code, 'timed_out':False}
    except subprocess.TimeoutExpired:
        try:
            subprocess.run(['sample', str(process.pid), '3', '-file', str(output/'skin-probe-stack.txt')],
                           stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT, timeout=12)
        except (OSError, subprocess.TimeoutExpired):
            pass
        finally:
            process.kill()
            process.wait()
        status = {'completed':False, 'timed_out':True, 'timeout_seconds':90}
status['elapsed_seconds'] = time.monotonic()-started
status['scope'] = 'Diagnostic only: skin scattering is disabled in shipped presets.'
(output/'skin-probe-status.json').write_text(json.dumps(status, indent=2))
print('Optional skin-scattering probe:', status)
