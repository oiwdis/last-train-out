"""Test upstream offline Metal libraries on the same signed PCK and player executable."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from zipfile import ZipFile

MACOS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MACOS))
from benchmark_release import measure
from stress_release import digest


def bake(app, compiler, trace, out):
    out.mkdir(parents=True)
    with ZipFile(trace) as archive:
        events = [json.loads(line) for line in archive.read('player-first/signposts.ndjson').splitlines()
                  if line.startswith(b'{')]
    stages = {event['eventMessage'].split('hash=')[-1].lower() for event in events
              if event.get('signpostName') == 'shader_compile' and event.get('signpostType') == 'begin'}
    if not stages or not all(re.fullmatch('[0-9a-f]{1,8}', stage) for stage in stages):
        raise ValueError('The observed shader trace contains no usable stage hashes.')
    env = dict(os.environ, LTO_METAL_BAKE_HASHES=',' + ','.join(sorted(stages)) + ',')
    # The normal player never runs xcrun. Only this build machine creates metallibs.
    code = subprocess.run([sys.executable, MACOS / 'prepare_metal_shaders.py', app, out,
                           '--offline-baker', compiler], env=env).returncode
    log = out / 'source-inventory.log'
    lines = log.read_text(errors='replace').splitlines() if log.exists() else []
    compiled = {key for line in lines for key in re.findall(r'\[metal-bake\] \S+ ,([0-9a-f]+), \d+ bytes', line)}
    (out / 'coverage.json').write_text(json.dumps({'trace_sha256': digest(trace), 'observed': sorted(stages),
        'compiled': sorted(compiled), 'remaining_source': sorted(stages - compiled), 'compiler_exit': code}, indent=2))
    return int(code != 0 or not compiled or not compiled <= stages)


def compare(source, binary, first, out):
    out.mkdir(parents=True)
    reports = []
    packs = [next((app / 'Contents/Resources').glob('*.pck')) for app in (source, binary)]
    exes = [app / 'Contents/MacOS/LastTrainOutMetal' for app in (source, binary)]
    if digest(packs[0]) != digest(packs[1]) or digest(exes[0]) != digest(exes[1]):
        raise ValueError('The game pack and player binary must match between conditions.')
    order = [first, 'source' if first == 'binary' else 'binary']
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp)
        pack = path / packs[0].name
        shutil.copy2(packs[0], pack)
        session = 'LTO-354-offline-' + uuid.uuid4().hex
        for condition in ('cold', 'warm', 'matrix'):
            for kind in (order if condition == 'cold' else reversed(order)):
                app = source if kind == 'source' else binary
                user = session + '-' + kind + ('-matrix' if condition == 'matrix' else '')
                (path / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                                   f'config/custom_user_dir_name="{user}"\n')
                support = Path.home() / 'Library/Application Support' / user
                matrix = condition == 'matrix'
                script = 'integration_benchmark.gd' if matrix else 'startup_probe.gd'
                flags = ['--suite=matrix','--warmup=60','--samples=180','--graphics=low'] if matrix else ['--graphics=high','--profile-phases']
                name = kind + '-' + condition
                attempt = measure(str(app / 'Contents/MacOS/choose-renderer'), path, out, name, script, flags, 600,
                                  ['metal', '--main-pack', str(pack)], support / 'shader_cache')
                file = out / (name + '.json')
                data = json.loads(file.read_text()) if file.exists() and not attempt.get('report_error') else {}
                attempt['passed'] = bool(attempt['returncode'] == 0 and not attempt['engine_diagnostics']
                    and data.get('driver') == 'metal' and data.get('runtime_binary') == 'LastTrainOutMetal'
                    and (attempt.get('complete_matrix') if matrix else attempt.get('mission_ready')
                         and data.get('user_data_directory') == str(support)))
                reports.append(attempt)
                (out / 'libraries.json').write_text(json.dumps({'pack_sha256': digest(pack), 'runs': reports}, indent=2))
    return int(any(not attempt['passed'] for attempt in reports))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    tasks = parser.add_subparsers(dest='action', required=True)
    build = tasks.add_parser('bake')
    for key in ('app','compiler','trace','out'):
        build.add_argument(key, type=Path)
    check = tasks.add_parser('compare')
    for key in ('source','binary','out'):
        check.add_argument(key, type=Path)
    check.add_argument('first', choices=['source','binary'])
    args = parser.parse_args()
    if args.action == 'bake':
        raise SystemExit(bake(args.app.resolve(), args.compiler.resolve(), args.trace.resolve(), args.out.resolve()))
    raise SystemExit(compare(args.source.resolve(), args.binary.resolve(), args.first, args.out.resolve()))
