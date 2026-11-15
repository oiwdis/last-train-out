#!/usr/bin/env python3
"""Validate self-contained production GLBs, texture payloads and skin data before export."""
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def inspect(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from('<4sII', data)
    assert magic == b'glTF' and version == 2 and length == len(data), path
    json_length, kind = struct.unpack_from('<II', data, 12)
    assert kind == 0x4E4F534A, path
    doc = json.loads(data[20:20 + json_length])
    binary_offset = 20 + json_length
    binary_length, kind = struct.unpack_from('<II', data, binary_offset)
    assert kind == 0x004E4942 and binary_length > 0, path
    blob = data[binary_offset + 8:]
    assert not any('uri' in buffer for buffer in doc['buffers']), (path, 'external buffer')
    for view in doc['bufferViews']:
        assert view.get('byteOffset', 0) + view['byteLength'] <= len(blob), path
    for image in doc.get('images', []):
        assert 'bufferView' in image, (path, 'external or missing image')
        view = doc['bufferViews'][image['bufferView']]
        payload = blob[view.get('byteOffset', 0):][:view['byteLength']]
        assert len(payload) > 128 and payload.startswith((b'\x89PNG', b'\xff\xd8')), (path, image)
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            position = doc['accessors'][primitive['attributes']['POSITION']]
            assert position['count'] > 0, path
            assert all(math.isfinite(x) for x in position['min'] + position['max']), path
            assert 'NORMAL' in primitive['attributes'], (path, 'missing normals')
            assert 'material' in primitive, (path, 'missing material')
    if path.name == 'railway_survivor.glb':
        assert len(doc['images']) >= 10, 'Character PBR images were lost during Blender path relocation'
        assert len(doc['skins'][0]['joints']) == 52
        assert len(doc['animations']) >= 14
        for mesh in doc['meshes']:
            assert all('WEIGHTS_0' in p['attributes'] and 'JOINTS_0' in p['attributes'] for p in mesh['primitives']), mesh['name']
    return {'file': str(path.relative_to(ROOT)), 'bytes': len(data), 'meshes': len(doc['meshes']), 'images': len(doc.get('images', [])), 'sha256': __import__('hashlib').sha256(data).hexdigest()}

if __name__ == '__main__':
    rows = [inspect(p) for folder in ['characters', 'props', 'train', 'environment'] for p in sorted((ROOT/'assets'/folder).glob('*.glb'))]
    assert len(rows) >= 20, 'Production asset set is incomplete'
    textures = 0
    for folder in ['characters', 'props', 'train', 'environment', 'pbr', 'sky']:
        for path in (ROOT/'assets'/folder).glob('*.import'):
            settings = path.read_text()
            if 'importer="texture"' in settings:
                assert 'valid=false' not in settings, (path, 'failed texture import record committed')
                assert path.with_suffix('').is_file(), (path, 'missing extracted texture source')
                assert 'compress/mode=2' in settings and 'mipmaps/generate=true' in settings, (path, '3D texture budget not configured')
                textures += 1
    print(json.dumps({'validated': len(rows), 'compressed_mipmapped_textures': textures, 'assets': rows}, indent=2))
