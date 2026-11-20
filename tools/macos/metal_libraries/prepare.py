"""Package verified build-time Metal libraries separately from writable game caches."""
import hashlib
import json
from pathlib import Path
import plistlib
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

PROFILE_KEYS = ('family', 'language', 'argumentBuffers')
PACKAGED = Path(__file__).with_name('apple5-msl4-macos26.zip')


def archive_groups(source, libraries, destination):
    """Freeze only groups changed by the offline compiler after its rendered comparison."""
    profile = plistlib.loads((source / 'Profile.plist').read_bytes())
    baked = plistlib.loads((libraries / 'Profile.plist').read_bytes())
    if set(profile['files']) != set(baked['files']) or any(profile[k] != baked[k] for k in PROFILE_KEYS):
        raise ValueError('The two shader inventories must describe the same profile and groups')
    meta = {key: baked[key] for key in (*PROFILE_KEYS, 'min_os_version')}
    meta['groups'] = {}

    def add(archive, name, data):
        item = ZipInfo(name)
        item.external_attr = 0o644 << 16
        item.compress_type = ZIP_DEFLATED
        archive.writestr(item, data)

    with ZipFile(destination, 'x') as out:
        for key, source_hash in sorted(profile['files'].items()):
            original = (source / key).read_bytes()
            compiled = (libraries / key).read_bytes()
            output_hash = hashlib.sha256(compiled).hexdigest()
            if hashlib.sha256(original).hexdigest() != source_hash or output_hash != baked['files'][key]:
                raise ValueError('Shader group differs from its inventory: ' + key)
            if source_hash != output_hash:
                meta['groups'][key] = {'source_sha256':source_hash, 'library_sha256':output_hash}
                add(out, key, compiled)
        add(out, 'manifest.json', json.dumps(meta, indent=2).encode())


def install_compatible_groups(resources, profile, archive=PACKAGED):
    """Use a group only when its current source and device profile match the tested input."""
    with ZipFile(archive) as packed:
        manifest = json.loads(packed.read('manifest.json'))
        if any(profile[key] != manifest[key] for key in PROFILE_KEYS):
            return {}
        files = {}
        dest = resources / 'MetalLibraries'
        for key, hashes in manifest['groups'].items():
            # Keys must come from the freshly rendered source inventory. The
            # exporter already validated those relative paths and source hashes.
            if profile['files'].get(key) != hashes['source_sha256']:
                continue
            library = packed.read(key)
            if hashlib.sha256(library).hexdigest() != hashes['library_sha256']:
                raise ValueError('Compiled shader group differs from its release receipt: ' + key)
            file = dest / key
            file.parent.mkdir(exist_ok=True, parents=True)
            file.write_bytes(library)
            files[key] = hashes['library_sha256']
        if files:
            inventory = dict(profile, files=files, min_os_version=manifest['min_os_version'])
            (dest / 'Profile.plist').write_bytes(plistlib.dumps(inventory))
        return files


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Freeze a tested pair of source and compiled inventories')
    for name in ('source', 'libraries', 'destination'):
        parser.add_argument(name, type=Path)
    args = parser.parse_args()
    archive_groups(args.source, args.libraries, args.destination)
