"""Summarize Godot's signposted Metal intervals, preserving overlaps and pairing failures."""
import argparse
from collections import defaultdict
import csv
from datetime import datetime
import json
from pathlib import Path, PurePosixPath
from zipfile import ZipFile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('archives', nargs='+', type=Path)
    opt = parser.parse_args()
    result, shaders = [], []
    for path in opt.archives:
        with ZipFile(path) as z:
            files = sorted(f for f in z.namelist() if PurePosixPath(f).name == 'signposts.ndjson')
            if not files:
                raise ValueError(f'{path} has no Metal signpost stream')
            groups = defaultdict(list)
            for source in files:
                for line in z.read(source).splitlines():
                    if not line.startswith(b'{'):
                        continue
                    event = json.loads(line)
                    if event.get('signpostType') in ('begin', 'end'):
                        groups[(source, event['processID'], event['signpostName'])].append(event)
        for (source, pid, name), events in groups.items():
            active, durations, depth, union, unmatched = {}, [], 0, 0, 0
            for e in sorted(events, key=lambda row: row['machTimestamp']):
                t = datetime.fromisoformat(e['timestamp'])
                # The asynchronous library callback may execute on another
                # thread. Synchronous pipeline intervals use the caller thread.
                key = (e['signpostID'], 0 if name == 'shader_compile' else e['threadID'])
                if e['signpostType'] == 'begin':
                    if depth == 0: start = t
                    depth += 1
                    if key in active: unmatched += 1
                    active[key] = (t, e['eventMessage'])
                else:
                    beginning = active.pop(key, None)
                    if beginning is None:
                        unmatched += 1
                        continue
                    when, shader = beginning
                    durations.append(((t - when).total_seconds() * 1000, shader))
                    depth -= 1
                    if depth == 0: union += (t - start).total_seconds()
            unmatched += len(active)
            longest = max(durations, default=(None, None))
            per_shader = defaultdict(list)
            for duration, label in durations:
                per_shader[label.removeprefix('shader_name=').split(':', 1)[0]].append(duration)
            for shader, values in per_shader.items():
                shaders.append(dict(archive=path.name, stream=source, pid=pid, operation=name, shader=shader, count=len(values),
                                    worker_s=round(sum(values) / 1000, 4), longest_ms=round(max(values), 3)))
            result.append(dict(archive=path.name, stream=source, pid=pid, operation=name, count=len(durations),
                               aggregate_worker_s=round(sum(d for d, _ in durations) / 1000, 4),
                               union_wall_s=round(union, 4) if not unmatched else '',
                               longest_ms=round(longest[0], 3) if durations else None, longest_event=longest[1], unpaired=unmatched))
    for output, table in [(opt.output, result), (opt.output.with_name(opt.output.stem + '-shaders.csv'), shaders)]:
        if not table: continue
        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open('w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=list(table[0]), lineterminator='\n')
            writer.writeheader()
            writer.writerows(table)


if __name__ == '__main__':
    main()
