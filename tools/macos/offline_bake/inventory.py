"""Add build-time metallibs to signed Godot 4.5.1 Metal shader groups.

The layouts below come from RenderingShaderContainer::from_bytes and
RenderingShaderContainerMetal in the pinned 4.5.1 source. Preserve every
reflection record and the complete original MSL source for each stage.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import subprocess
import tempfile
from zipfile import ZipFile

import zstandard as zstd

U32 = struct.Struct('<I')
CONTAINER = struct.Struct('<4s4I')
REFLECTION = struct.Struct('<Q12I')
METAL_PROFILE = struct.Struct('<9I')
STAGE = struct.Struct('<4I')
METAL_STAGE = struct.Struct('<3I32s3I')
MACOS_TARGET = 260000
MIN_OS_OFFSET = CONTAINER.size + REFLECTION.size + 7 * U32.size


def align4(size):
    return (size + 3) & ~3


def variant(data, library_for):
    magic, version, driver, format_version, stages = CONTAINER.unpack_from(data)
    if (magic, version, driver, format_version) != (b'GRSC', 2, 0x42424242, 1):
        raise ValueError('Unsupported Metal shader container')
    reflection = REFLECTION.unpack_from(data, CONTAINER.size)
    profile = METAL_PROFILE.unpack_from(data, CONTAINER.size + REFLECTION.size)
    if profile[0] != 0 or profile[6] != 40000:
        raise ValueError('Expected macOS MSL 4.0 source')
    pos = align4(CONTAINER.size + REFLECTION.size + METAL_PROFILE.size + reflection[-1])
    for _ in range(reflection[8]):
        uniforms, = U32.unpack_from(data, pos)
        # Five common words, active stages and four nine-word Metal bindings.
        pos += U32.size + uniforms * (5 + 1 + 4 * 9) * U32.size
    pos += (reflection[2] * 5 + reflection[-2]) * U32.size
    result = bytearray(data[:pos])
    has_library = False
    for _ in range(stages):
        start = pos
        kind, size, compression, raw_size = STAGE.unpack_from(data, pos)
        pos += STAGE.size
        code = data[pos:pos + size]
        pos = align4(pos + size)
        mask, invariant, fast_math, digest, source_size, lib_size, push = METAL_STAGE.unpack_from(data, pos)
        pos += METAL_STAGE.size
        if compression not in (0, 1) or not 0 < raw_size <= 64 * 1024 * 1024:
            raise ValueError('Unsupported Metal shader compression or stage size')
        payload = zstd.ZstdDecompressor().decompress(code, max_output_size=raw_size) if compression else code
        source = payload[:source_size]
        if len(payload) != raw_size or raw_size != source_size + lib_size or hashlib.sha256(source).digest() != digest:
            raise ValueError('Shader stage length or SHA-256 differs from its reflection')
        existing = payload[source_size:]
        if existing and not existing.startswith(b'MTLB'):
            raise ValueError('Invalid embedded metallib')
        library = library_for(digest.hex(), source, bool(invariant), existing)
        if library is None:
            result.extend(data[start:pos])
            continue
        if existing or not library.startswith(b'MTLB'):
            raise ValueError('Expected a new Apple Metal library')
        has_library = True
        packed = zstd.ZstdCompressor(level=3).compress(source + library)
        result.extend(STAGE.pack(kind, len(packed), 1, len(source) + len(library)))
        result.extend(packed)
        result.extend(bytes(align4(len(result)) - len(result)))
        result.extend(METAL_STAGE.pack(mask, invariant, fast_math, digest, source_size, len(library), push))
    if pos != len(data):
        raise ValueError('Unaccounted bytes in shader container')
    if has_library:
        U32.pack_into(result, MIN_OS_OFFSET, MACOS_TARGET)
    return bytes(result)


def group(data, library_for):
    if data[:8] != b'GDSC\x04\0\0\0':
        raise ValueError('Unsupported Godot shader cache version')
    count, = U32.unpack_from(data, 8)
    output = bytearray(data[:12])
    pos = 12
    for _ in range(count):
        length, = U32.unpack_from(data, pos)
        pos += U32.size
        content = variant(data[pos:pos + length], library_for) if length else b''
        pos += length
        output.extend(U32.pack(len(content)))
        output.extend(content)
    if pos != len(data):
        raise ValueError('Unaccounted bytes in shader group')
    return bytes(output)


def compile_stage(entry, directory, logs):
    digest, (source, invariant) = entry
    shader = directory / (digest + '.metal')
    library = shader.with_suffix('.metallib')
    shader.write_bytes(source)
    command = ['xcrun', '-sdk', 'macosx', 'metal', '-O3', '-std=metal4.0', '-mmacosx-version-min=26.0',
               '-ffast-math', *(['-fpreserve-invariance'] if invariant else []), str(shader), '-o', str(library)]
    with (logs / (digest + '.log')).open('w') as log:
        print(' '.join(command), file=log, flush=True)
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
        subprocess.run(['xcrun', '-sdk', 'macosx', 'metal-dsymutil', '--remove-source', str(library)],
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    content = library.read_bytes()
    if not content.startswith(b'MTLB'):
        raise ValueError('Metal compiler did not produce a library for ' + digest)
    return digest, content


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('trace', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('--inspect', action='store_true', help='Validate coverage and byte-exact source round trips only')
    opt = parser.parse_args()
    opt.out.mkdir(parents=True, exist_ok=False)
    inventory = opt.app / 'Contents/Resources/MetalShaders'
    profile = plistlib.loads((inventory / 'Profile.plist').read_bytes())
    with ZipFile(opt.trace) as archive:
        events = [json.loads(line) for line in archive.read('player-first/signposts.ndjson').splitlines() if line.startswith(b'{')]
    observed = {int(e['eventMessage'].split('hash=')[-1], 16) for e in events
                if e.get('signpostName') == 'shader_compile' and e.get('signpostType') == 'begin'}
    sources = {}
    groups = {}

    def collect(digest, source, invariant, existing):
        if existing:
            raise ValueError('Only source inventory may be baked')
        if int(digest[:8], 16) in observed:
            entry = source, invariant
            if sources.setdefault(digest, entry) != entry:
                raise ValueError('A shader digest has different compiler options')

    for name, expected in profile['files'].items():
        data = (inventory / name).read_bytes()
        if hashlib.sha256(data).hexdigest() != expected or group(data, collect) != data:
            raise ValueError('Source inventory failed verification for ' + name)
        groups[name] = data
    covered = {int(key[:8], 16) for key in sources}
    receipt = {'source_groups': len(groups), 'trace_sha256': hashlib.sha256(opt.trace.read_bytes()).hexdigest(),
               'observed': len(observed), 'source_hashes': sorted(sources),
               'remaining_source': [format(key, 'x') for key in sorted(observed - covered)]}
    (opt.out / 'coverage.json').write_text(json.dumps(receipt, indent=2))
    if not sources or len(covered) != len(sources) or covered != observed:
        raise ValueError('The inventory does not uniquely cover the observed shader stages')
    if opt.inspect:
        return
    logs = opt.out / 'compiler-logs'
    logs.mkdir()
    with tempfile.TemporaryDirectory() as temp, ThreadPoolExecutor(max_workers=3) as workers:
        libs = dict(workers.map(lambda entry: compile_stage(entry, Path(temp), logs), sorted(sources.items())))
    dest = opt.out / 'MetalShaders'
    dest.mkdir()
    digests = {}
    verified = set()

    def verify(digest, source, invariant, existing):
        if existing != libs.get(digest, b''):
            raise ValueError('Stored library differs from compiler output for ' + digest)
        if existing:
            verified.add(digest)

    for name, data in groups.items():
        baked = group(data, lambda digest, source, invariant, existing: libs.get(digest))
        if group(baked, verify) != baked:
            raise ValueError('Baked library did not round-trip for ' + name)
        target = dest / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(baked)
        digests[name] = hashlib.sha256(baked).hexdigest()
    if verified != sources.keys():
        raise ValueError('Missing output library')
    profile.update(files=digests, min_os_version='26.0')
    (dest / 'Profile.plist').write_bytes(plistlib.dumps(profile))
    receipt['compiled_libraries'] = len(verified)
    receipt['library_bytes'] = sum(map(len, libs.values()))
    (opt.out / 'coverage.json').write_text(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    main()
