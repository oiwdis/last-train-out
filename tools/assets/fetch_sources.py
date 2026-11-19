#!/usr/bin/env python3
"""Fetch the recorded public CC0 sources; accept the free animation ZIP from its publisher."""
import argparse
import hashlib
import json
import subprocess
import urllib.request
import uuid
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def fetch(url, destination, checksum):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists():
        subprocess.run(['curl', '--fail', '--location', '--retry', '3', '--silent', '--show-error', url, '-o', str(destination)], check=True)
    if hashlib.sha256(destination.read_bytes()).hexdigest() != checksum:
        raise RuntimeError(f'Source changed or incomplete: {destination}; inspect the publisher before accepting a new checksum')

def extract(archive, destination):
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as packed:
        for name in packed.namelist():
            if not (destination/name).resolve().is_relative_to(destination.resolve()):
                raise RuntimeError('Unsafe archive path')
        packed.extractall(destination)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--work', type=Path, default=Path('/tmp/last-train-out-assets'))
    args = parser.parse_args()
    sources = args.work/'sources'
    archives = json.loads((ROOT/'assets/characters/sources.json').read_text())['archives']
    for entry in archives[:3]:
        stem = entry['file'].removesuffix('_cc0.zip')
        fetch(f'https://files.makehumancommunity.org/asset_packs/{stem}/{entry["file"]}', sources/entry['file'], entry['sha256'])
        extract(sources/entry['file'], args.work/'makehuman'/'data')
    animation = archives[3]
    animation_path = sources/animation['file']
    if not animation_path.exists():
        raise SystemExit(f'Download the free Standard ZIP at https://quaternius.itch.io/universal-animation-library and save as {animation_path}, then rerun. No purchase or account is required.')
    assert hashlib.sha256(animation_path.read_bytes()).hexdigest() == animation['sha256']
    extract(animation_path, sources/'animations')
    train = archives[4]
    if not (sources/train['file']).exists():
        url = 'https://www.blenderkit.com/api/v1/downloads/ef6b70a2-6035-4676-97f4-9f1c00ffa7df/?scene_uuid=' + str(uuid.uuid4())
        with urllib.request.urlopen(url) as response:
            download = json.load(response)['filePath']
        fetch(download, sources/train['file'], train['sha256'])
    else:
        assert hashlib.sha256((sources/train['file']).read_bytes()).hexdigest() == train['sha256']
    for asset in json.loads((ROOT/'assets/props/sources.json').read_text()):
        for file in asset['files']:
            fetch(file['url'], sources/'polyhaven'/asset['id']/file['file'], file['sha256'])
    sky = json.loads((ROOT/'assets/sky/source.json').read_text())
    fetch(sky['download'], ROOT/'assets/sky'/(sky['id']+'_1k.hdr'), sky['sha256'])
    print('Recorded CC0 sources verified. See docs/ASSET_PIPELINE.md for the pinned MPFB checkout and build commands.')
