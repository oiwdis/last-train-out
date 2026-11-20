"""Build CSVs directly from renderer_lab archives, including partial and failed runs."""
import argparse
from collections import defaultdict
import csv
import json
import math
from pathlib import Path
import statistics
import zipfile


def write_rows(path, rows):
    if rows:
        with path.open('w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator='\n')
            writer.writeheader()
            writer.writerows(rows)


def pctl(values, q):
    return sorted(values)[max(0, math.ceil(q * len(values)) - 1)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('out', type=Path)
    parser.add_argument('archives', type=Path, nargs='+')
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    runs, phases, frames = [], [], []
    samples = defaultdict(list)
    for path in args.archives:
        with zipfile.ZipFile(path) as archive:
            def load(name):
                return json.loads(archive.read(name)) if name in archive.namelist() else {}
            metadata = load('series.json')
            for r in metadata['runs']:
                data = load(r['name'] + '.json')
                runs.append(dict(source=path.name, group=metadata['group'], name=r['name'], revision=r['revision'],
                                 variant=r['variant'], method=r['method'], driver=r['driver'], actual=r['actual'],
                                 actual_driver=r.get('actual_driver'), backend_match=r.get('valid_backend'),
                                 cold=r['cold'], exit=r['code'], timeout=r.get('timeout',False), complete=r['complete'],
                                 device_loss=r['device_loss'], ready_ms=r['ready_ms'], wall_s=r['seconds'],
                                 peak_rss_bytes=r['peak_rss'], diagnostics=json.dumps(r['diagnostics'])))
                records = data.get('phases',[])
                if not records:
                    records = [json.loads(line[8:]) for line in archive.read(r['name']+'.log').decode(errors='replace').splitlines()
                               if line.startswith('[phase] {') and line.endswith('}')]
                for record in records:
                    phases.append(dict(source=path.name,run=r['name'],phase=record['phase'],
                                       duration_ms=record.get('duration_ms'),ticks_ms=record.get('ticks_ms'),
                                       specialization=record.get('pipeline_specialization'),draw=record.get('pipeline_draw'),
                                       texture_bytes=record.get('texture_bytes')))
                measured = data.get('results', [])
                if not measured and r['name']+'.json.jsonl' in archive.namelist():
                    for line in archive.read(r['name']+'.json.jsonl').splitlines():
                        try:
                            partial = json.loads(line)
                        except ValueError:
                            break
                        if 'frames_ms' in partial: measured.append(partial)
                for row in measured:
                    vals = row['frames_ms']
                    # Screenshots and their readbacks are a separately instrumented run.
                    if '-matrix' in r['name']:
                        samples[(path.name, r['revision'], r['method'], row['preset'], row['location'], row['stage'])].extend(vals)
                    frames.append(dict(source=path.name,run=r['name'],revision=r['revision'],method=r['method'],complete=r['complete'],
                                       preset=row['preset'],location=row['location'],stage=row['stage'],samples=len(vals),
                                       mean_ms=statistics.mean(vals),fps=1000/statistics.mean(vals),
                                       median_ms=pctl(vals,.5),p95_ms=pctl(vals,.95),p99_ms=pctl(vals,.99),worst_ms=max(vals),
                                       over100=sum(v>100 for v in vals),draw_calls=row['draw_calls'],primitives=row['primitives'],
                                       render_cpu_ms=row['render_cpu_ms'],gpu_ms=row['render_gpu_ms'] or '',
                                       process_ms=row['process_ms'],physics_ms=row['physics_ms'],texture_bytes=row['texture_bytes'],
                                       process_rss_peak=r['peak_rss']))
    write_rows(args.out/'attempts.csv', runs)
    write_rows(args.out/'phases.csv', phases)
    write_rows(args.out/'frames.csv', frames)
    pooled = []
    for key, values in samples.items():
        row = dict(zip(('source','revision','method','preset','location','stage'), key))
        row.update(samples=len(values), mean_ms=statistics.mean(values), fps=1000/statistics.mean(values),
                   median_ms=pctl(values,.5), p95_ms=pctl(values,.95), p99_ms=pctl(values,.99),
                   worst_ms=max(values), over_33_3=sum(v>33.3 for v in values),
                   over_50=sum(v>50 for v in values), over_100=sum(v>100 for v in values))
        pooled.append(row)
    write_rows(args.out/'pooled.csv', pooled)


if __name__=='__main__':
    main()
