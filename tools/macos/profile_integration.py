#!/usr/bin/env python3
"""Exploratory evidence only: unchanged gameplay, native phase traces and stacks.

Timing runs and sampling-profiler runs are separate; sampled runs are never used
as matched FPS evidence. Failures and partial logs remain on disk.
"""
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import time
import threading

from renderer_diagnostics import engine_diagnostics

godot, destination = sys.argv[1:3]
suite = sys.argv[3] if len(sys.argv) > 3 else 'all'
root = Path(__file__).resolve().parents[2]
out = Path(destination).resolve()
out.mkdir(parents=True, exist_ok=True)
metadata = {'source': os.environ.get('SOURCE_SHA', ''), 'platform': platform.platform(),
            'processor_count': os.cpu_count(), 'scope': 'hosted exploratory investigation; not physical M1',
            'runs': []}


def run(name, script, arguments, timeout=900, capture_stacks=False):
    report = out / (name + '.json')
    phase_file = out / (name + '-stage.json')
    command = [godot, '--verbose', '--path', str(root), '--audio-driver', 'Dummy',
               '--resolution', '960x540', '--script', 'res://scripts/diagnostics/' + script,
               '--', '--graphics=low', '--profile-phases', '--out=' + str(report), *arguments]
    if capture_stacks:
        command.append('--trace-stage=' + str(phase_file))
    rss, samplers, observed = [], [], set()
    arrivals = []
    started = time.monotonic()
    with (out / (name + '.log')).open('w') as log:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        def consume():
            for line in process.stdout:
                log.write(line)
                # Include cache saves and driver errors, not just our phase labels.
                # Arrival time is approximate (engine stdout may be buffered).
                arrivals.append({'process_wall_ms': (time.monotonic()-started)*1000, 'line': line.rstrip()})
                log.flush()
        reader = threading.Thread(target=consume)
        reader.start()
        try:
            while process.poll() is None:
                elapsed = time.monotonic() - started
                if elapsed > timeout:
                    process.kill()
                    process.wait()
                    break
                memory = subprocess.run(['ps', '-o', 'rss=', '-p', str(process.pid)], capture_output=True, text=True)
                if memory.stdout.strip():
                    rss.append({'seconds': elapsed, 'bytes': int(memory.stdout.strip()) * 1024})
                if capture_stacks and phase_file.exists():
                    try:
                        phase = json.loads(phase_file.read_text())['phase']
                    except (ValueError, KeyError):
                        phase = ''
                    targets = {'High/Harlow platform/entry': 3, 'High/Near advancing fog/steady': 10}
                    if phase in targets and phase not in observed and platform.system() == 'Darwin':
                        observed.add(phase)
                        label = phase.replace('/', '-').replace(' ', '_')
                        stream = (out / (name + '-' + label + '-sample-command.log')).open('w')
                        sample = subprocess.Popen(['sample', str(process.pid), str(targets[phase]), '2',
                                                   '-file', str(out / (name + '-' + label + '.sample.txt'))],
                                                  stdout=stream, stderr=subprocess.STDOUT)
                        samplers.append((sample, stream))
                time.sleep(.05 if capture_stacks else .5)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            for sample, stream in samplers:
                try:
                    sample.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    sample.kill()
                    sample.wait()
                stream.close()
            reader.join(timeout=10)
    text = (out / (name + '.log')).read_text()
    status = {'name': name, 'command': command, 'returncode': process.returncode,
              'wall_seconds': time.monotonic() - started, 'sampling_profiler': capture_stacks,
              'report_exists': report.exists(), 'peak_rss_bytes': max((r['bytes'] for r in rss), default=0),
              'engine_diagnostics': engine_diagnostics(text.splitlines())}
    (out / (name + '-process.json')).write_text(json.dumps({'status': status, 'rss': rss, 'stdout_arrival_timeline': arrivals}, indent=2))
    metadata['runs'].append(status)
    (out / ('investigation-' + suite + '.json')).write_text(json.dumps(metadata, indent=2))
    print(name, 'exit', process.returncode, 'report', report.exists(), flush=True)


if suite in ('all', 'startup'):
    # First windowed process on a fresh runner, then warm launches. Imported
    # assets/filesystem caches are already warm; this is not a cold filesystem.
    for attempt in range(3):
        run('startup-' + str(attempt + 1), 'startup_probe.gd', [], timeout=240)
if suite in ('all', 'matrix'):
    for attempt in range(2):
        run('baseline-matrix-' + str(attempt + 1), 'integration_benchmark.gd',
            ['--suite=matrix', '--samples=600', '--warmup=120'])
    run('sampled-matrix', 'integration_benchmark.gd',
        ['--suite=matrix', '--samples=600', '--warmup=120'], capture_stacks=True)
if suite == 'cleanup':
    for attempt in range(3):
        run('cleanup-' + str(attempt + 1), 'integration_benchmark.gd',
            ['--suite=matrix', '--samples=24', '--warmup=8'])
if suite in ('quick', 'preparation'):
    run('entry-probe', 'integration_benchmark.gd',
        ['--suite=matrix', '--samples=24', '--warmup=8'], timeout=300)
if any(r['returncode'] != 0 or not r['report_exists'] or r['engine_diagnostics'] for r in metadata['runs']):
    raise SystemExit(1)
