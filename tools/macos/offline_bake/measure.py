"""Test upstream offline Metal libraries on the same signed PCK and player executable."""
import argparse
import json
from pathlib import Path
import shutil
import sys
import tempfile
import uuid

MACOS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MACOS))
from benchmark_release import measure
from stress_release import digest


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
        conditions = ['cold', 'warm', 'matrix']
        if first == 'binary':
            conditions.append('readback')
        for condition in conditions:
            for kind in (order if condition == 'cold' else reversed(order)):
                app = source if kind == 'source' else binary
                user = session + '-' + kind + ('-' + condition if condition in ('matrix', 'readback') else '')
                (path / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                                   f'config/custom_user_dir_name="{user}"\n')
                support = Path.home() / 'Library/Application Support' / user
                matrix = condition in ('matrix', 'readback')
                script = 'integration_benchmark.gd' if matrix else 'startup_probe.gd'
                flags = ['--suite=matrix','--warmup=60','--samples=180','--graphics=low'] if matrix else ['--graphics=high','--profile-phases']
                name = kind + '-' + condition
                shots = out / (name + '-png')
                if condition == 'readback':
                    flags = ['--suite=matrix', '--samples=12', '--warmup=8', '--shots=' + str(shots)]
                attempt = measure(str(app / 'Contents/MacOS/choose-renderer'), path, out, name, script, flags, 600,
                                  ['metal', '--main-pack', str(pack)], support / 'shader_cache')
                file = out / (name + '.json')
                data = json.loads(file.read_text()) if file.exists() and not attempt.get('report_error') else {}
                attempt['passed'] = bool(attempt['returncode'] == 0 and not attempt['engine_diagnostics']
                    and data.get('driver') == 'metal' and data.get('runtime_binary') == 'LastTrainOutMetal'
                    and (attempt.get('complete_matrix') if matrix else attempt.get('mission_ready')
                         and data.get('user_data_directory') == str(support)))
                if condition == 'readback':
                    attempt['screenshots'] = len(list(shots.glob('*.png')))
                    attempt['passed'] = attempt['passed'] and attempt['screenshots'] == 36
                reports.append(attempt)
                (out / 'libraries.json').write_text(json.dumps({'pack_sha256': digest(pack), 'runs': reports}, indent=2))
    return int(any(not attempt['passed'] for attempt in reports))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('source', 'binary', 'out'):
        parser.add_argument(name, type=Path)
    parser.add_argument('first', choices=['source', 'binary'])
    args = parser.parse_args()
    raise SystemExit(compare(args.source.resolve(), args.binary.resolve(), args.first, args.out.resolve()))
