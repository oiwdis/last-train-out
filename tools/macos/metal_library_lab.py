"""Measure stock Metal library creation policies on one pack and capture Godot's native signposts."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import shutil
import tempfile
import uuid

from benchmark_release import measure
from metal_trace import metal_signposts
from stress_release import digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    alternate = {'immediate': 'lazy', 'lazy': 'immediate', 'eager-gi': 'on-demand-gi', 'on-demand-gi': 'eager-gi'}
    parser.add_argument('first', choices=alternate)
    parser.add_argument('--matrix', action='store_true')
    opt = parser.parse_args()
    app, out = opt.app.resolve(), opt.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    pack, = (app / 'Contents/Resources').glob('*.pck')
    chooser = app / 'Contents/MacOS/choose-renderer'
    binary = str(chooser if chooser.exists() else app / 'Contents/MacOS' / info['CFBundleExecutable'])
    summary = {'pack_sha256':digest(pack), 'source':info.get('LTOBuildCommit'), 'runs':[]}
    order = [opt.first, alternate[opt.first]]
    token = 'LTO-354-libraries-' + uuid.uuid4().hex
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        target = project / pack.name
        shutil.copy2(pack, target)
        flags = (['metal'] if chooser.exists() else ['--rendering-method', 'forward_plus', '--rendering-driver', 'metal'])
        flags += ['--main-pack', str(target)]

        def run(mode, condition, script='startup_probe.gd'):
            name = mode + '-' + condition
            # Both cold starts and both first matrices use independent writable caches.
            group = 'matrix' if script == 'integration_benchmark.gd' else ('profile' if condition == 'traced' else 'start')
            user = token + '-' + mode + '-' + group
            path = Path.home() / 'Library/Application Support' / user
            (project / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                                 f'config/custom_user_dir_name="{user}"\n')
            if mode in ('eager-gi', 'on-demand-gi'):
                os.environ['GODOT_MTL_SHADER_LOAD_STRATEGY'] = 'lazy'
                os.environ['LTO_METAL_EAGER_GI'] = '1' if mode == 'eager-gi' else '0'
            else:
                os.environ['GODOT_MTL_SHADER_LOAD_STRATEGY'] = mode
            args = ['--graphics=high', '--profile-phases'] if script == 'startup_probe.gd' else [
                '--graphics=low', '--suite=matrix', '--warmup=60', '--samples=180']
            row = measure(binary, project, out, name, script, args, 600 if script == 'integration_benchmark.gd' else 220,
                          flags, path / 'shader_cache')
            report = out / (name + '.json')
            data = json.loads(report.read_text()) if report.exists() and not row.get('report_error') else {}
            row['passed'] = (row['returncode'] == 0 and not row['engine_diagnostics'] and data.get('driver') == 'metal'
                             and (not chooser.exists() or (data.get('runtime_binary'), data.get('engine_build')) == ('LastTrainOutMetal', 'lto_metal'))
                             and (row.get('mission_ready') or row.get('complete_matrix')))
            if script == 'startup_probe.gd':
                row['passed'] = bool(row['passed'] and data.get('user_data_directory') == str(path))
            summary['runs'].append(row)
            (out / 'libraries.json').write_text(json.dumps(summary, indent=2))

        for mode in order:
            run(mode, 'cold')
        for mode in reversed(order):
            run(mode, 'warm')
        if opt.matrix:
            for mode in reversed(order):
                run(mode, 'matrix', 'integration_benchmark.gd')
        # Trace a separate fresh process. The first four startup timings and
        # the frame matrices run without an attached trace collector.
        with metal_signposts(out) as collector:
            run(opt.first, 'traced')
        summary['collector_exit'] = collector.returncode
        (out / 'libraries.json').write_text(json.dumps(summary, indent=2))
    return int(any(not row['passed'] for row in summary['runs']))


if __name__ == '__main__':
    raise SystemExit(main())
