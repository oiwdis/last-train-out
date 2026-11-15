#!/usr/bin/env python3
"""Apply explicit 3D texture settings; headless imports do not trigger editor 3D detection."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
count = 0
for folder in ['characters', 'props', 'train', 'environment', 'pbr', 'sky']:
    for path in (ROOT/'assets'/folder).glob('*.import'):
        text = path.read_text()
        if 'importer="texture"' not in text:
            continue
        text = text.replace('compress/mode=0', 'compress/mode=2')
        text = text.replace('compress/high_quality=false', 'compress/high_quality=true')
        text = text.replace('mipmaps/generate=false', 'mipmaps/generate=true')
        if any(word in path.name.lower() for word in ['normal', 'nor_gl', 'nrm']):
            text = text.replace('compress/normal_map=0', 'compress/normal_map=1')
        path.write_text(text)
        count += 1
print(f'Configured {count} 3D texture imports for VRAM compression and mipmaps; run Godot --headless --import next.')
