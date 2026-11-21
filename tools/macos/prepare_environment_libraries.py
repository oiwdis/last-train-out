"""Prepare Metal stages observed in the new world using the integration's existing offline baker."""
import argparse
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
from zipfile import ZipFile, ZIP_DEFLATED

from benchmark_release import measure
from compare_environments import FIXTURE, VIEWS, select_user
from metal_libraries.prepare import install_compatible_groups
from metal_trace import metal_signposts


def observe(app, directory):
    directory.mkdir()
    with tempfile.TemporaryDirectory(prefix='lto-environment-stages-') as tmp:
        project = Path(tmp)
        user = select_user(project, project.name)
        original, = (app / 'Contents/Resources').glob('*.pck')
        pack = project / original.name
        shutil.copyfile(original, pack)
        try:
            with metal_signposts(directory):
                run = measure(str(app / 'Contents/MacOS/choose-renderer'), project, directory, 'world', str(FIXTURE),
                              ['--suite=environment', '--samples=12', '--warmup=8'], 900,
                              ['metal', '--main-pack', str(pack)], user / 'shader_cache')
        finally:
            if user.exists():
                shutil.rmtree(user)
    world = json.loads((directory / 'world.json').read_bytes())
    if (run['returncode'] or run['timed_out'] or run['engine_diagnostics'] or world['driver'] != 'metal'
            or world['runtime_binary'] != 'LastTrainOutMetal' or len(world['results']) != VIEWS * 3 * 2):
        raise ValueError('Incomplete native world shader observation')
    events = [json.loads(line) for line in (directory / 'signposts.ndjson').read_bytes().splitlines() if line.startswith(b'{')]
    begins = [e for e in events if e.get('processID') == run['pid'] and e.get('signpostType') == 'begin']
    if not any(e.get('signpostName') == 'render_pipeline_create' for e in begins):
        raise ValueError('No render pipeline signposts were captured for the measured process')
    hashes = sorted({e['eventMessage'].split('hash=')[-1] for e in begins if e.get('signpostName') == 'shader_compile'})
    return run['pid'], hashes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    app, out = args.app.resolve(), args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    pid, hashes = observe(app, out / 'before')
    receipt = {'source_compiles_before': hashes}
    report = out / 'result.json'
    report.write_text(json.dumps(receipt, indent=2))
    if not hashes:
        return
    # The existing extension tool accepts one trace tied to the exact process ID.
    trace = out / 'observed-stages.zip'
    with ZipFile(trace, 'w', ZIP_DEFLATED) as archive:
        archive.write(out / 'before/signposts.ndjson', 'signposts.ndjson')
        archive.writestr('entry-profile.json', json.dumps({'sampled': {'pid': pid}}))
    subprocess.run([sys.executable, str(Path(__file__).parent / 'entry_libraries/extend.py'),
                    str(app), str(trace), str(out / 'compiled')], check=True)
    resources = app / 'Contents/Resources'
    profile_file = resources / 'MetalShaders/Profile.plist'
    profile = plistlib.loads(profile_file.read_bytes())
    groups = install_compatible_groups(resources, profile, out / 'compiled/extended-libraries.zip')
    if len(groups) < profile['bundled_library_groups']:
        raise ValueError('Extended inventory lost existing matched Metal groups')
    profile['bundled_library_groups'] = len(groups)
    profile_file.write_bytes(plistlib.dumps(profile))
    subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
    _, remaining = observe(app, out / 'after')
    receipt.update(source_compiles_after=remaining, matched_library_groups=len(groups))
    report.write_text(json.dumps(receipt, indent=2))
    if remaining:
        raise ValueError('The verified environment still needed observed Metal source compilations')


if __name__ == '__main__':
    main()
