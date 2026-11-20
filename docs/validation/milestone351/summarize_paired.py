import json,math,csv,pathlib,sys,statistics
source=pathlib.Path(sys.argv[1]);out=pathlib.Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
metadata=json.loads((source/'comparison.json').read_text())
location_order=['Harlow platform','Warehouse A','Warehouse B','Locomotive cab','Passenger car','Curved railway','Ashford Depot','Ashford workshop','Blackwater Crossing','Near advancing fog','Inside dangerous fog','Mission completion']
presets=['Low','Medium','High'];groups={};individual=[];worst_frames=[];preparation=[]
for record in metadata['runs']:
 if '-matrix-' not in record['name']:continue
 path=source/(record['name']+'.json')
 if not path.exists():continue
 data=json.loads(path.read_text())
 preparation.append((record['name'],data['loading'],data['preset_preparation']))
 for row in data['results']:
  version=record['name'].split('-')[0];key=(version,row['preset'],row['location'],row['stage'])
  groups.setdefault(key,[]).append(row)
  individual.append(dict(run=record['name'],**{k:v for k,v in row.items() if not isinstance(v,(list,dict))}))
  index=max(range(len(row['frames_ms'])),key=row['frames_ms'].__getitem__)
  timeline=row['timeline'][index]
  worst_frames.append(dict(run=record['name'],preset=row['preset'],location=row['location'],stage=row['stage'],sample_index=index,frame_ms=row['frames_ms'][index],process_bracket_ms=timeline.get('process_bracket_ms',0),physics_bracket_ms=timeline.get('physics_bracket_ms',0),render_bracket_ms=timeline.get('render_bracket_ms',0),pipeline_delta=json.dumps(row['pipeline_delta'],sort_keys=True)))
aggregated={}
for key,rows in groups.items():
 values=sorted(v for row in rows for v in row['frames_ms']);count=len(values)
 percentile=lambda p:values[max(0,math.ceil(count*p)-1)]
 d=dict(zip(['revision','preset','location','stage'],key),samples=count,mean_ms=statistics.mean(values),median_ms=percentile(.5),p95_ms=percentile(.95),p99_ms=percentile(.99),worst_ms=max(values),over_33_3=sum(v>33.3 for v in values),over_50=sum(v>50 for v in values),over_100=sum(v>100 for v in values))
 for metric in ['draw_calls','primitives','process_ms','physics_ms','render_cpu_ms','render_gpu_ms','texture_bytes','static_memory_bytes']:
  d[metric]=sum(r[metric]*len(r['frames_ms']) for r in rows)/count
 aggregated[key]=d
for filename,rows in [('all-attempts.csv',individual),('pooled-distributions.csv',list(aggregated.values())),('worst-frames.csv',worst_frames)]:
 with (out/filename).open('w') as f:
  writer=csv.DictWriter(f,fieldnames=list(rows[0]) if rows else [],lineterminator="\n");writer.writeheader();writer.writerows(rows)
lines=['# Matched hosted comparison','',f"Baseline `{metadata['baseline']}`; candidate `{metadata['optimized']}`.",'','Godot 4.5.1, 960×540 windowed, Vulkan, V-sync/frame cap off. Two sequential matrices per revision, alternating order. 60 entry frames and 600 steady frames per view per run, with 120 settling frames. Separate fresh application caches, warm filesystem, shared OS/driver cache state uncontrolled. No profiler, screenshots or Movie Maker. All samples, including failures and outliers, are retained. Pooled percentiles are recomputed from raw frames, never averaged from per-run percentiles. GPU timing zero means unavailable.','']
for preset in presets:
 lines.extend([f'## {preset} — steady rendering','','Values are baseline → candidate milliseconds. Counts pool both attempts.','','| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |','|---|---:|---:|---:|---:|---:|---|'])
 for loc in location_order:
  a=aggregated.get(('baseline',preset,loc,'steady'));b=aggregated.get(('optimized',preset,loc,'steady'))
  if not a or not b:lines.append(f'| {loc} | INCOMPLETE | | | | | |');continue
  metrics=' | '.join(f'{a[m]:.2f} → {b[m]:.2f}' for m in ['mean_ms','median_ms','p95_ms','p99_ms','worst_ms'])
  counts=' → '.join('/'.join(str(r[m]) for m in ['over_33_3','over_50','over_100']) for r in [a,b])
  lines.append(f'| {loc} | {metrics} | {counts} |')
 lines.extend(['',f'## {preset} — entry and view preparation','','| Location | Worst entry, ms | Entry >100 ms |','|---|---:|---:|'])
 for loc in location_order:
  a=aggregated.get(('baseline',preset,loc,'entry'));b=aggregated.get(('optimized',preset,loc,'entry'))
  if a and b:lines.append(f"| {loc} | {a['worst_ms']:.2f} → {b['worst_ms']:.2f} | {a['over_100']} → {b['over_100']} |")
 lines.append('')
