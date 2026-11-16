#!/usr/bin/env python3
"""Repair historical failed image metadata using an identical verified source."""
from pathlib import Path
import shutil
import sys

root = Path(__file__).resolve().parents[2]
baseline = Path(sys.argv[1]).resolve()
for settings in sorted((baseline / 'assets').rglob('*.import')):
    if 'valid=false' not in settings.read_text():
        continue
    source = settings.with_suffix('')
    current = root / source.relative_to(baseline)
    assert source.read_bytes() == current.read_bytes(), f'Baseline image differs: {source}'
    fixed = current.with_name(current.name + '.import')
    assert 'valid=false' not in fixed.read_text(), fixed
    shutil.copy2(fixed, settings)
    print('Repaired historical import metadata:', settings.relative_to(baseline))
