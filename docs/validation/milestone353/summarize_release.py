"""Tabulate all exported launch and lifecycle processes, including partial or failed attempts."""
import argparse
import csv
import json
import math
from pathlib import Path
import statistics
import sys
import zipfile

sys.path.insert(0,str(Path(__file__).resolve().parents[3]/'tools/macos'))
from renderer_diagnostics import engine_diagnostics


def percentile(vals, fraction):
    return sorted(vals)[math.ceil(len(vals)*fraction)-1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination',type=Path)
    parser.add_argument('archives',type=Path,nargs='+')
    opt=parser.parse_args()
    opt.destination.mkdir(parents=True,exist_ok=True)
    rows=[]
    for path in opt.archives:
        with zipfile.ZipFile(path) as z:
            data=json.loads(z.read('stress.json'))
            for run in data['runs']:
                name=run['name']
                report={}
                if name+'.json' in z.namelist():
                    try: report=json.loads(z.read(name+'.json'))
                    except ValueError: pass
                events={r['phase']:r['ticks_ms'] for r in report.get('events',[])}
                printed_ready=None
                last_phase=None
                diagnostics=run.get('diagnostics',[])
                if name+'.log' in z.namelist():
                    lines=z.read(name+'.log').decode(errors='replace').splitlines()
                    diagnostics=engine_diagnostics(lines)
                    for raw in lines:
                        if not raw.startswith(('[startup] {','[phase] {')) or not raw.endswith('}'):
                            continue
                        event=json.loads(raw[raw.index('{'):])
                        last_phase=event['phase']
                        if last_phase=='mission_ready':
                            printed_ready=event.get('ticks_ms')
                measured=report.get('results',[])
                if not measured and name+'.json.jsonl' in z.namelist():
                    for line in z.read(name+'.json.jsonl').splitlines():
                        try: record=json.loads(line)
                        except ValueError: break
                        if 'frames_ms' in record: measured.append(record)
                args=run['command'][run['command'].index('--')+1:]
                preset=next((a.split('=',1)[1] for a in args if a.startswith('--graphics=')),'')
                group=name.rsplit('-',1)[0] if name.rsplit('-',1)[-1].isdigit() else name
                completed=(run['returncode']==0 and run.get('complete',False)
                           and not run.get('device_loss') and not run.get('timed_out') and not run.get('skipped'))
                passed=completed and not diagnostics
                rows.append(dict(series=data.get('series','mixed'),attempt=name,group=group,preset=preset,
                                 requested_backend=data.get('experimental_backend') or 'release default',
                                 actual_method=run.get('renderer'),actual_driver=run.get('driver'),
                                 backend_mismatch=run.get('backend_mismatch',False),
                                 code=run['returncode'],completed=completed,passed=passed,device_loss=run.get('device_loss',False),
                                 timed_out=run.get('timed_out',False),skipped=run.get('skipped',''),
                                 diagnostics=len(diagnostics),original_diagnostic_count=len(run.get('diagnostics',[])),
                                 diagnostic_messages=json.dumps(diagnostics),
                                 engine_ms=events.get('script_initialized'),to_load_ms=diff(events,'script_initialized','load_begin'),
                                 load_ms=diff(events,'load_begin','load_end'),instantiate_ms=diff(events,'load_end','instantiate_end'),
                                 activate_ms=diff(events,'instantiate_end','add_child_end'),prepare_ms=diff(events,'add_child_end','mission_ready'),
                                 ready_ms=run.get('ready_ms'),printed_ready_ms=printed_ready,last_phase=last_phase,
                                 first_frame_worst_ms=run.get('first_frames_worst_ms'),
                                 entry_ms=max((r['worst_ms'] for r in measured if r['stage']=='entry'),default=None),
                                 steady_ms=max((r['worst_ms'] for r in measured if r['stage']=='steady'),default=None),
                                 checks=len(report.get('checks',[])),wall_s=run.get('wall_seconds'),peak_rss_mib=run.get('peak_rss_bytes',0)/2**20))
    with (opt.destination/'every-process.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n')
        w.writeheader()
        w.writerows(rows)
    backends=sorted({r['requested_backend'] for r in rows})
    title='Default Vulkan release stress' if backends==['release default'] else 'Experimental exported stress — '+', '.join(backends)
    lines=['# '+title,'',
           'Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.','',
           '| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |',
           '|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|']
    groups=[(g,p) for g in ['cold','warm'] for p in ['high','medium','low']]
    groups += [(g,'') for g in ['isolation-preflight','warm-seed-matrix','cycles','exit-preparing','station-entries']]
    for group,preset in groups:
        rr=[r for r in rows if r['group']==group and (not preset or r['preset']==preset)]
        vals=[r['ready_ms']/1000 for r in rr if r['completed'] and r['ready_ms'] is not None]
        timing=' / '.join(f'{v:.3f}' for v in [min(vals),statistics.median(vals),percentile(vals,.95),max(vals)]) if vals else '—'
        first=max((r['first_frame_worst_ms'] for r in rr if r['completed'] and r['first_frame_worst_ms'] is not None), default=None)
        successes=sum(r['passed'] for r in rr)
        losses=sum(r['device_loss'] for r in rr)
        started=sum(not r['skipped'] for r in rr)
        matrix=[]
        for metric in ['entry_ms','steady_ms']:
            observed=[r[metric] for r in rr if r[metric] is not None]
            matrix.append(f'{max(observed):.3f}' if observed else '—')
        complete=sum(r['completed'] for r in rr)
        lines.append(f"| {(group+' '+preset).strip()} | {len(rr)} | {started} | {complete} | {successes} | {losses} | {started-successes-losses} | {len(rr)-started} | {timing} | {first if first is not None else '—'} | {' / '.join(matrix)} |")
    lines+=['','[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)']
    (opt.destination/'STRESS.md').write_text('\n'.join(lines)+'\n')


def diff(events, begin, end):
    return events[end]-events[begin] if begin in events and end in events else None


if __name__=='__main__':
    main()
