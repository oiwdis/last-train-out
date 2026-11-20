"""Collect stock release Metal source/reflection caches for the finished PCK on this GPU."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile
import uuid

from benchmark_release import measure
from metal_libraries.prepare import install_compatible_groups


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    app, out = args.app.resolve(), args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    resources = app / 'Contents/Resources'
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    binary = str(app / 'Contents/MacOS/LastTrainOutMetal')
    profile = json.loads(subprocess.check_output([app / 'Contents/MacOS/choose-renderer', '--device-profile']))
    original, = resources.glob('*.pck')
    user = 'LTO-MetalBuild-' + uuid.uuid4().hex
    data = Path.home() / 'Library/Application Support' / user
    with tempfile.TemporaryDirectory(prefix='lto-metal-build-') as temp:
        project = Path(temp)
        pack = project / original.name
        shutil.copy2(original, pack)
        (project / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                               f'config/custom_user_dir_name="{user}"\n')
        result = measure(binary, project, out, 'source-inventory', 'integration_benchmark.gd',
                         ['--suite=matrix', '--samples=12', '--warmup=8'], 600,
                         ['--main-pack', str(pack), '--rendering-method', 'forward_plus', '--rendering-driver', 'metal'],
                         data / 'shader_cache')
        if result['returncode'] or not result.get('complete_matrix') or result['engine_diagnostics']:
            raise SystemExit('The packaged Metal shader inventory failed; see source-inventory.log.')
        report = json.loads((out / 'source-inventory.json').read_text())
        if (report['renderer'], report['driver'], report['runtime_binary']) != ('forward_plus', 'metal', 'LastTrainOutMetal'):
            raise SystemExit('Wrong renderer in shader inventory.')
    dest = resources / 'MetalShaders'
    dest.mkdir()
    files = {}
    cache = data / 'shader_cache'
    for path in sorted(cache.rglob('*.metal.cache')):
        key = path.relative_to(cache).as_posix()
        if not re.fullmatch(r'[a-zA-Z0-9_]+/[a-f0-9]{64}/[a-f0-9]{40}\.metal\.cache', key):
            raise ValueError('Unexpected Godot shader cache path ' + key)
        source = path.read_bytes()
        if source[:8] != b'GDSC\x04\0\0\0':
            raise ValueError('Unexpected Godot shader cache format ' + key)
        target = dest / key
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(source)
        files[key] = hashlib.sha256(source).hexdigest()
    if not files:
        raise SystemExit('Godot produced no Metal shader intermediates.')
    profile.update(files=files, source=info['LTOBuildCommit'], adapter=report['adapter'], engine=report['godot'])
    libraries = install_compatible_groups(resources, profile)
    profile['bundled_library_groups'] = len(libraries)
    (dest / 'Profile.plist').write_bytes(plistlib.dumps(profile))
    (out / 'metal-profile.json').write_text(json.dumps(profile, indent=2))
    print('Included', len(files), 'Metal source groups and', len(libraries), 'matched library groups for', report['adapter'])


if __name__ == '__main__':
    main()