lines.extend(['## Every startup attempt','','Times are seconds since engine process initialization. The first boundary combines OS/engine/driver startup and built-in shader preparation; the load boundary includes script/resources/decompression; activation includes `_ready`, geometry, physics registration and gameplay wiring. These aggregates cannot isolate every internal engine stage. Readiness follows destination-GPU preparation and physics synchronization.','','| Revision / attempt | Engine to script | Script to load | Load | Instantiate | Activate | Render preparation + readiness | Total ready |','|---|---:|---:|---:|---:|---:|---:|---:|'])
for rec in metadata['runs']:
 if '-startup-' not in rec['name']:continue
 path=source/(rec['name']+'.json')
 if not path.exists():lines.append(f"| {rec['name']} | INCOMPLETE | | | | | | |");continue
 d=json.loads(path.read_text());e={v['phase']:v['ticks_ms']/1000 for v in d['events']}
 vals=[e['script_initialized'],e['load_begin']-e['script_initialized'],e['load_end']-e['load_begin'],e['instantiate_end']-e['load_end'],e['add_child_end']-e['instantiate_end'],e['mission_ready']-e['add_child_end'],e['mission_ready']]
 lines.append('| '+rec['name']+' | '+' | '.join(f'{v:.3f}' for v in vals)+' |')
lines.extend(['','## Process memory and failures','','RSS is sampled every 0.5 seconds; it is not total GPU memory and can miss short peaks. Texture/static-memory monitors and per-location CPU timings are in the CSV. Retained frame/timeline arrays contribute to static-memory growth; identical instrumentation is used for both revisions.','','| Process | Seconds to exit | Peak RSS MiB | Exit | Diagnostics |','|---|---:|---:|---:|---:|'])
for r in metadata['runs']:
 lines.append(f"| {r['name']} | {r['wall_seconds']:.2f} | {r['peak_rss_bytes']/1048576:.2f} | {r['returncode']} | {len(r['engine_diagnostics'])} |")
lines.extend(['','The raw process logs retain every diagnostic and cache event. A complete JSON or zero exit does not override engine errors. Loading/preset preparation and fixture-transition times remain in the raw reports, separately from entry and steady samples. Fixtures deliberately reposition the player and freeze most simulation; the uninterrupted controls-driven recording is separate evidence.',''])
lines.extend(['## Worst-frame callback evidence','','Twenty largest per-view worst frames from all attempts. Callback brackets are CPU elapsed intervals, including waits; they are not GPU timestamps. Full per-view records are in `worst-frames.csv`.','','| Run | Preset / location / stage | Frame ms | Process ms | Physics ms | Render bracket ms |','|---|---|---:|---:|---:|---:|'])
for r in sorted(worst_frames,key=lambda r:r['frame_ms'],reverse=True)[:20]:
 lines.append(f"| {r['run']} | {r['preset']} / {r['location']} / {r['stage']} | {r['frame_ms']:.3f} | {r['process_bracket_ms']:.3f} | {r['physics_bracket_ms']:.3f} | {r['render_bracket_ms']:.3f} |")
lines.extend(['','## Matrix preparation, separate from gameplay samples','','Each process constructs the scene and prepares its initial Low view before measurement. Later preset changes prepare the existing scene. All time remains reported here; moving work into preparation does not make startup free.','','| Run | Scene construction ms | Initial render-ready ms from construction start | Low / Medium / High preset preparation ms |','|---|---:|---:|---|'])
for name,loading,presets_data in preparation:
 lines.append(f"| {name} | {loading['scene_construct_ms']} | {loading['render_ready_ms']} | "+' / '.join(str(r['milliseconds']) for r in presets_data)+' |')
lines.extend(['','## Shader-cache diagnostics','','The process logs preserve every PSO load/save event. Shader-code hit/miss messages are engine diagnostics, not a count of every pipeline or texture upload.','','| Process | Shader hits | Shader misses | PSO events |','|---|---:|---:|---|'])
for r in metadata['runs']:
 events='; '.join(r.get('pipeline_cache_events',[])).replace('|','/')
 lines.append(f"| {r['name']} | {r.get('shader_cache_hits',0)} | {r.get('shader_cache_misses',0)} | {events} |")
lines.append('')
(out/'COMPARISON.md').write_text('\n'.join(lines))
print('Wrote',out,'rows',len(aggregated))
