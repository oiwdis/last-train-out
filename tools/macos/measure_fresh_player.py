"""Launch the actual Metal player shortcut cold then warm on a fresh signed-download runner."""
import argparse
from contextlib import nullcontext
import json
from pathlib import Path
import platform
import shutil
import subprocess
import time

from benchmark_release import cache_inventory
from metal_trace import metal_signposts
from renderer_diagnostics import engine_diagnostics


def wait_for_exit(process, report, directory, name):
    started = time.monotonic()
    reported = None
    captures = []
    timed_out = False
    while process.poll() is None:
        now = time.monotonic()
        if reported is None and report.is_file():
            reported = now
        # The reporter writes after all 30 playable frames. A healthy exit
        # takes a few frames. Observe an actual hang before killing the process.
        if reported is not None and len(captures) < 2 and now - reported >= (12, 45)[len(captures)]:
            sample = directory / f'{name}-shutdown-{len(captures) + 1}.txt'
            with (directory / f'{name}-sampler.log').open('a') as log:
                try:
                    result = subprocess.run(['/usr/bin/sample', str(process.pid), '3', '10', '-file', str(sample)],
                                            stdout=log, stderr=subprocess.STDOUT, timeout=15)
                    sample_code = result.returncode
                except subprocess.TimeoutExpired:
                    sample_code = 124
            captures.append({'after_report_s':now - reported, 'sample_exit':sample_code, 'file':sample.name})
        if now - started >= 300:
            timed_out = True
            process.kill()
            process.wait()
            break
        try:
            process.wait(timeout=0.5)
        except subprocess.TimeoutExpired:
            continue
    ended = time.monotonic()
    return (124 if timed_out else process.returncode,
            {'report_observed_s': reported - started if reported is not None else None,
             'elapsed_after_report_s': ended - reported if reported is not None else None,
             'samples': captures})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--without-signposts', action='store_true',
                        help='Independent cold control with no signpost observer attached')
    opt = parser.parse_args()
    out = opt.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    chooser = opt.app.resolve() / 'Contents/MacOS/choose-renderer'
    user = Path.home() / 'Library/Application Support/Godot/app_userdata/Last Train Out'
    summary = {'host': platform.platform(), 'architecture': platform.machine(),
               'first_launch_signposts': not opt.without_signposts, 'attempts': []}
    experiment_start = time.time()
    for index, name in enumerate(('first-launch', 'warm-launch')):
        cache = cache_inventory(user / 'shader_cache')
        dest = out / (name + '.json')
        # No scene, pack, project override or dummy audio. Exercise the same
        # selector path and same bundle/user directory as a player's launch.
        cmd = [str(chooser), 'metal', '--resolution', '960x540', '--verbose', '--',
               '--graphics=high', '--profile-phases', '--lto-launch-report=' + str(dest)]
        started = time.monotonic()
        observation = metal_signposts(out) if index == 0 and not opt.without_signposts else nullcontext()
        with observation as trace, (out / (name + '.log')).open('w') as stream:
            with subprocess.Popen(cmd, stdout=stream, stderr=subprocess.STDOUT) as process:
                code, shutdown = wait_for_exit(process, dest, out, name)
        if trace is not None:
            summary['first_launch_collector_exit'] = trace.returncode
        log = (out / (name + '.log')).read_text(errors='replace')
        diagnostics = engine_diagnostics(log.splitlines())
        report = json.loads(dest.read_text()) if dest.exists() else {}
        progress = report.get('load', {}).get('progress', [])
        passed = (code == 0 and not diagnostics and '4.5.1.stable.lto_metal.' in log and report.get('ready') is True
                  and report.get('method') == 'forward_plus' and report.get('driver') == 'metal'
                  and report.get('preset') == 2 and report.get('user_dir') == str(user)
                  and report.get('launcher_ready_ms', 0) > 0 and len(report.get('first_frames_ms', [])) == 30
                  and bool(progress) and progress[-1][0] == 100)
        summary['attempts'].append({'name': name, 'command': cmd, 'passed': passed, 'returncode': code,
                                    'cache_before': cache, 'cache_after': cache_inventory(user / 'shader_cache'),
                                    'observer_wall_s': time.monotonic() - started,
                                    'shutdown_observation': shutdown, 'diagnostics': diagnostics})
        (out / 'player-launches.json').write_text(json.dumps(summary, indent=2))
    for report in (Path.home() / 'Library/Logs/DiagnosticReports').glob('Last*Train*.ips'):
        if report.stat().st_mtime >= experiment_start:
            shutil.copy2(report, out / report.name)
    return int(any(not row['passed'] for row in summary['attempts']))


if __name__ == '__main__':
    raise SystemExit(main())
