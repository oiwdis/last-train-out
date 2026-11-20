"""Extract every paired startup attempt and original frame intervals, retaining failures."""
import argparse
import csv
import json
from pathlib import Path, PurePosixPath
import zipfile


def write_csv(path, rows):
    if rows:
        with path.open('w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator='\n')
            writer.writeheader()
            writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('out', type=Path)
    parser.add_argument('archives', type=Path, nargs='+')
    opt = parser.parse_args()
    opt.out.mkdir(parents=True, exist_ok=True)
    rows, phases, intervals = [], [], []
    for path in opt.archives:
        with zipfile.ZipFile(path) as z:
            valid = {'startup.json', 'libraries.json', 'stress.json', 'player-launches.json'}
            manifests = sorted(k for k in z.namelist() if PurePosixPath(k).name in valid)
            if not manifests:
                raise ValueError(f'{path} has no startup manifest')
            for manifest in manifests:
                parent = PurePosixPath(manifest).parent
                key = PurePosixPath(manifest).name
                summary = json.loads(z.read(manifest))
                attempts = summary if isinstance(summary, list) else summary.get('runs', summary.get('attempts', []))
                for attempt in attempts:
                    name = attempt['name']
                    if key == 'stress.json' and not name.startswith(('cold-', 'warm-')): continue
                    if 'matrix' in name: continue
                    data = {}
                    report = str(parent / (name + '.json'))
                    if report in z.namelist():
                        try:
                            data = json.loads(z.read(report))
                        except (ValueError, UnicodeDecodeError):
                            pass
                    identity = {'archive': path.name, 'attempt': name, 'manifest': manifest}
                    events = {event['phase']: event for event in data.get('events', [])}
                    for source in ('events', 'phases'):
                        for index, event in enumerate(data.get(source, [])):
                            phases.append(dict(**identity, source=source, index=index, phase=event['phase'],
                                               ticks_ms=event.get('ticks_ms'), duration_ms=event.get('duration_ms'),
                                               texture_bytes=event.get('texture_bytes'),
                                               pipeline_specializations=event.get('pipeline_specialization'),
                                               pipeline_draw=event.get('pipeline_draw')))
                    def ts(phase):
                        return events.get(phase, {}).get('ticks_ms')
                    def diff(begin, end):
                        if ts(begin) is not None and ts(end) is not None: return ts(end) - ts(begin)
                    frames = data.get('first_frames_ms', [])
                    intervals.extend(dict(**identity,frame=i + 1,ms=ms) for i, ms in enumerate(frames))
                    if key == 'stress.json':
                        passed = (attempt['returncode'] == 0 and attempt.get('complete', False)
                                  and not attempt.get('diagnostics') and not attempt.get('device_loss') and not attempt.get('timed_out'))
                    else:
                        passed = attempt.get('passed')
                    rows.append(dict(**identity, passed=passed, code=attempt.get('returncode'),
                                timed_out=attempt.get('timed_out'), skipped=attempt.get('skipped'), device_loss=attempt.get('device_loss'),
                                preset=data.get('preset', attempt.get('preset')), driver=data.get('driver'), binary=data.get('runtime_binary'),
                                first_script_ms=data.get('first_script_ms',ts('script_initialized')), to_load_ms=diff('script_initialized','load_begin'),
                                load_ms=diff('load_begin','load_end'), instantiate_ms=diff('load_end','instantiate_end'),
                                activate_ms=diff('instantiate_end','add_child_end'), prepare_ms=diff('add_child_end','mission_ready'),
                                engine_ready_ms=data.get('engine_ready_ms',ts('mission_ready')),
                                launcher_ready_ms=data.get('launcher_ready_ms', data.get('launcher_to_playable_ms', attempt.get('launcher_ready_ms'))),
                                threaded_load_ms=data.get('load',{}).get('resource_ms'),
                                worst_loading_frame_ms=data.get('load',{}).get('worst_loading_frame_ms'),
                                progress=json.dumps(data.get('load',{}).get('progress',[])), first_frame_worst_ms=max(frames, default=None),
                                peak_rss_bytes=attempt.get('peak_rss_bytes'), wall_seconds=attempt.get('wall_seconds', attempt.get('observer_wall_s')),
                                diagnostics=json.dumps(attempt.get('diagnostics',attempt.get('engine_diagnostics',[])))))
    write_csv(opt.out / 'startup-attempts.csv', rows)
    write_csv(opt.out / 'startup-phases.csv', phases)
    write_csv(opt.out / 'first-frames.csv', intervals)


if __name__ == '__main__':
    main()
