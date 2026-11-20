"""Launch the actual Metal player shortcut cold then warm on a fresh signed-download runner."""
import argparse
from contextlib import nullcontext
import json
from pathlib import Path
import platform
import subprocess
import time

from benchmark_release import cache_inventory
from metal_trace import metal_signposts
from renderer_diagnostics import engine_diagnostics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    opt = parser.parse_args()
    out = opt.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    chooser = opt.app.resolve() / 'Contents/MacOS/choose-renderer'
    user = Path.home() / 'Library/Application Support/Godot/app_userdata/Last Train Out'
    summary = {'host': platform.platform(), 'architecture': platform.machine(), 'attempts': []}
    for index, name in enumerate(('first-launch', 'warm-launch')):
        cache = cache_inventory(user / 'shader_cache')
        dest = out / (name + '.json')
        # No scene, pack, project override or dummy audio. Exercise the same
        # selector path and same bundle/user directory as a player's launch.
        cmd = [str(chooser), 'metal', '--resolution', '960x540', '--verbose', '--',
               '--graphics=high', '--profile-phases', '--lto-launch-report=' + str(dest)]
        started = time.monotonic()
        observation = metal_signposts(out) if index == 0 else nullcontext()
        with observation as trace, (out / (name + '.log')).open('w') as stream:
            try:
                code = subprocess.run(cmd, stdout=stream, stderr=subprocess.STDOUT, timeout=300).returncode
            except subprocess.TimeoutExpired:
                code = 124
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
                                    'observer_wall_s': time.monotonic() - started, 'diagnostics': diagnostics})
        (out / 'player-launches.json').write_text(json.dumps(summary, indent=2))
    return int(any(not row['passed'] for row in summary['attempts']))


if __name__ == '__main__':
    raise SystemExit(main())
