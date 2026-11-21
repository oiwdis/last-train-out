"""Rebuild the matched Metal tables and visual gallery from the CI artifact."""
import argparse
import csv
import json
import math
import statistics
import zipfile
from collections import defaultdict
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def percentile(ordered, fraction):
    return ordered[max(0, math.ceil(len(ordered) * fraction) - 1)]


def summarize(records):
    frames = sorted(value for record in records for value in record['frames_ms'])
    fps = sorted(1000 / value for value in frames)
    n = len(frames)
    summary = dict(n=n, mean_ms=statistics.mean(frames), median_ms=statistics.median(frames),
                   p95_ms=percentile(frames, .95), p99_ms=percentile(frames, .99), worst_ms=frames[-1],
                   fps_p01=percentile(fps, .01), fps_p05=percentile(fps, .05), fps_p50=statistics.median(fps),
                   fps_p95=percentile(fps, .95), over33=sum(v > 33.3 for v in frames),
                   over50=sum(v > 50 for v in frames), over100=sum(v > 100 for v in frames))
    for field in ('draw_calls', 'primitives', 'process_ms', 'physics_ms', 'render_cpu_ms', 'render_gpu_ms',
                  'texture_bytes', 'static_memory_bytes'):
        summary[field] = sum(record[field] * record['samples'] for record in records) / n
    for kind in ('draw', 'surface', 'specialization'):
        summary[kind + '_pipelines'] = sum(record['pipeline_delta'][kind] for record in records)
    return summary


def table(path, rows):
    with path.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, list(rows[0]))
        writer.writeheader()
        for row in rows:
            writer.writerow({k: round(v, 4) if isinstance(v, float) else v for k, v in row.items()})


