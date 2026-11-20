#!/usr/bin/env python3
"""Controlled Godot 4.5.1 rendering experiments. Writes only new evidence and temporary projects."""
import argparse
import difflib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
BASE = '7df2f5abee54b8adcf27b8668263fba231a79033'
M351 = 'cc50670c9ae70aa2de7ce92185a229d284c075f8'
M352 = '6038bfcd0f0c5427ae6c53435d2867282938f6e4'
BACKENDS = {'forward_plus': 'vulkan', 'mobile': 'vulkan', 'gl_compatibility': 'opengl3'}
FILES = ['project.godot', 'icon.svg', 'icon.svg.import', 'assets', 'resources', 'scenes', 'scripts', 'systems']
DIAGNOSTICS = ['startup_probe.gd', 'frame_timeline.gd', 'performance_trace.gd',
               'scene_retirement.gd', 'integration_benchmark.gd']


def make_project(scratch, revision, godot, out):
    project = scratch / revision
    project.mkdir()
    if revision == 'minimal':
        shutil.copy2(ROOT / 'tools/macos/renderer_probe.gd', project)
        shutil.copy2(ROOT / 'scripts/fog/fog_front.gdshader', project)
        (project / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Renderer Probe"\n')
        return project
    with tempfile.TemporaryFile() as archive:
        subprocess.run(['git', 'archive', revision, '--', *FILES], cwd=ROOT, stdout=archive, check=True)
        archive.seek(0)
        subprocess.run(['tar', 'xf', '-', '-C', str(project)], stdin=archive, check=True)
    # Share validated expensive texture bytes. Scene imports and class caches
    # are rebuilt per source tree. Driver/shader caches are never copied here.
    imports = project / '.godot/imported'
    shutil.copytree(ROOT / '.godot/imported', imports, ignore=shutil.ignore_patterns('*.scn'))
    for script in DIAGNOSTICS:
        shutil.copy2(ROOT / 'scripts/diagnostics' / script, project / 'scripts/diagnostics' / script)
    log = out / ('import-' + revision[:7] + '.log')
    with log.open('w') as stream:
        subprocess.run([godot, '--headless', '--path', str(project), '--import'],
                       stdout=stream, stderr=subprocess.STDOUT, check=True, timeout=600)
    if any(line.startswith(('ERROR:', 'SCRIPT ERROR:')) for line in log.read_text().splitlines()):
        raise RuntimeError('Import failed: ' + str(log))
    return project


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError('Workload checkout does not contain the expected source: ' + old)
    return text.replace(old, new)


def workload(project, variant, originals, out):
    """Single-factor modifications to a disposable 6038 checkout. Save the exact diff."""
    paths = ['scripts/presentation/render_warmup.gd', 'resources/graphics/high.tres']
    warmup, high = (originals[key] for key in paths)
    if variant == 'quarter-pixels':
        warmup = replace_once(warmup, 'var _scene: Node3D', 'var saved_scale: float\nvar _scene: Node3D')
        warmup = replace_once(warmup, '_camera.make_current()', 'saved_scale = viewport.scaling_3d_scale\n\tviewport.scaling_3d_scale = minf(saved_scale, 0.35)\n\t_camera.make_current()')
        warmup = replace_once(warmup, '_original.make_current()', '_original.get_viewport().scaling_3d_scale = saved_scale\n\t\t_original.make_current()')
    elif variant == 'no-views':
        warmup = replace_once(warmup, 'job._begin(scene)', 'job._finish.call_deferred()')
    elif variant == 'one-draw':
        warmup = replace_once(warmup, '_view_frames = _frames_required', '_view_frames = 1')
    elif variant == 'no-proxy':
        warmup = replace_once(warmup, '_frame_signal.connect(_on_frame)', '_sources.clear()\n\t_frame_signal.connect(_on_frame)')
    elif variant == 'no-local-shadows':
        high = replace_once(high, 'local_shadows = true', 'local_shadows = false')
    elif variant == 'no-msaa':
        high = replace_once(high, 'msaa = 1', 'msaa = 0')
    elif variant == 'no-ssao':
        high = replace_once(high, 'ssao = true', 'ssao = false')
    for path, source in zip(paths, [warmup, high]):
        target = project / path
        if target.read_text() != source:
            target.write_text(source)
        if source != originals[path]:
            (out / (variant + '.diff')).write_text(''.join(difflib.unified_diff(
                originals[path].splitlines(True), source.splitlines(True), 'a/' + path, 'b/' + path)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('godot')
    parser.add_argument('group', choices=['minimal', 'workload', 'history', 'backends'])
    parser.add_argument('out', type=Path)
    parser.add_argument('--repeats', type=int, default=3)
    opt = parser.parse_args()
    if not 1 <= opt.repeats <= 8:
        parser.error('repeats must be between 1 and 8')
    out = opt.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    start = time.time()
    token = 'LTO-353-lab-' + uuid.uuid4().hex
    rows = []
    metadata = {'group':opt.group, 'head':subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip(),
                'machine':platform.platform(), 'cpus':os.cpu_count(), 'engine':subprocess.check_output([opt.godot,'--version'], text=True).strip(),
                'repeats':opt.repeats, 'resolution':'960x540', 'runs':rows, 'complete':False}
    index = out / 'series.json'

    def attempt(project, name, script, args, cache, backend='forward_plus', variant='control',
                gpu_debug=False, cold=True, timeout=180):
        # project and all cache directories belong to this invocation only.
        user = token + '-' + cache
        override = '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + user + '"\n[rendering]\n'
        if variant == 'shader-cache-off':
            override += 'shader_compiler/shader_cache/enabled=false\n'
        if variant == 'pso-off':
            override += 'rendering_device/pipeline_cache/enable=false\n'
        (project / 'override.cfg').write_text(override)
        if cold:
            shutil.rmtree(project / '.godot/shader_cache', ignore_errors=True)
        report = out / (name + '.json')
        log = out / (name + '.log')
        cmd = [opt.godot, '--verbose', '--path', str(project), '--audio-driver', 'Dummy',
               '--rendering-method', backend, '--rendering-driver', BACKENDS[backend],
               '--resolution', '960x540', '--position', '32,64']
        if gpu_debug:
            cmd.append('--gpu-validation')
        cmd += ['--script', 'res://' + script, '--', '--out=' + str(report), *args]
        env = os.environ.copy()
        if gpu_debug and platform.system() == 'Darwin':
            env['MTL_DEBUG_LAYER'] = '1'
        row = {'name':name, 'revision':project.name, 'variant':variant, 'method':backend,
               'driver':BACKENDS[backend], 'cold':cold, 'cache':cache, 'command':cmd, 'validation':gpu_debug}
        began = time.monotonic()
        peak = 0
        with log.open('w') as stream:
            proc = subprocess.Popen(cmd, stdout=stream, stderr=subprocess.STDOUT, env=env)
            try:
                while proc.poll() is None:
                    if time.monotonic() - began >= timeout:
                        row['timeout'] = True
                        proc.kill()
                        break
                    rss = subprocess.run(['ps', '-o', 'rss=', '-p', str(proc.pid)], capture_output=True, text=True)
                    if rss.stdout.strip().isdigit():
                        peak = max(peak, int(rss.stdout.strip()) * 1024)
                    time.sleep(.4)
            finally:
                if proc.poll() is None:
                    proc.kill()
                proc.wait()
        lines = log.read_text(errors='replace').splitlines()
        row.update(code=proc.returncode, seconds=time.monotonic()-began, peak_rss=peak,
                   device_loss=any('device was lost' in l.lower() or 'kIOGPUCommandBufferCallbackErrorTimeout' in l for l in lines),
                   diagnostics=[l for l in lines if l.startswith(('ERROR:', 'SCRIPT ERROR:', 'WARNING:', '[mvk-error]'))],
                   cache_events=[l for l in lines if 'PSO cache' in l])
        data = {}
        if report.exists():
            try:
                data = json.loads(report.read_text())
            except (ValueError, OSError) as error:
                # Preserve interrupted reports without truncating the test matrix.
                row['report_error'] = str(error)
        actual = data.get('actual_method', data.get('renderer'))
        driver = data.get('actual_driver', data.get('driver'))
        row.update(actual=actual, actual_driver=driver, adapter=data.get('adapter'),
                   valid_backend=(actual, driver) == (backend, BACKENDS[backend]))
        if 'user_data_directory' in data and Path(data['user_data_directory']).name != user:
            raise RuntimeError('Process did not use its assigned private cache')
        row['complete'] = bool(data.get('complete') or data.get('mission_ready') or len(data.get('results', [])) == 72)
        row['ready_ms'] = next((e['ticks_ms'] for e in data.get('events', []) if e['phase'] == 'mission_ready'), data.get('ready_ms'))
        rows.append(row)
        index.write_text(json.dumps(metadata, indent=2))
        print(name, row['code'], row['complete'], row['device_loss'], round(row['seconds'],2), flush=True)

    with tempfile.TemporaryDirectory(prefix='lto353-lab-') as tmp:
        scratch = Path(tmp)
        revisions = [BASE, M351, M352] if opt.group == 'history' else ['minimal' if opt.group == 'minimal' else M352]
        projects = {r:make_project(scratch,r,opt.godot,out) for r in revisions}
        project = projects[revisions[0]]
        probe = 'scripts/diagnostics/startup_probe.gd'
        matrix = 'scripts/diagnostics/integration_benchmark.gd'
        startup = ['--graphics=high', '--profile-phases']
        matrix_args = ['--graphics=low', '--suite=matrix', '--samples=180', '--warmup=60']
        if opt.group == 'minimal':
            cases = ['control','no-preparation','batch','no-fog','medium','shader-cache-off','pso-off',
                     'preupload','early-retire','sync-before']
            for n in range(opt.repeats):
                for case in cases if n % 2 == 0 else reversed(cases):
                    name = f'{case}-{n+1}'
                    attempt(project,name,'renderer_probe.gd',['--variant='+case],name,variant=case)
            attempt(project,'validation','renderer_probe.gd',[],'validation',gpu_debug=True)
        elif opt.group == 'workload':
            originals = {p:(project / p).read_text() for p in ['scripts/presentation/render_warmup.gd','resources/graphics/high.tres']}
            cases = ['control','quarter-pixels','no-views','one-draw','no-proxy','no-local-shadows','no-msaa','no-ssao','pso-off']
            for n in range(opt.repeats):
                for case in cases if n % 2 == 0 else reversed(cases):
                    workload(project,case,originals,out)
                    name = f'{case}-{n+1}'
                    attempt(project,name,probe,startup,name,variant=case)
            workload(project,'control',originals,out)
            attempt(project,'validation',probe,startup,'validation',gpu_debug=True)
        elif opt.group == 'history':
            for n in range(opt.repeats):
                for revision in revisions[n % 3:] + revisions[:n % 3]:
                    name = f'{revision[:7]}-cold-{n+1}'
                    attempt(projects[revision],name,probe,startup,name)
            for n in range(2):
                for revision in revisions if n == 0 else reversed(revisions):
                    name = f'{revision[:7]}-matrix-{n+1}'
                    attempt(projects[revision],name,matrix,matrix_args,revision[:7]+'-matrix',cold=n==0,timeout=600)
        else:
            methods = list(BACKENDS)
            for n in range(opt.repeats):
                for backend in methods[n % 3:] + methods[:n % 3]:
                    cache = f'{backend}-{n+1}'
                    for cold in [True, False]:
                        name = cache+('-cold' if cold else '-warm')
                        attempt(project,name,probe,startup,cache,backend,cold=cold)
            for backend in methods:
                attempt(project,backend+'-matrix',matrix,matrix_args,backend+'-timing',backend,timeout=600)
                # Keep screenshots separate from frame-pacing comparisons.
                shots = out / (backend+'-shots')
                attempt(project,backend+'-visual',matrix,['--graphics=low','--suite=matrix','--samples=24',
                        '--warmup=8','--shots='+str(shots)],backend+'-timing',backend,cold=False,timeout=480)
    for p in (Path.home()/'Library/Logs/DiagnosticReports').glob('*.ips'):
        if p.stat().st_mtime >= start and 'godot' in p.name.lower():
            (out/'crash-reports').mkdir(exist_ok=True)
            shutil.copy2(p,out/'crash-reports'/p.name)
    metadata['complete'] = True
    index.write_text(json.dumps(metadata, indent=2))
    # This is an investigative job. Surface crashes and incomplete reports.
    return int(any(r['code'] or not r['complete'] or not r['valid_backend'] or r['device_loss'] for r in rows))


if __name__ == '__main__':
    raise SystemExit(main())
