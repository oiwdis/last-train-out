"""Align first-entry render intervals with the packaged player's native Metal signposts."""
import argparse
from datetime import datetime
import csv
import json
from pathlib import Path
from statistics import median
from zipfile import ZipFile


OPERATIONS = ('shader_compile', 'compute_pipeline_create', 'render_pipeline_create')


def native_intervals(events, pid):
    starts, intervals, unpaired = {}, [], []
    for event in sorted(events, key=lambda row: row.get('machTimestamp', 0)):
        operation = event.get('signpostName')
        if event.get('processID') != pid or operation not in OPERATIONS:
            continue
        stamp = datetime.fromisoformat(event['timestamp']).timestamp()
        key = operation, event['signpostID'], 0 if operation == 'shader_compile' else event['threadID']
        if event.get('signpostType') == 'begin':
            if key in starts:
                unpaired.append(key)
            starts[key] = stamp
        elif event.get('signpostType') == 'end':
            begin = starts.pop(key, None)
            if begin is None:
                unpaired.append(key)
            else:
                intervals.append((operation, begin, stamp))
    return intervals, unpaired + list(starts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    with ZipFile(args.archive) as archive:
        profile = json.loads(archive.read('entry-profile.json'))['sampled']
        data = json.loads(archive.read('sampled.json'))
        repeat = json.loads(archive.read('repeat.json'))
        events = [json.loads(line) for line in archive.read('signposts.ndjson').splitlines() if line.startswith(b'{')]
    intervals, unpaired = native_intervals(events, profile['pid'])
    phases = profile['stages']
    offsets = {phase: row['marker_wall_ns'] / 1e9 - row['ticks_ms'] / 1000 for phase, row in phases.items()}
    # The fixture stamps the stage file with integer milliseconds on the same
    # Mac. Allow the entire observed offset spread plus 2 ms on each side.
    margin = max(offsets.values()) - min(offsets.values()) + .002
    clock = dict(observed_stage_markers=len(offsets), marker_offset_median_s=median(offsets.values()),
                 alignment_margin_ms=margin * 1000, source_process=profile['pid'],
                 signposted_counts={op:sum(k == op for k, _, _ in intervals) for op in OPERATIONS},
                 unmatched_signposts=unpaired)
    (args.out / 'alignment.json').write_text(json.dumps(clock, indent=2) + '\n')
    rows = []
    for source, matrix in [('sampled', data), ('unprofiled-repeat', repeat)]:
        for r in matrix['results']:
            phase = '/'.join((r['preset'], r['location'], r['stage']))
            i = r['frames_ms'].index(max(r['frames_ms']))
            t = r['timeline'][i]
            row = dict(run=source, phase=phase, window_frame=i + 1, worst_ms=r['frames_ms'][i],
                       render_bracket_ms=t['render_bracket_ms'], render_setup_ms=t['render_setup_cpu_ms'],
                       physics_ms=t['physics_bracket_ms'], process_ms=t['process_bracket_ms'],
                       stack_sample_requested=source == 'sampled' and phase in profile['samplers'])
            for op in OPERATIONS:
                row[op + '_overlaps'] = ''
            if source == 'sampled' and phase in offsets:
                end = offsets[phase] + t['ticks_ms'] / 1000
                start = end - t['frame_ms'] / 1000
                for op in OPERATIONS:
                    row[op + '_overlaps'] = sum(k == op and begin <= end + margin and finish >= start - margin
                                                for k, begin, finish in intervals)
            rows.append(row)
    with (args.out / 'entry-phases.csv').open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=rows[0], lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)


if __name__ == '__main__':
    main()