def gallery(archive, out):
    groups = {
        'harlow': [('harlow_track', 'Harlow running line'), ('bonded_stores_exterior', 'Bonded Stores exterior'),
                   ('bonded_stores_interior', 'Bonded Stores interior')],
        'line-and-settlements': [('curved_embankment', 'Curved approach at 850 m'), ('ashford_depot', 'Ashford freight yard'),
                                 ('blackwater_crossing', 'Blackwater station'), ('crossing_stores', 'Crossing Stores')],
        'weather': [('distant_fog', 'Distant bank'), ('near_advancing_fog', 'Approaching fog'),
                    ('inside_dangerous_fog', 'Inside dangerous fog')],
        'interiors': [('warehouse_a', 'Warehouse A'), ('warehouse_b', 'Warehouse B'),
                      ('ashford_workshop', 'Ashford workshop'), ('locomotive_cab', 'Locomotive cab'),
                      ('passenger_car', 'Passenger car')]
    }
    try:
        face = ImageFont.truetype('DejaVuSans.ttf', 20)
    except OSError:
        face = ImageFont.load_default()
    for key, views in groups.items():
        sheet = Image.new('RGB', (1288, 38 + len(views) * 397), '#142022')
        draw = ImageDraw.Draw(sheet)
        for x, label in [(8, 'PR 6 integration'), (652, 'Milestone 4')]:
            draw.text((x, 7), label, fill='#eff3ef', font=face)
        for i, (slug, title) in enumerate(views):
            top = 38 + i * 397
            draw.text((8, top + 3), title, fill='#e8e8cb', font=face)
            for j, version in enumerate(('reference', 'candidate')):
                with Image.open(BytesIO(archive.read(f'{version}-images/1-{slug}.png'))) as original:
                    if original.size != (960, 540):
                        raise ValueError(f'Unexpected screenshot size {original.size}')
                    sheet.paste(original.convert('RGB').resize((640, 360), Image.Resampling.LANCZOS),
                                (4 + 644*j, top + 33))
        sheet.save(out / (key + '.jpg'), quality=88, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    out = args.output
    out.mkdir(exist_ok=True, parents=True)
    scenes, presets, startups = defaultdict(list), defaultdict(list), []
    all_runs = []
    with zipfile.ZipFile(args.artifact) as archive:
        def load(name):
            return json.loads(archive.read(name))
        manifest = load('comparison.json')
        poses = None
        for name in ('reference-first', 'candidate-first', 'candidate-repeat', 'reference-repeat'):
            version, state = name.split('-')
            data = load(name + '.json')
            attempt = next(row for row in manifest['attempts'] if row['name'] == name)
            if not attempt['passed'] or (data['renderer'], data['driver']) != ('forward_plus', 'metal'):
                raise ValueError(f'Invalid capture {name}')
            if poses is None:
                poses = data['camera_poses']
            if poses != data['camera_poses'] or len(poses) != 48:
                raise ValueError('Camera poses, fog fronts, observer positions or presets differed')
            for record in data['results']:
                if len(record['frames_ms']) != {'entry': 60, 'steady': 180}[record['stage']]:
                    raise ValueError(f'Incomplete frame sequence in {name}')
                key = (version, record['preset'], record['stage'])
                scenes[key + (record['location'],)].append(record)
                presets[key].append(record)
            all_runs.append(dict(name=name, adapter=data['adapter'], processor=data['processor'],
                                 scene_construct_ms=data['loading']['scene_construct_ms'],
                                 render_ready_ms=data['loading']['render_ready_ms'],
                                 peak_rss_mib=attempt['peak_rss_bytes']/2**20,
                                 shader_hits=attempt['shader_cache_hits'], shader_misses=attempt['shader_cache_misses'],
                                 preset_preparation=data['preset_preparation'], diagnostics=attempt['engine_diagnostics']))
        if len(scenes) != 192 or any(len(records) != 2 for records in scenes.values()):
            raise ValueError('Incomplete fixed-view matrix')
        for run in manifest['player_launches']:
            player = load(run['version'] + '-player/' + run['name'] + '.json')
            startups.append(dict(version=run['version'], preset=run['preset'], cache=run['state'], passed=run['passed'],
                                 selector_to_play_ms=run['launcher_ready_ms'], first_worst_ms=run['first_worst_ms'],
                                 loading_done_ms=player['load'].get('ready_ms'), cache_files_before=run['cache_before']['files'],
                                 cache_bytes_after=run['cache_after']['bytes']))
        for version in ('reference','candidate'):
            data = load(version+'-images.json')
            if data['camera_poses'] != poses:
                raise ValueError('Screenshot conditions differ from timings')
        gallery(archive, out)
        with zipfile.ZipFile(out/'raw-environment.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as raw:
            for member in archive.namelist():
                if not member.endswith(('/', '.png')):
                    raw.writestr(member, archive.read(member))
    rows = [dict(version=v, preset=p, stage=s, location=l, **summarize(records))
            for (v,p,s,l),records in scenes.items()]
    group_rows = [dict(version=v, preset=p, stage=s, **summarize(records)) for (v,p,s),records in presets.items()]
    table(out/'locations.csv', rows)
    table(out/'presets.csv', group_rows)
    table(out/'launches.csv', startups)
    (out/'runs.json').write_text(json.dumps({'host':manifest['host'], 'fixture':manifest['fixture_sha256'],
                                 'packs':manifest['packs'],'attempts':all_runs}, indent=2)+'\n')
    md = ['# Matched environment frame times', '',
          'Times are milliseconds. Each cell shows the PR 6 reference followed by the Milestone 4 candidate. '
          'Two runs per revision contribute 360 steady frames and 120 entry frames per view. '
          'The comparison uses all observed intervals. Percentiles use nearest rank and medians use the sample median.', '',
          '[Frame intervals, poses, logs and cache counters](raw-environment.zip) · [Location metrics and FPS distributions](locations.csv) · '
          '[Pooled results by preset](presets.csv) · [Player startup](launches.csv) · [Machine and memory](runs.json)', '']
    for p in ('Low','Medium','High'):
        md.extend([f'## {p}', '', '| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |',
                   '|---|---:|---:|---:|---:|---:|---:|'])
        for pose in poses[:16]:
            l = pose['location']
            def cell(stage, column):
                pair = [next(r[column] for r in rows if (r['version'],r['preset'],r['stage'],r['location'])==(v,p,stage,l))
                        for v in ('reference','candidate')]
                return f'{pair[0]:.1f} / {pair[1]:.1f}'
            md.append('| '+' | '.join([l]+[cell('steady',m) for m in ('median_ms','p95_ms','p99_ms','worst_ms')]+
                                       [cell('entry',m) for m in ('p99_ms','worst_ms')])+' |')
        md.append('')
    (out/'FRAME_TIMES.md').write_text('\n'.join(md)+'\n')


if __name__ == '__main__':
    main()
