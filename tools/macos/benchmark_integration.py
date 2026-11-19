#!/usr/bin/env python3
"""Matched source-head comparisons and twelve-location matrix on one hosted Mac."""
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import time

godot, art, survival, destination = sys.argv[1:]
root = Path(__file__).resolve().parents[2]
out = Path(destination).resolve()
out.mkdir(parents=True, exist_ok=True)
(out / 'host.json').write_text(json.dumps({
    'platform': platform.platform(), 'machine': platform.machine(),
    'cpu_count': os.cpu_count(), 'samples': 600, 'warmup': 120,
    'scope': 'hosted Mac, 960x540 windowed; NOT physical 2020 M1 fullscreen',
    'source_heads': {'art': 'a8f58ec57c218c3944d038a9d1640e78597042be',
                     'survival': '9c4f0de49e104ca95ccb57c88cf535ab96202dac'},
    'integration_commit': os.environ.get('SOURCE_SHA', os.environ.get('GITHUB_SHA', ''))
}, indent=2))
for name, project, suites in [('integration', root, ['matrix', 'ablations']),
                              ('source-art', Path(art), ['harlow']),
                              ('source-survival', Path(survival), ['harlow'])]:
    diagnostic = project / 'scripts/diagnostics/integration_benchmark.gd'
    if project != root:
        diagnostic.parent.mkdir(exist_ok=True)
        shutil.copy2(root / 'scripts/diagnostics/integration_benchmark.gd', diagnostic)
    for suite in suites:
        stem = name + '-' + suite
        command = [godot, '--path', str(project), '--audio-driver', 'Dummy',
                   '--resolution', '960x540', '--position', '32,64',
                   '--script', str(diagnostic), '--', '--suite=' + suite,
                   '--samples=600', '--warmup=120', '--graphics=low',
                   '--out=' + str(out / (stem + '.json'))]
        if name == 'integration' and suite == 'matrix':
            command.append('--shots=' + str(out / 'screenshots'))
        rss = []
        started = time.monotonic()
        with (out / (stem + '.log')).open('w') as stream:
            process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT)
            try:
                while process.poll() is None:
                    if time.monotonic() - started > 900:
                        raise TimeoutError(stem + ' exceeded 15 minutes')
                    memory = subprocess.run(['ps', '-o', 'rss=', '-p', str(process.pid)],
                                            capture_output=True, text=True)
                    if memory.stdout.strip():
                        rss.append({'seconds': round(time.monotonic()-started, 2),
                                    'bytes': int(memory.stdout.strip())*1024})
                    time.sleep(.5)
                assert process.returncode == 0, stem
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()
        result = json.loads((out / (stem + '.json')).read_text())
        assert result['fixed_fps'] is False and result['resolution'] == '(960, 540)'
        expected = {'matrix': 36, 'harlow': 15, 'ablations': 9}[suite]
        assert len([r for r in result['results'] if r['stage'] == 'steady']) == expected
        assert 'SCRIPT ERROR' not in (out / (stem + '.log')).read_text()
        (out / (stem + '-rss.json')).write_text(json.dumps({
            'peak_process_rss_bytes': max(row['bytes'] for row in rss),
            'wall_seconds': time.monotonic()-started, 'samples': rss}, indent=2))
        print(stem, result['adapter'], result['driver'], 'peak RSS MiB', max(r['bytes'] for r in rss)/2**20, flush=True)
