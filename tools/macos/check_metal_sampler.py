"""Run positive/negative Metal sampler controls on the stock editor, with no game assets."""
import argparse
import json
from pathlib import Path
import plistlib
import subprocess

from renderer_diagnostics import engine_diagnostics

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    options = parser.parse_args()
    out = options.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    app = options.app.resolve()
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    pack, = (app / 'Contents/Resources').glob('*.pck')
    variants = ('control', 'neutral', 'explicit-invalid')
    for variant in variants:
        part = out / variant
        part.mkdir()
        executable = info['CFBundleExecutable'] if variant == 'control' else 'LastTrainOutMetal'
        with (part / 'raw.log').open('w') as stream:
            subprocess.run([app / 'Contents/MacOS' / executable, '--main-pack', str(pack),
                            '--resolution', '640x360', '--rendering-method', 'forward_plus',
                            '--rendering-driver', 'metal', '--audio-driver', 'Dummy',
                            '--script', str(ROOT / 'tools/macos/metal_sampler_probe.gd'), '--',
                            '--out=' + str(part), '--variant=' + variant],
                           stdout=stream, stderr=subprocess.STDOUT, timeout=180, check=True)
    pairs = []
    for variant in variants:
        part = out / variant
        data = json.loads((part / 'result.json').read_text())
        assert (data['method'], data['driver']) == ('forward_plus', 'metal')
        raw = (part / 'raw.log').read_text()
        warnings = engine_diagnostics(raw.splitlines())
        if variant != 'neutral':
            assert len(warnings) == 1 and 'Metal does not support LOD bias for samplers' in warnings[0], warnings
        else:
            assert not warnings, warnings
        assert all((part / f['file']).stat().st_size > 0 for f in data['frames'])
        pairs.append([f['rgba_sha256'] for f in data['frames']])
    assert len(pairs[0]) == 6 and pairs[0] == pairs[1] == pairs[2], pairs
    print('All three Metal processes produced six identical images each. Both positive controls warned.')


if __name__ == '__main__':
    main()
