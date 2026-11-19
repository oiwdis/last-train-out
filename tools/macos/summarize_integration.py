#!/usr/bin/env python3
"""Tabulate raw native measurements without dropping tails or failed/missing runs."""
import csv
import json
from pathlib import Path
import sys

folder = Path(sys.argv[1])
matrix = json.loads((folder / 'integration-matrix.json').read_text())
columns = ['location', 'preset', 'stage', 'fps_from_mean', 'mean_ms', 'p50_ms',
           'p95_ms', 'p99_ms', 'worst_ms', 'process_ms', 'physics_ms', 'render_cpu_ms',
           'render_gpu_ms', 'draw_calls', 'texture_bytes', 'static_memory_bytes', 'render_scale']
with (folder / 'all-locations.csv').open('w', newline='') as stream:
    writer = csv.DictWriter(stream, fieldnames=columns, extrasaction='ignore')
    writer.writeheader()
    writer.writerows(matrix['results'])
comparisons = []
for source in ['source-art', 'source-survival']:
    data = json.loads((folder / (source + '-harlow.json')).read_text())
    baseline = {(row['location'], row['preset']): row for row in data['results'] if row['stage'] == 'steady'}
    for row in matrix['results']:
        key = row['location'], row['preset']
        if row['stage'] != 'steady' or key not in baseline:
            continue
        old = baseline[key]
        comparisons.append({'source': source, 'source_driver': data['driver'],
                            'integration_driver': matrix['driver'],
                            'location': key[0], 'preset': key[1],
                            'source_mean_ms': old['mean_ms'], 'integration_mean_ms': row['mean_ms'],
                            'mean_change_percent': (row['mean_ms']/old['mean_ms']-1)*100,
                            'source_p99_ms': old['p99_ms'], 'integration_p99_ms': row['p99_ms'],
                            'source_worst_ms': old['worst_ms'], 'integration_worst_ms': row['worst_ms']})
with (folder / 'source-comparison.csv').open('w', newline='') as stream:
    writer = csv.DictWriter(stream, fieldnames=list(comparisons[0]))
    writer.writeheader()
    writer.writerows(comparisons)
summary = {'host': json.loads((folder / 'host.json').read_text()),
           'adapter': matrix['adapter'], 'loading': matrix['loading'],
           'preset_preparation': matrix['preset_preparation'],
           'gpu_timing_available': any(row['render_gpu_ms'] > 0 for row in matrix['results']),
           'worst_steady_case': max((r for r in matrix['results'] if r['stage'] == 'steady'), key=lambda r:r['p99_ms']),
           'worst_entry_case': max((r for r in matrix['results'] if r['stage'] == 'entry'), key=lambda r:r['worst_ms']),
           'source_comparisons': comparisons}
for label in ['worst_steady_case', 'worst_entry_case']:
    summary[label] = {k:v for k,v in summary[label].items() if k != 'frames_ms'}
(folder / 'summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
