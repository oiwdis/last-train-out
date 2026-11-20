"""Compare the shipped and extended read-only library inventories on a single Mac."""
import argparse
from contextlib import nullcontext
import json
from pathlib import Path
import plistlib
import shutil
import sys
import tempfile
import uuid

MACOS = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(MACOS))
sys.path.insert(0,str(MACOS / 'metal_libraries'))
from benchmark_release import measure
from metal_trace import metal_signposts
from prepare import install_compatible_groups
from stress_release import digest


def install(app, archive):
    resources = app / 'Contents/Resources'
    file = resources / 'MetalShaders/Profile.plist'
    profile = plistlib.loads(file.read_bytes())
    groups = install_compatible_groups(resources,profile,archive)
    if len(groups) < profile['bundled_library_groups']:
        raise ValueError('The extension lost a shipped library group')
    profile['bundled_library_groups'] = len(groups)
    file.write_bytes(plistlib.dumps(profile))


def compare(shipped, extended, out, first):
    out.mkdir(parents=True)
    apps = {'shipped':shipped, 'extended':extended}
    pack, = (shipped/'Contents/Resources').glob('*.pck')
    same_pack, = (extended/'Contents/Resources').glob('*.pck')
    if digest(pack) != digest(same_pack):
        raise ValueError('The two variants must contain the same signed game pack')
    for binary in ('choose-renderer','LastTrainOutMetal'):
        if digest(shipped/'Contents/MacOS'/binary) != digest(extended/'Contents/MacOS'/binary):
            raise ValueError('Runtime bytes differ: ' + binary)
    order = [first, 'shipped' if first == 'extended' else 'extended']
    token = 'LTO-Entry-Compare-' + uuid.uuid4().hex
    attempts = []
    with tempfile.TemporaryDirectory() as directory:
        folder = Path(directory)
        copy = folder / pack.name
        shutil.copy2(pack,copy)
        for stage, sequence in [('matrix-1',order),('matrix-2',reversed(order)),('visual',order)]:
            for version in sequence:
                name = version + '-' + stage
                user = token + '-' + version
                (folder/'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + user + '"\n')
                run = out / name
                run.mkdir()
                observer = metal_signposts(run) if stage == 'matrix-1' else nullcontext()
                args = ['--suite=matrix','--samples=180','--warmup=60']
                if stage == 'visual':
                    args = ['--suite=matrix','--samples=24','--warmup=8','--shots=' + str(run/'shots')]
                with observer:
                    row = measure(str(apps[version]/'Contents/MacOS/choose-renderer'),folder,run,name,'integration_benchmark.gd',
                                  args,600,['metal','--main-pack',str(copy)],Path.home()/'Library/Application Support'/user/'shader_cache')
                file = run/(name+'.json')
                data = json.loads(file.read_bytes()) if file.is_file() and not row.get('report_error') else {}
                log = (run/(name+'.log')).read_text(errors='replace')
                row['passed'] = (row['returncode'] == 0 and not row['engine_diagnostics'] and row.get('complete_matrix')
                                 and data.get('driver') == 'metal' and data.get('runtime_binary') == 'LastTrainOutMetal'
                                 and 'Loaded bundled Metal library group' in log)
                if stage == 'matrix-1':
                    events = [json.loads(line) for line in (run/'signposts.ndjson').read_bytes().splitlines() if line.startswith(b'{')]
                    begins = [e for e in events if e.get('signpostType')=='begin']
                    row['native_counts'] = {k:sum(e.get('signpostName')==k for e in begins) for k in
                                            ('shader_compile','compute_pipeline_create','render_pipeline_create')}
                    if row['native_counts']['render_pipeline_create'] == 0:
                        row['passed'] = False
                attempts.append(row)
                (out/'attempts.json').write_text(json.dumps(attempts,indent=2))
    return int(any(not r['passed'] for r in attempts))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    commands = p.add_subparsers(dest='action',required=True)
    setup = commands.add_parser('install')
    setup.add_argument('app',type=Path)
    setup.add_argument('archive',type=Path)
    bench = commands.add_parser('compare')
    bench.add_argument('shipped',type=Path)
    bench.add_argument('extended',type=Path)
    bench.add_argument('out',type=Path)
    bench.add_argument('first',choices=['shipped','extended'])
    opt = p.parse_args()
    if opt.action == 'install':
        install(opt.app,opt.archive)
    else:
        raise SystemExit(compare(opt.shipped.resolve(),opt.extended.resolve(),opt.out.resolve(),opt.first))
