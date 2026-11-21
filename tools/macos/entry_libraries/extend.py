"""Compile newly observed journey stages and retain the byte-exact shipped Metal libraries."""
import argparse
from collections import deque
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import plistlib
import sys
import tempfile
from zipfile import ZipFile

MACOS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MACOS / 'offline_bake'))
sys.path.insert(0, str(MACOS / 'metal_libraries'))
from inventory import compile_stage, group
from prepare import archive_groups, install_compatible_groups


def collect(app, trace):
    resources = app / 'Contents/Resources'
    source = resources / 'MetalShaders'
    baked = resources / 'MetalLibraries'
    profile = plistlib.loads((source / 'Profile.plist').read_bytes())
    shipped = plistlib.loads((baked / 'Profile.plist').read_bytes())
    with ZipFile(trace) as z:
        events = [json.loads(line) for line in z.read('signposts.ndjson').splitlines() if line.startswith(b'{')]
        pid = json.loads(z.read('entry-profile.json'))['sampled']['pid']
    observed = {int(e['eventMessage'].split('hash=')[-1],16) for e in events if e.get('processID') == pid
                and e.get('signpostName') == 'shader_compile' and e.get('signpostType') == 'begin'}
    sources, before, inputs = {}, {}, {}
    for name, expected in profile['files'].items():
        original = (source / name).read_bytes()
        if hashlib.sha256(original).hexdigest() != expected:
            raise ValueError('Source inventory mismatch: ' + name)
        def source_stage(digest, msl, invariant, existing):
            if existing or sources.setdefault(digest,(msl,invariant)) != (msl,invariant):
                raise ValueError('Source or compiler options differ for ' + digest)
        if group(original,source_stage) != original:
            raise ValueError('Source did not round-trip: ' + name)
        base = (baked / name).read_bytes() if name in shipped['files'] else original
        if hashlib.sha256(base).hexdigest() != shipped['files'].get(name, expected):
            raise ValueError('Read-only inventory mismatch: ' + name)
        def existing_stage(digest, msl, invariant, lib):
            if sources.get(digest) != (msl,invariant):
                raise ValueError('Read-only source differs from fallback')
            if lib and before.setdefault(digest,lib) != lib:
                raise ValueError('Different library bytes for ' + digest)
        if group(base,existing_stage) != base:
            raise ValueError('Existing library did not round-trip')
        inputs[name] = base
    needed = {k:v for k,v in sources.items() if int(k[:8],16) in observed}
    if not observed or len(needed) != len(observed):
        raise ValueError('The trace must identify unique signed source stages')
    return source, profile, before, needed, inputs



def extend_group(base, observed_libraries, verified):
    # One source hash can be compiled in one material variant and source-only
    # in another. Preserve each occurrence unless the trace asks for its library.
    expected = deque()

    def fill(digest, source, invariant, existing):
        addition = observed_libraries.get(digest) if not existing else None
        expected.append((digest, existing or addition or b''))
        return addition

    def check(digest, source, invariant, library):
        if not expected or expected.popleft() != (digest, library):
            raise ValueError('Output library drift: ' + digest)
        if library:
            verified.add(digest)

    data = group(base, fill)
    if group(data, check) != data or expected:
        raise ValueError('Output group did not round-trip')
    return data

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('app',type=Path)
    p.add_argument('trace',type=Path)
    p.add_argument('out',type=Path)
    p.add_argument('--inspect',action='store_true')
    opt = p.parse_args()
    source,profile,before,needed,inputs = collect(opt.app,opt.trace)
    opt.out.mkdir(parents=True)
    uncompiled = {digest: stage for digest, stage in needed.items() if digest not in before}
    receipt = dict(original_libraries=len(before), additional_stages=sorted(uncompiled),
                   reused_observed_stages=sorted(needed.keys() & before.keys()),
                   original_library_bytes=sum(map(len,before.values())), trace_sha256=hashlib.sha256(opt.trace.read_bytes()).hexdigest())
    report = opt.out / 'coverage.json'
    report.write_text(json.dumps(receipt,indent=2))
    if opt.inspect:
        return
    logs = opt.out / 'compiler-logs'
    logs.mkdir()
    with tempfile.TemporaryDirectory() as directory, ThreadPoolExecutor(max_workers=3) as workers:
        new = dict(workers.map(lambda item: compile_stage(item,Path(directory),logs), sorted(uncompiled.items())))
    combined = dict(before,**new)
    observed_libraries = {digest: combined[digest] for digest in needed}
    verified = set()
    with tempfile.TemporaryDirectory() as directory:
        full = Path(directory)
        hashes = {}
        for name, base in inputs.items():
            data = extend_group(base, observed_libraries, verified)
            path = full / name
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_bytes(data)
            hashes[name] = hashlib.sha256(data).hexdigest()
        if verified != set(combined):
            raise ValueError('Missing compiled stages')
        (full/'Profile.plist').write_bytes(plistlib.dumps(dict(profile,files=hashes,min_os_version='26.0')))
        archive = opt.out / 'extended-libraries.zip'
        archive_groups(source, full, archive)
        installed = install_compatible_groups(full / 'verification',profile,archive)
    receipt.update(total_libraries=len(verified),additional_library_bytes=sum(map(len,new.values())),read_only_groups=len(installed),
                   archive_sha256=hashlib.sha256(archive.read_bytes()).hexdigest())
    report.write_text(json.dumps(receipt,indent=2))


if __name__ == '__main__':
    main()
