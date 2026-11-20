#!/usr/bin/env python3
"""Check repeated native startup evidence without treating an exit code as success.

Usage: python3 verify_startup_cache.py <extracted evidence directory> [prefix]
Prefix defaults to startup; the paired cohort uses optimized-startup.
No cache files are deleted or modified. Results are printed for retention.
"""
import json
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
prefix = sys.argv[2] if len(sys.argv) > 2 else 'startup'
rows = []
for attempt in range(1, 4):
    stem = root / f'{prefix}-{attempt}'
    report = json.loads(stem.with_suffix('.json').read_text())
    lines = stem.with_suffix('.log').read_text().splitlines()
    loaded = [float(match.group(1)) for line in lines
              if (match := re.search(r'Startup PSO cache \(([0-9.]+) MiB\)', line))]
    saved = [float(match.group(1)) for line in lines
             if (match := re.search(r'Updated PSO cache \(([0-9.]+) MiB\)', line))]
    diagnostics = [line for line in lines if line.startswith(('ERROR:', 'SCRIPT ERROR:',
                   'WARNING:', 'Leaked instance:', 'Resource still in use:'))]
    rows.append({'attempt': attempt, 'driver': report['driver'],
                 'mission_ready': report['mission_ready'], 'loaded_pso_mib': loaded,
                 'saved_pso_mib': saved, 'shader_misses': sum('Shader cache miss' in line for line in lines),
                 'diagnostics': diagnostics})
print(json.dumps(rows, indent=2))
assert all(r['mission_ready'] and not r['diagnostics'] for r in rows), 'Readiness or diagnostic failure'
assert all(r['driver'] == 'vulkan' for r in rows), 'This assertion is specific to Vulkan PSO reuse'
assert all(r['loaded_pso_mib'] and r['loaded_pso_mib'][0] > 0 for r in rows[1:]), 'Warm launches did not load the persisted PSO cache'
assert rows[0]['saved_pso_mib'] or (rows[0]['loaded_pso_mib'] and rows[0]['loaded_pso_mib'][0] > 0), 'First process neither saved nor loaded a cache'
print('PASS: three clean ready states and persisted PSO cache reuse across both warm launches.')
