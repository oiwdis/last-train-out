"""Summarize original-PCK shadow and backend experiments, including failed attempts."""
import argparse
import csv
import json
from pathlib import Path
import statistics
import sys
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'tools/macos'))
from renderer_diagnostics import engine_diagnostics


def read_json_member(archive, name):
    if name in archive.namelist():
        return json.loads(archive.read(name))
    return {}


def summarize(source):
    with zipfile.ZipFile(source) as archive:
        series = read_json_member(archive, 'series.json')
        for run in series['runs']:
            attempt = run['name']
            key = attempt + '.log'
            lines = archive.read(key).decode(errors='replace').splitlines() if key in archive.namelist() else []
            phases = []
            for line in lines:
                if line.startswith('[phase] {') and line.endswith('}'):
                    phases.append(json.loads(line[len('[phase] '):]))
            report = read_json_member(archive, attempt + '.json')
            final = phases[-1] if phases else {}
            frames = report.get('first_frames_ms', [])
            yield dict(source=source.name, group=series['group'], attempt=attempt, requested_method=run['method'],
                       requested_driver=run['driver'], actual_method=run.get('actual',[None,None])[0],
                       actual_driver=run.get('actual',[None,None])[1], treatment=run['treatment'], cold=run['cold'],
                       passed=run['passed'], code=run['code'], timeout=run.get('timeout',False),
                       skipped=run.get('skipped',''), device_loss=run.get('device_loss',False),
                       ready_ms=run.get('ready_ms'), wall_s=run.get('seconds'), rss_mib=run.get('peak_rss',0)/2**20,
                       last_phase=final.get('phase'), specializations=final.get('pipeline_specialization'),
                       texture_mib=final.get('texture_bytes',0)/2**20, restored='restored' in run.get('shadow_phases',[]),
                       worst_post_ready_ms=max(frames,default=None),
                       first_gpu_error=next((line for line in lines if 'kIOGPUCommandBufferCallbackErrorTimeout' in line),''),
                       engine_diagnostics=json.dumps(engine_diagnostics(lines)),
                       original_diagnostics=json.dumps(run.get('diagnostics', [])))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination',type=Path)
    parser.add_argument('archives',nargs='+',type=Path)
    opt = parser.parse_args()
    opt.destination.mkdir(parents=True,exist_ok=True)
    rows = [r for source in opt.archives for r in summarize(source)]
    with (opt.destination/'attempts.csv').open('w',newline='') as stream:
        writer = csv.DictWriter(stream,fieldnames=list(rows[0]),lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)
    lines = ['# Experiments on the original release pack','',
             'All cases ran the same exported 6038bfcd game at 960×540, High. Each runner used isolated writable application caches. The shadow cohorts rotated control and three covered atlas configurations. All original camera, material, and geometry work remained in place. Full preset shadow sizes were restored before the final camera drain. Backend cohorts paired a fresh cache with a warm launch on that same cache. A method/driver mismatch or inability to write a full report fails the attempt.','',
             '| Raw archive | Method/driver | Covered atlas change | Cache | Passed / attempted | GPU loss | Other failure | Ready min / median / max, s |',
             '|---|---|---|---|---:|---:|---:|---|']
    for source in opt.archives:
        cohort=[r for r in rows if r['source']==source.name]
        keys=dict.fromkeys((r['requested_method'],r['requested_driver'],r['treatment'],r['cold']) for r in cohort)
        for method,driver,treatment,cold in keys:
            attempts=[r for r in cohort if (r['requested_method'],r['requested_driver'],r['treatment'],r['cold'])==(method,driver,treatment,cold)]
            passed=sum(r['passed'] for r in attempts)
            loss=sum(r['device_loss'] for r in attempts)
            ready=[r['ready_ms']/1000 for r in attempts if r['passed'] and r['ready_ms'] is not None]
            spread=' / '.join(f'{v:.3f}' for v in (min(ready),statistics.median(ready),max(ready))) if ready else '—'
            lines.append(f"| [{source.name}]({source.name}) | {method}/{driver} | {treatment} | {'cold' if cold else 'warm'} | {passed}/{len(attempts)} | {loss} | {len(attempts)-passed-loss} | {spread} |")
    lines += ['','[All attempted processes, diagnostics, last phase and RSS](attempts.csv)']
    (opt.destination/'EXPERIMENTS.md').write_text('\n'.join(lines)+'\n')


if __name__ == '__main__':
    main()
