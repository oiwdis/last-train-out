"""Trace engine startup intervals on an isolated native macOS player."""
import argparse
from collections import defaultdict
from datetime import datetime
import json
from pathlib import Path
import subprocess
import sys

MACOS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MACOS))
from metal_trace import metal_signposts


def summarize(events):
    starts = {}
    spans = defaultdict(list)
    unmatched = []
    for row in sorted(events, key=lambda item: item['machTimestamp']):
        key = row['processID'], row['signpostID']
        stamp = datetime.fromisoformat(row['timestamp']).timestamp()
        if row.get('signpostType') == 'begin':
            if key in starts:
                unmatched.append(key)
            starts[key] = (row['eventMessage'].removeprefix('stage='), stamp)
        elif row.get('signpostType') == 'end':
            if key not in starts:
                unmatched.append(key)
                continue
            name, begin = starts.pop(key)
            spans[row['processID'], name].append((begin, stamp))
    summary = []
    for (pid, name), samples in sorted(spans.items()):
        end = 0
        union = 0.0
        for begin, finish in sorted(samples):
            union += max(0.0, finish - max(begin, end))
            end = max(end, finish)
        times = [finish - begin for begin, finish in samples]
        summary.append(dict(pid=pid, stage=name, count=len(samples), worker_s=sum(times), union_s=union, max_s=max(times)))
    return summary, unmatched + list(starts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('out', type=Path)
    opt = parser.parse_args()
    out = opt.out.resolve()
    out.mkdir(parents=True)
    with metal_signposts(out):
        code = subprocess.run([sys.executable, MACOS / 'measure_fresh_player.py', opt.app.resolve(), out / 'player',
                               '--without-signposts']).returncode
    rows = [json.loads(s) for s in (out / 'signposts.ndjson').read_bytes().splitlines() if s.startswith(b'{')]
    filtered = [r for r in rows if r.get('signpostName') == 'startup_stage']
    summary, unpaired = summarize(filtered)
    by_process = defaultdict(set)
    for r in summary:
        by_process[r['pid']].add(r['stage'])
    required = {'main_setup','main_start','main_setup2','physics_servers','metal_default_device','metal_context',
                'metal_device_driver','shader_cache_read','metal_texture_allocate','compressed_texture_load',
                'texture_staging','metal_upload_commands','material_update_shader'}
    missing = {str(pid):sorted(required - stages) for pid, stages in by_process.items()}
    (out / 'stage-timings.json').write_text(json.dumps({'player_code': code, 'missing':missing, 'unpaired':unpaired,
                                                       'spans': summary}, indent=2))
    return int(code != 0 or len(by_process) != 2 or bool(unpaired) or any(missing.values()))


if __name__ == '__main__':
    raise SystemExit(main())
