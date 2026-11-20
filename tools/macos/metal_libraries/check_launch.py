"""Check bundled library reads and opt-out on the same fresh-download user's cache."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from renderer_diagnostics import engine_diagnostics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('player', type=Path)
    parser.add_argument('out', type=Path)
    opt = parser.parse_args()
    app, player, out = opt.app.resolve(), opt.player.resolve(), opt.out.resolve()
    out.mkdir(parents=True)
    chooser = app / 'Contents/MacOS/choose-renderer'
    resources = app / 'Contents/Resources'
    source = plistlib.loads((resources / 'MetalShaders/Profile.plist').read_bytes())
    # The ordinary first launch has already completed before this device query.
    actual = json.loads(subprocess.check_output([chooser, '--device-profile']))
    compatible = all(actual[k] >= source[k] for k in ('family','language','argumentBuffers'))
    expected = compatible and int(platform.mac_ver()[0].split('.')[0]) >= 26 and source.get('bundled_library_groups', 0) > 0
    checks = {}
    report = json.loads((player / 'first-launch.json').read_text())
    for launch in ('first-launch', 'warm-launch'):
        log = (player / (launch + '.log')).read_text(errors='replace')
        checks[launch + '-selection'] = ('[renderer] using read-only bundled Metal libraries:' in log) == expected
        checks[launch + '-engine-read'] = ('Loaded bundled Metal library group ' in log) == expected
    cache = Path(report['user_dir']) / 'shader_cache'
    if expected:
        baked = plistlib.loads((resources / 'MetalLibraries/Profile.plist').read_bytes())
        checks['source-cache-preserved'] = all((cache / key).is_file() and
            hashlib.sha256((cache / key).read_bytes()).hexdigest() == source['files'][key] for key in baked['files'])
    fallback = out / 'source-only.json'
    cmd = [str(chooser),'metal','--resolution','960x540','--verbose','--','--graphics=high',
           '--lto-launch-report=' + str(fallback)]
    with (out / 'source-only.log').open('w') as log:
        try:
            code = subprocess.run(cmd, env=dict(os.environ, LTO_METAL_LIBRARIES='0'),
                                  stdout=log, stderr=subprocess.STDOUT, timeout=300).returncode
        except subprocess.TimeoutExpired:
            code = 124
    data = json.loads(fallback.read_text()) if fallback.is_file() else {}
    log = (out / 'source-only.log').read_text(errors='replace')
    diagnostics = engine_diagnostics(log.splitlines())
    checks['source-only'] = (code == 0 and not diagnostics and data.get('ready') is True and
        data.get('driver') == 'metal' and data.get('user_dir') == report['user_dir'] and
        len(data.get('first_frames_ms', [])) == 30 and 'Loaded bundled Metal library group ' not in log)
    (out / 'checks.json').write_text(json.dumps(dict(device=actual, compatible=bool(expected), checks=checks,
        source_only_code=code, diagnostics=diagnostics, command=cmd), indent=2))
    return int(not all(checks.values()))


if __name__ == '__main__':
    raise SystemExit(main())
