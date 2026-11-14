#!/usr/bin/env python3
"""Fetch unmodified CC0 Poly Haven 1K maps; record source URLs and checksums."""
import concurrent.futures, hashlib, json, pathlib, subprocess
ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSETS = ['brick_wall_001', 'rusty_painted_metal', 'wood_planks_grey', 'concrete_floor_worn_001', 'asphalt_02', 'denim_fabric', 'rusty_corrugated_iron', 'green_metal_rust', 'gravel_stones']

def fetch(asset):
    metadata = json.loads(subprocess.check_output(['curl', '-L', '--fail', '--silent', '--retry', '3', 'https://api.polyhaven.com/files/' + asset]))
    files = []
    for channel, choices in [('albedo', ['Diffuse', 'diff']), ('normal', ['nor_gl']), ('roughness', ['Rough', 'rough'])]:
        key = next(key for key in choices if key in metadata)
        info = metadata[key]['1k']['jpg']
        path = ROOT / 'assets/pbr' / f'{asset}_{channel}.jpg'
        subprocess.run(['curl', '-L', '--fail', '--silent', '--retry', '3', info['url'], '-o', str(path)], check=True)
        files.append({'path': str(path.relative_to(ROOT)), 'url': info['url'], 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    return {'asset': asset, 'source': 'https://polyhaven.com/a/' + asset, 'license': 'CC0-1.0', 'license_url': 'https://polyhaven.com/license', 'files': files}

if __name__ == '__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        manifest = list(executor.map(fetch, ASSETS))
    (ROOT / 'assets/pbr/sources.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Fetched {sum(len(a["files"]) for a in manifest)} CC0 texture maps.')
