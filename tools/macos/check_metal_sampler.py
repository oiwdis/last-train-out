"""Run positive/negative Metal sampler controls on the stock editor, with no game assets."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from renderer_diagnostics import engine_diagnostics

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('godot')
    parser.add_argument('output', type=Path)
    options = parser.parse_args()
    out = options.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    with tempfile.TemporaryDirectory() as tmp:
        project = Path(tmp)
        (project / 'scripts/settings').mkdir(parents=True)
        shutil.copy2(ROOT / 'scripts/settings/render_resolution.gd', project / 'scripts/settings/')
        shutil.copy2(ROOT / 'tools/macos/metal_sampler_probe.gd', project / 'probe.gd')
        (project / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Metal sampler probe"\n[display]\nwindow/stretch/mode="canvas_items"\nwindow/stretch/aspect="expand"\n')
        for variant in ('control', 'neutral'):
            part = out / variant
            part.mkdir()
            with (part / 'raw.log').open('w') as stream:
                subprocess.run([options.godot, '--path', str(project), '--resolution', '640x360',
                                '--rendering-method', 'forward_plus', '--rendering-driver', 'metal',
                                '--audio-driver', 'Dummy', '--script', 'probe.gd', '--',
                                '--out=' + str(part), '--variant=' + variant],
                               stdout=stream, stderr=subprocess.STDOUT, timeout=150, check=True)
    pairs = []
    for variant in ('control', 'neutral'):
        part = out / variant
        data = json.loads((part / 'result.json').read_text())
        assert (data['method'], data['driver']) == ('forward_plus', 'metal')
        raw = (part / 'raw.log').read_text()
        warnings = engine_diagnostics(raw.splitlines())
        if variant == 'control':
            assert len(warnings) == 1 and 'Metal does not support LOD bias for samplers' in warnings[0], warnings
        else:
            assert not warnings, warnings
        pairs.append([hashlib.sha256((part / f['file']).read_bytes()).hexdigest() for f in data['frames']])
    assert len(pairs[0]) == 6 and pairs[0] == pairs[1], pairs
    print('Both actual Metal runs produced six identical rendered images; only the positive control warned.')


if __name__ == '__main__':
    main()
