"""Summarize every exported stress attempt; missing reports remain failures."""
import csv
import json
from pathlib import Path
import sys

source, destination = map(Path, sys.argv[1:])
destination.mkdir(parents=True, exist_ok=True)
series = json.loads((source / 'stress.json').read_text())
rows = []
for run in series['runs']:
    report = source / (run['name'] + '.json')
    report_error = run.get('report_error', '')
    try:
        data = json.loads(report.read_text()) if report.exists() else {}
    except (ValueError, OSError) as error:
        data = {}
        report_error = str(error)
    events = {e['phase']: e['ticks_ms'] for e in data.get('events', [])}
    ready = events.get('mission_ready')
    row = {'attempt': run['name'], 'exit': run['returncode'],
           'complete': run.get('complete', False), 'device_loss': run.get('device_loss', False),
           'diagnostics': len(run.get('diagnostics', [])), 'timed_out': run.get('timed_out', False),
           'skipped': run.get('skipped', ''), 'report_error': report_error, 'ready_ms': ready,
           'process_seconds': run.get('wall_seconds'),
           'peak_rss_mib': run.get('peak_rss_bytes', 0) / 1048576,
           'checks': len(data.get('checks', [])), 'failed_checks': data.get('failed'),
           'cache_files_before': run.get('cache_before', {}).get('files'),
           'cache_files_after': run.get('cache_after', {}).get('files'),
           'cache_bytes_after': run.get('cache_after', {}).get('bytes')}
    for key, begin, end in [('load_ms', 'load_begin', 'load_end'),
                            ('instantiate_ms', 'load_end', 'instantiate_end'),
                            ('activate_ms', 'instantiate_end', 'add_child_end'),
                            ('preparation_ready_ms', 'add_child_end', 'mission_ready')]:
        row[key] = events[end] - events[begin] if begin in events and end in events else None
    rows.append(row)
with (destination / 'every-attempt.csv').open('w') as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]),lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
lines = ['# Exported Vulkan stress: every attempt', '',
         'Source `' + series['source'] + '`; pack SHA-256 `' + series['pack_sha256'] + '`.', '',
         series['scope'] + '. ' + series['cache_conditions'] + '.', '',
         'This is a predetermined bounded series. No failed run is replaced by a retry. '
         'Process lifetime includes settling and shutdown; mission-ready time does not. '
         'RSS is sampled, not a complete GPU-memory measurement.', '',
         '| Attempt | Exit | Complete | Ready seconds | Process seconds | Peak RSS MiB | Diagnostics | Device loss |',
         '|---|---:|---|---:|---:|---:|---:|---|']
for row in rows:
    ready = '—' if row['ready_ms'] is None else f"{row['ready_ms']/1000:.3f}"
    seconds = '—' if row['process_seconds'] is None else f"{row['process_seconds']:.3f}"
    lines.append(f"| {row['attempt']} | {row['exit']} | {row['complete']} | {ready} | {seconds} | "
                 f"{row['peak_rss_mib']:.2f} | {row['diagnostics']} | {row['device_loss']} |")
lines.extend(['', 'Series passed: **' + str(series.get('passed', False)) + '**. '
              'Missing/skipped attempts remain incomplete. Detailed stages, cache inventories and '
              'check counts are in `every-attempt.csv`; raw files retain each diagnostic and frame.', ''])
(destination / 'STRESS.md').write_text('\n'.join(lines))
