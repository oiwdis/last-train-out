"""Compare first and repeat entry frames and rendered images on each library-trial host."""
import argparse
import csv
import io
import json
from math import ceil
from pathlib import Path
from statistics import mean, median
from zipfile import ZipFile

from PIL import Image, ImageChops, ImageStat

from summarize_entry import native_intervals, OPERATIONS


def write_csv(path, rows):
    if rows:
        with path.open('w', newline='') as stream:
            writer = csv.DictWriter(stream, rows[0], lineterminator='\n')
            writer.writeheader()
            writer.writerows(rows)


def timing(archive, host, attempt, native):
    name = attempt['name']
    data = json.loads(archive.read(f'{name}/{name}.json'))
    rows = data['results']
    if data['driver'] != 'metal' or len(rows) != 72:
        raise ValueError(f'Incomplete Metal matrix in {host} {name}')
    for stage in ('entry', 'steady'):
        phases = [r for r in rows if r['stage'] == stage]
        worst = max(phases, key=lambda r: max(r['frames_ms']))
        samples = sorted(v for r in phases for v in r['frames_ms'])
        yield dict(host=host, attempt=name, stage=stage, samples=len(samples),
                   mean_ms=round(mean(samples), 3), median_ms=round(median(samples), 3),
                   p95_ms=samples[ceil(.95 * len(samples)) - 1], p99_ms=samples[ceil(.99 * len(samples)) - 1],
                   worst_ms=samples[-1], worst_preset=worst['preset'], worst_location=worst['location'],
                   over33_3=sum(v > 33.3 for v in samples), over50=sum(v > 50 for v in samples),
                   over100=sum(v > 100 for v in samples), peak_rss_bytes=attempt['peak_rss_bytes'], **native)


def signposts(archive, name):
    events = [json.loads(line) for line in archive.read(name + '/signposts.ndjson').splitlines() if line.startswith(b'{')]
    pids = {e['processID'] for e in events if e.get('signpostName') in OPERATIONS}
    if len(pids) != 1:
        raise ValueError(f'Expected one native Metal player PID in {name}, found {pids}')
    intervals, unmatched = native_intervals(events, pids.pop())
    counts = {op:sum(observed == op for observed, _, _ in intervals) for op in OPERATIONS}
    return dict(**counts, unmatched_endpoints=len(unmatched))


def screenshots(archive, host):
    versions = []
    for version in ('shipped', 'extended'):
        prefix = version + '-visual/shots/'
        versions.append({name[len(prefix):]:name for name in archive.namelist() if name.startswith(prefix) and name.endswith('.png')})
    shipped, extended = versions
    if len(shipped) != 36 or shipped.keys() != extended.keys():
        raise ValueError(f'Incomplete screenshot pairs on {host}')
    for view in sorted(shipped):
        with Image.open(io.BytesIO(archive.read(shipped[view]))) as before, Image.open(io.BytesIO(archive.read(extended[view]))) as after:
            if before.size != after.size:
                raise ValueError(view)
            diff = ImageChops.difference(before.convert('RGB'), after.convert('RGB'))
            yield dict(host=host, view=view, identical=diff.getbbox() is None,
                       mean_abs_level=round(mean(ImageStat.Stat(diff).mean), 6),
                       max_abs_level=max(high for _, high in diff.getextrema()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('out', type=Path)
    parser.add_argument('archives', nargs='+', type=Path)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    times, pixels = [], []
    for path in args.archives:
        with ZipFile(path) as archive:
            for attempt in json.loads(archive.read('attempts.json')):
                name = attempt['name']
                if '-matrix-' in name and f'{name}/{name}.json' in archive.namelist():
                    native = dict.fromkeys((*OPERATIONS, 'unmatched_endpoints'))
                    if name.endswith('matrix-1'):
                        native = signposts(archive, name)
                    times.extend(timing(archive, path.stem, attempt, native))
            pixels.extend(screenshots(archive, path.stem))
    write_csv(args.out / 'frames.csv', times)
    write_csv(args.out / 'pixels.csv', pixels)


if __name__ == '__main__':
    main()
