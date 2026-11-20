#!/usr/bin/env python3
"""Paired 3.5.1 comparison on one host; retain every raw and failed attempt.

Fresh project/user caches per revision, then repeated warm processes. Alternate
revision order. OS/driver caches are not claimed cold or independently isolated.
No sampling profiler, screenshots, fixed FPS, or Movie Maker in timing runs.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import time

from renderer_diagnostics import engine_diagnostics

BASELINE = '7df2f5abee54b8adcf27b8668263fba231a79033'
ROOT = Path(__file__).resolve().parents[2]


def cache_inventory(cache):
    files = list(cache.rglob('*')) if cache.exists() else []
    return {'files': sum(p.is_file() for p in files),
            'bytes': sum(p.stat().st_size for p in files if p.is_file())}


def measure(godot, project, out, name, script, args, timeout, engine_args=(), cache=None):
    report = out / (name + '.json')
    command = [godot, *engine_args, '--verbose', '--path', str(project), '--audio-driver', 'Dummy',
               '--resolution', '960x540', '--position', '32,64', '--script',
               'res://scripts/diagnostics/' + script, '--', '--graphics=low',
               '--out=' + str(report), *args]
    if cache is None:
        cache = project / '.godot' / 'shader_cache'
    before = cache_inventory(cache)
    rss = []
    started = time.monotonic()
    timed_out = False
    with (out / (name + '.log')).open('w') as stream:
        process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT)
        try:
            while process.poll() is None:
                elapsed = time.monotonic() - started
                if elapsed > timeout:
                    timed_out = True
                    process.kill()
                    process.wait()
                    break
                memory = subprocess.run(['ps', '-o', 'rss=', '-p', str(process.pid)],
                                        capture_output=True, text=True)
                if memory.stdout.strip():
                    rss.append({'seconds': elapsed, 'bytes': int(memory.stdout.strip()) * 1024})
                time.sleep(.5)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
    lines = (out / (name + '.log')).read_text().splitlines()
    diagnostics = engine_diagnostics(lines)
    result = {'name': name, 'command': command, 'returncode': process.returncode,
              'timed_out': timed_out, 'wall_seconds': time.monotonic() - started,
              'report_exists': report.exists(), 'peak_rss_bytes': max((r['bytes'] for r in rss), default=0),
              'shader_cache_before': before, 'shader_cache_after': cache_inventory(cache),
              'pipeline_cache_events': [line for line in lines if 'PSO cache' in line],
              'shader_cache_misses': sum('Shader cache miss' in line for line in lines),
              'shader_cache_hits': sum('Shader cache hit' in line for line in lines),
              'shader_variants_loaded': sum('Loading cache for shader' in line for line in lines),
              'engine_diagnostics': diagnostics, 'rss': rss}
    if report.exists():
        try:
            data = json.loads(report.read_text())
        except (ValueError,OSError) as error:
            data = {}
            result['report_error'] = str(error)
        if script == 'integration_benchmark.gd':
            result['complete_matrix'] = (len(data.get('results',[])) == 72 and
                                         data['resolution'] == '(960, 540)' and
                                         data['fixed_fps'] is False)
        else:
            result['mission_ready'] = data.get('mission_ready',False)
    (out / (name + '-process.json')).write_text(json.dumps(result, indent=2))
    print(name, 'exit', process.returncode, 'timeout', timed_out, 'diagnostics', len(diagnostics), flush=True)
    return result


def prepare(godot, revision, name, scratch, out):
    project = scratch / name
    project.mkdir()
    archive = scratch / (name + '.tar')
    subprocess.run(['git', 'fetch', '--no-tags', '--depth=1', 'origin', revision], cwd=ROOT, check=True)
    with archive.open('wb') as stream:
        subprocess.run(['git', 'archive', revision], cwd=ROOT, stdout=stream, check=True)
    subprocess.run(['tar', '-xf', str(archive), '-C', str(project)], check=True)
    archive.unlink()
    imports = project / '.godot' / 'imported'
    # Reuse only source-validated imported assets, never the comparison shader cache.
    shutil.copytree(ROOT / '.godot' / 'imported', imports, copy_function=shutil.copy2)
    for scene in imports.glob('*.scn'):
        scene.unlink()
    for helper in ['integration_benchmark.gd', 'frame_timeline.gd', 'startup_probe.gd', 'performance_trace.gd', 'scene_retirement.gd']:
        shutil.copy2(ROOT / 'scripts' / 'diagnostics' / helper, project / 'scripts' / 'diagnostics' / helper)
    user_name = 'LTO-351-' + scratch.name + '-' + name
    (project / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                         'config/custom_user_dir_name="' + user_name + '"\n')
    with (out / (name + '-import.log')).open('w') as stream:
        subprocess.run([godot, '--headless', '--path', str(project), '--import'],
                       stdout=stream, stderr=subprocess.STDOUT, check=True, timeout=300)
    text = (out / (name + '-import.log')).read_text()
    if any(line.startswith(('ERROR:', 'SCRIPT ERROR:')) for line in text.splitlines()):
        raise RuntimeError(name + ' import errors; raw log retained')
    return project


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('godot')
    parser.add_argument('destination', type=Path)
    parser.add_argument('--repeats', type=int, default=2)
    options = parser.parse_args()
    out = options.destination.resolve()
    out.mkdir(parents=True, exist_ok=True)
    current = os.environ.get('SOURCE_SHA') or subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    metadata = {'baseline': BASELINE, 'optimized': current, 'host': platform.platform(),
                'architecture': platform.machine(), 'processor_count': os.cpu_count(),
                'resolution': '960x540', 'samples': 600, 'settling_frames': 120,
                'scope': 'hosted windowed fixtures; not physical M1 or continuous gameplay',
                'cache_conditions': 'separate fresh project/user caches, warm filesystem; shared OS/driver caches uncontrolled',
                'diagnostic_sha256': hashlib.sha256((ROOT / 'scripts/diagnostics/integration_benchmark.gd').read_bytes()).hexdigest(),
                'runs': []}
    def retain(result):
        metadata['runs'].append(result)
        (out / 'comparison.json').write_text(json.dumps(metadata, indent=2))
    with tempfile.TemporaryDirectory(prefix='lto-m351-') as directory:
        scratch = Path(directory)
        projects = {name: prepare(options.godot, revision, name, scratch, out)
                    for name, revision in [('baseline', BASELINE), ('optimized', current)]}
        for attempt in range(3):
            for name in (['baseline', 'optimized'] if attempt % 2 == 0 else ['optimized', 'baseline']):
                retain(measure(options.godot, projects[name], out, name + '-startup-' + str(attempt + 1),
                               'startup_probe.gd', ['--profile-phases'], 240))
        for attempt in range(options.repeats):
            for name in (['baseline', 'optimized'] if attempt % 2 == 0 else ['optimized', 'baseline']):
                stem = name + '-matrix-' + str(attempt + 1)
                retain(measure(options.godot, projects[name], out, stem,
                               'integration_benchmark.gd', ['--suite=matrix', '--samples=600', '--warmup=120'], 900))
                if name == 'optimized' and attempt == 0 and (out / (stem + '.json')).exists():
                    shutil.copy2(out / (stem + '.json'), out / 'integration-matrix.json')
    # The baseline's existing cache/shutdown errors remain evidence. They do
    # not excuse an error in the candidate, or a missing baseline measurement.
    if any(r['returncode'] or not r['report_exists'] or
           (r['name'].startswith('optimized-') and r['engine_diagnostics']) or
           not r.get('complete_matrix', r.get('mission_ready', False)) for r in metadata['runs']):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
