"""Time both packaged players from the selector to play on the same Mac and PCK."""
import argparse
import json
from pathlib import Path
import platform
import plistlib
import shutil
import subprocess
import tempfile
import time
import uuid

from benchmark_release import cache_inventory
from measure_fresh_player import wait_for_exit
from renderer_diagnostics import engine_diagnostics
from stress_release import digest


def run_player(chooser, pack, out, driver, preset, state, user):
    name = '-'.join((driver, preset, state))
    cache = user / 'shader_cache'
    before = cache_inventory(cache)
    stats = out / (name + '.json')
    cmd = [str(chooser), driver, '--main-pack', str(pack), '--windowed', '--resolution', '960x540', '--verbose',
           'res://scenes/main/journey_loading.tscn', '--', '--graphics=' + preset, '--profile-phases',
           '--lto-launch-report=' + str(stats)]
    start = time.monotonic()
    with (out / (name + '.log')).open('w') as log, subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT) as proc:
        code, shutdown = wait_for_exit(proc, stats, out, name)
    lines = (out / (name + '.log')).read_text(errors='replace').splitlines()
    diagnostics = engine_diagnostics(lines)
    report = json.loads(stats.read_text()) if stats.exists() else {}
    frames = report.get('first_frames_ms', [])
    ready = report.get('launcher_ready_ms', 0)
    progress = report.get('load', {}).get('progress', [])
    passed = (code == 0 and not diagnostics and report.get('ready') is True and ready > 0
              and (report.get('method'), report.get('driver')) == ('forward_plus', driver)
              and report.get('preset') == ('low','medium','high').index(preset) and report.get('user_dir') == str(user)
              and len(frames) == 30 and progress and progress[-1][0] == 100
              and (state != 'cold' or before['files'] == 0))
    return dict(name=name, driver=driver, preset=preset, state=state, command=cmd, passed=bool(passed), returncode=code,
                wall_s=time.monotonic()-start, launcher_ready_ms=ready or None, first_worst_ms=max(frames, default=None),
                cache_before=before, cache_after=cache_inventory(cache), shutdown=shutdown, diagnostics=diagnostics)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('first', choices=('metal','vulkan'))
    opt = parser.parse_args()
    app, out = opt.app.resolve(), opt.out.resolve()
    out.mkdir(parents=True)
    selector = app / 'Contents/MacOS/choose-renderer'
    original, = (app / 'Contents/Resources').glob('*.pck')
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    drivers = (opt.first, 'vulkan' if opt.first == 'metal' else 'metal')
    token = 'LTO-Paired-Player-' + uuid.uuid4().hex
    started = time.time()
    record = dict(host=platform.platform(), architecture=platform.machine(), first=opt.first, revision=info['LTOBuildCommit'],
                  pack_sha256=digest(original), resolution='960x540 windowed', audio='system', attempts=[])
    with tempfile.TemporaryDirectory() as tmp:
        pack = Path(tmp) / original.name
        shutil.copy2(original, pack)
        for preset in ('high','medium','low'):
            for state in ('cold','warm'):
                for driver in drivers if state == 'cold' else reversed(drivers):
                    name = '-'.join((token,preset,driver))
                    user = Path.home() / 'Library/Application Support' / name
                    (pack.parent/'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + name + '"\n')
                    attempt = run_player(selector, pack, out, driver, preset, state, user)
                    record['attempts'].append(attempt)
                    (out / 'paired-players.json').write_text(json.dumps(record, indent=2))
    for crash in (Path.home() / 'Library/Logs/DiagnosticReports').glob('Last*Train*.ips'):
        if crash.stat().st_mtime_ns >= started * 1e9:
            shutil.copy2(crash, out / crash.name)
    return int(any(not row['passed'] for row in record['attempts']))


if __name__ == '__main__':
    raise SystemExit(main())
