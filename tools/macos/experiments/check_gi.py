"""Check that first-use GI compositions run when SDFGI is explicitly enabled."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from metal_trace import metal_signposts
from renderer_diagnostics import engine_diagnostics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    opt = parser.parse_args()
    app, out = opt.app.resolve(), opt.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    comparisons, status = [], []
    for policy in ('eager', 'on-demand'):
        part = out / policy
        part.mkdir()
        cmd = [str(app / 'Contents/MacOS/choose-renderer'), 'metal', '--audio-driver', 'Dummy', '--resolution', '320x192',
               '--fixed-fps', '60', '--script', str(Path(__file__).with_name('gi_probe.gd').resolve()), '--', '--out=' + str(part)]
        env = dict(os.environ, LTO_METAL_EAGER_GI='1' if policy == 'eager' else '0')
        with metal_signposts(part) as trace, (part / 'game.log').open('w') as log:
            try:
                code = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, env=env, timeout=240).returncode
            except subprocess.TimeoutExpired:
                code = 124
        count = 0
        for line in (part / 'signposts.ndjson').read_bytes().splitlines():
            if not line.startswith(b'{'): continue
            e = json.loads(line)
            if (e.get('signpostName') == 'compute_pipeline_create' and e.get('signpostType') == 'begin'
                    and e.get('eventMessage', '').startswith('shader_name=GiShaderRD:')):
                count += 1
        diagnostics = engine_diagnostics((part / 'game.log').read_text(errors='replace').splitlines())
        d = json.loads((part / 'result.json').read_text()) if (part / 'result.json').exists() else {}
        stages = d.get('stages', [])
        passed = (code == 0 and not diagnostics and d.get('driver') == 'metal' and d.get('binary') == 'LastTrainOutMetal'
                  and [v['sdfgi'] for v in stages] == [False, True, False, True] and all(v['active_environment'] for v in stages)
                  and (count == 40 if policy == 'eager' else 0 < count < 40))
        comparisons.append([v['rgba_sha256'] for v in stages])
        status.append({'policy':policy, 'returncode':code, 'passed':passed, 'gi_compute_pipelines':count,
                       'diagnostics':diagnostics, 'trace_exit':trace.returncode})
        (out / 'checks.json').write_text(json.dumps(status, indent=2))
    same = comparisons[0] == comparisons[1] and len(comparisons[0]) == 4
    (out / 'pixel-equivalence.json').write_text(json.dumps({'equal':same,'hashes':comparisons}, indent=2))
    return int(not same or not all(row['passed'] for row in status))


if __name__ == '__main__':
    raise SystemExit(main())
