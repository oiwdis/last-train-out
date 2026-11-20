"""Pool the original entry/steady intervals and present all 36 paired views."""
import argparse
from collections import defaultdict
import csv
import json
import math
from pathlib import Path
from statistics import mean
from zipfile import ZipFile


def percentile(sorted_frames, fraction):
    return sorted_frames[math.ceil(len(sorted_frames) * fraction) - 1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    groups = defaultdict(list)
    with ZipFile(args.archive) as archive:
        for driver in ('metal', 'vulkan'):
            for repeat in (1, 2):
                name = f'{driver}-matrix-{repeat}.json'
                data = json.loads(archive.read(name))
                if data['driver'] != driver or len(data['results']) != 72:
                    raise ValueError(name)
                for row in data['results']:
                    groups[driver, row['stage']].extend(row['frames_ms'])
    table = []
    for (driver, stage), frames in groups.items():
        frames.sort()
        table.append(dict(driver=driver, stage=stage, count=len(frames), mean=round(mean(frames), 3),
                          median=percentile(frames, .5), p95=percentile(frames, .95),
                          p99=percentile(frames, .99), worst=max(frames),
                          over33_3=sum(v > 33.3 for v in frames), over50=sum(v > 50 for v in frames),
                          over100=sum(v > 100 for v in frames)))
    with (args.out / 'global.csv').open('w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(table[0]), lineterminator='\n')
        writer.writeheader()
        writer.writerows(table)

    with (args.out / 'pooled.csv').open() as f:
        views = {(r['driver'], r['stage'], r['preset'], r['location']): r for r in csv.DictReader(f)}
    locations = ['Harlow platform', 'Warehouse A', 'Warehouse B', 'Locomotive cab', 'Passenger car', 'Curved railway',
                 'Ashford Depot', 'Ashford workshop', 'Blackwater Crossing', 'Near advancing fog', 'Inside dangerous fog',
                 'Mission completion']
    lines = ['# Matched frame times at all 36 views', '',
             'Each cell gives native Metal and Vulkan in that order. Within a renderer the two values are p99 and worst frame time, in milliseconds. Two timing passes reverse driver order and use the same pack, 960×540 window, positions, preset, fog state and disabled V-sync. Screenshot readback happens in separate processes. The underlying tables retain each threshold count, frame distribution, process memory peak, CPU time, draw calls and texture allocation.', '',
             '[Global frame distributions](global.csv) · [All per-view statistics](pooled.csv) · [Per-attempt rendering counters and RSS](frames.csv) · [Attempt status and diagnostics](attempts.csv) · [Original logs, reports and 72 PNGs](../raw/metal-drivers.zip)']
    for stage in ('entry', 'steady'):
        lines += ['', '## ' + stage.title() + ' intervals', '',
                  '| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |', '|---|---:|---:|---:|']
        for location in locations:
            cells = [location]
            for preset in ('Low', 'Medium', 'High'):
                values = []
                for driver in ('metal', 'vulkan'):
                    row = views[driver, stage, preset, location]
                    values.append(f"{float(row['p99_ms']):.1f}, {float(row['worst_ms']):.1f}")
                cells.append(' / '.join(values))
            lines.append('| ' + ' | '.join(cells) + ' |')
    (args.out / 'README.md').write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
