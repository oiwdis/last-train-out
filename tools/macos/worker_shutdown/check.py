"""Check the three-worker exit barrier with idle and draining queues in separate processes."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from renderer_diagnostics import engine_diagnostics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('--pack', type=Path)
    parser.add_argument('--control', action='store_true', help='Retain the known upstream timeout as a positive control')
    opt = parser.parse_args()
    out = opt.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    rows = []
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        config = '[threading]\nworker_pool/max_threads=3\nworker_pool/low_priority_thread_ratio=0.67\n'
        args = ['--headless', '--verbose', '--path', str(project)]
        if opt.pack:
            pack = project / opt.pack.name
            shutil.copy2(opt.pack, pack)
            (project / 'override.cfg').write_text(config)
            args += ['--main-pack', str(pack)]
        else:
            (project / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="LTO worker check"\n' + config)
        args += ['--script', str(Path(__file__).with_name('queue.gd').resolve()), '--']
        for index, count in enumerate((0, 8, 8, 8)):
            cmd = [str(opt.binary.resolve()), *args, *(['--pending-work'] if count else [])]
            log = out / f'launch-{index}.log'
            started = time.monotonic()
            with log.open('w') as stream:
                try:
                    code = subprocess.run(cmd, stdout=stream, stderr=subprocess.STDOUT, timeout=10).returncode
                except subprocess.TimeoutExpired:
                    code = 124
            lines = log.read_text(errors='replace').splitlines()
            diagnostic = engine_diagnostics(lines)
            matched = (f'[worker-shutdown] finite tasks submitted: {count}' in lines and
                       'WorkerThreadPool: 3 threads, 2 max low-priority.' in lines)
            rows.append({'tasks':count, 'code':code, 'fixture_reached':matched, 'diagnostics':diagnostic,
                         'wall_seconds':time.monotonic() - started, 'log':log.name})
            (out / 'exits.json').write_text(json.dumps(rows, indent=2))
    if not all(r['fixture_reached'] and not r['diagnostics'] for r in rows) or rows[0]['code'] != 0:
        return 1
    if opt.control:
        return int(not any(r['code'] == 124 for r in rows[1:]) or any(r['code'] not in (0,124) for r in rows[1:]))
    return int(any(r['code'] != 0 for r in rows))


if __name__ == '__main__':
    raise SystemExit(main())
