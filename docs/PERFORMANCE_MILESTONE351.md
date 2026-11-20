# Milestone 3.5.1 — performance and stability investigation

PR [#6](https://github.com/oiwdis/last-train-out/pull/6) remains a draft. The reference is
`7df2f5abee54b8adcf27b8668263fba231a79033`. This is an optimization of the complete
three-station game; no assets, stations, fog rules or source tests were removed.
Physical 2020 M1 validation is pending. Hosted Apple Paravirtual measurements are
not evidence that the physical-M1 fullscreen or 15-second launch targets pass.

## What changed and why

### CPU geometry construction

Procedural boxes previously uploaded an intermediate ArrayMesh, downloaded its
vertex/attribute/index buffers for UV projection, and downloaded geometry again
through SurfaceTool when assembling details. Godot's RenderingDevice
[`mesh_get_surface`](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/renderer_rd/storage_rd/mesh_storage.cpp)
uses `buffer_get_data` for that path. This creates synchronization during scene
activation, even though the source vertices were already available on the CPU.

`CpuMeshSource` implements Mesh's CPU surface interface. Decorative box, beam,
ladder, column and cylinder assembly now keeps those arrays on the CPU and
uploads finished meshes. The imported unit box is read once per scene cache.
The caches are released at scene teardown. Native SurfaceTool still performs
transforms/indexing; this does not substitute primitive placeholders for assets.

[Geometry comparisons](validation/milestone351/investigation/linux/geometry-comparison.json)
retain exact triangle positions, UVs and winding. The maximum normal-component
change is 0.000215 from removing intermediate GPU attribute quantization.
Four representative shape fingerprints also pass on Linux and native ARM.
There is no intended visible quality reduction.

Exploratory warm scene activation fell from 6.705–7.097 seconds to
1.555–2.171 seconds; StationArt fell from 3.3–3.45 seconds to 0.218–0.372 seconds.
These observations came from different hosted runners and precede the matched
comparison. Total readiness did **not** improve clearly in that first attempt:
24.901/22.591 seconds versus 23.351/22.078. Its first launch was worse at 96.417
seconds and emitted two MoltenVK cache-write errors. The failed attempt remains
in [native geometry evidence](validation/milestone351/geometry-tests/native/README.md).

### Entry stall and queued GPU work

The original 2,506 ms entry outlier was reproduced as 1,619 and 2,773 ms on two
unsampled native runs. In the latter, 2,771.636 ms was inside the render callback
bracket, versus 1.071 ms in process callbacks and no physics callback in that
frame. Draw/surface/specialization counters did not advance. A separate native
sampling run showed `RenderingDevice::_begin_frame → _stall_for_frame →
RenderingDeviceDriverVulkan::fence_wait → vkWaitForFences` on the main thread.
Its short entry stack sample contains only 89 samples; it is not a complete
trace of every millisecond of the stall. GPU timestamps are unavailable on this
host, so the exact internal GPU workload cannot be identified from these data.

The preparation code previously changed views after one or two submitted draws
and restored gameplay after one final draw. `frame_post_draw` means submitted,
not completed. Preparation now renders through the device's reported frame-queue
rotation for each authored view and fog material, then drains the original
camera before unpausing. It uses the existing explicit preparation period;
no loading screen is triggered by entering a station, warehouse or dangerous
fog during play. Fog simulation remains paused during preparation, as before.
The existing overlay now shows progress through the views.

A short native probe after this change reached 86.753 ms for High Harlow entry,
but Medium Harlow still reached 334.389 ms, Medium near-fog 179.644 ms, and High
Warehouse A 149.937 ms. That probe has only 24 samples per stage and is not the
final matched pacing comparison. All results are in
[queue preparation evidence](validation/milestone351/queue-preparation/README.md).
The 100 ms target must be assessed across all locations, not just Harlow High.

[Three additional native processes](validation/milestone351/repeated-native/README.md)
completed all presets/locations and shutdowns without device loss, ObjectDB or
resource-in-use warnings. High Harlow entry worst times were 93.952 / 81.133 /
120.907 ms; the worst entry anywhere was 347.615 ms in the first Medium cab case.
All outliers remain retained. These are short stress windows, not a replacement
for the long paired cohort. The first Harlow fixture follows mission completion
and a preset change, including repositioning the train back to Harlow; it is a
scene/preset transition stress case, not an ordinary uninterrupted walk.

### Fog and redundant HUD uploads

The historical High near-fog steady outlier of 937.364 ms did not reproduce in
the two unsampled baseline runs: worst frames were 52.559 and 84.014 ms.
This does not prove it is fixed. The separately sampled fog run reached 221.387
ms and is excluded from FPS comparisons because profiling adds overhead; its
raw data remain retained. Its main thread frequently waited on GPU fences.

The same stack trace exposed another concrete avoidable path:
`ProgressBar → StyleBoxFlat::draw → request_polygon → vertex_buffer_create →
_buffer_initialize → _wait_for_transfer_worker → fence_wait`. The HUD assigned
the same stamina fill color every frame. StyleBoxFlat emits `changed` even for
an identical color, forcing unchanged polygons to be rebuilt and uploaded.
The HUD now updates that style only when exhaustion changes, and stops
imperceptible subpixel interpolation once the bar reaches its target. A
regression verifies zero idle style invalidations and immediate exhaustion/
recovery color transitions. This removes unnecessary work; it is not evidence
that every fog outlier had that cause.

All four danger states, health/exposure, shelter, seeded events and 2/4/6 fog
layers for Low/Medium/High remain unchanged. Tests verify material and shader
identity across all danger/preset combinations; no new material is created
when danger becomes critical. The fog already used six transparent sheets and
ordinary distance fog rather than a new volumetric pass.

### MoltenVK cache errors versus fatal device loss

The original fatal incident is preserved in
[run 46 ARM logs](validation/milestone35/native-final/arm64/packaged-benchmark-presets.log):
Metal command-buffer timeouts, `VK_TIMEOUT`, failed fence wait, device loss and
SIGTRAP during High preparation. The identical ZIP later passed on another
runner. Neither the retry nor subsequent successful stress runs establishes
that the fatal issue is fixed.

This investigation reproduced a different failure: `VK_INCOMPLETE` while
MoltenVK serialized its pipeline cache during ongoing preparation. Godot's
3 MiB save threshold repeatedly requested cache serialization while background
pipeline creation could grow the cache between the size query and write.
Godot tolerates `VK_INCOMPLETE`, but MoltenVK still emits validation errors.
An error-free warm run still had the 2.77-second entry stall, so cache writing
cannot explain all entry stalls.

The save threshold is now 128 MiB, beyond the measured 10–20 MiB working set.
Godot still writes on clean shutdown. The queue-aware startup probe wrote a
10.4 MiB PSO cache on its first clean exit; both warm launches loaded that same
size without rewriting it. The rendered stress process cleanly wrote 16.0 MiB.
The tradeoff is loss of the latest PSO additions if the process is killed before
shutdown, which can increase the next preparation cost. The shader-code cache
is separate. No driver errors are suppressed.

Resource allocation pressure and driver behavior remain possible contributors
to the fatal timeout. Process RSS and texture monitors are retained, but are
not complete GPU allocation telemetry. No GPU use-after-free or unbounded
allocation has been demonstrated. A physical GPU capture and repeated native
stress are still needed before closing that incident.

### Scene lifetime and shutdown

A new cancellation regression reproduced an actual ObjectDB leak: removing
GraphicsSettings while it awaited a static RenderWarmup coroutine left a
GDScriptFunctionState suspended. Verbose logs identify `prepare` and `completed`.
Preparation is now a scene-owned Node job with explicit signal disconnection,
pause restoration, temporary camera/overlay cleanup and completion on teardown.
The same regression then passed without ObjectDB/resource-in-use diagnostics.

The rider/cargo restoration ordering is preserved: Continue waits for rendering
preparation, applies train transforms, waits for physics synchronization and
only then resolves occupants. The new test restores a rider and loose cargo
together while preset preparation is active. Rapid preset changes coalesce to
the last requested quality, and removing a preparing scene releases its owner.

The test wrapper, exported self-test, packaged benchmarks and recording now
reject engine errors and retained-resource warnings even if the process exits
zero. Raw logs remain available. A successful report alone is insufficient.
The cancellation leak is a proven fix; the old packaged diagnostic warnings
are not automatically attributed to it without fresh exported checks. The native
verbose stress log still prints `Orphan StringName: servers` (one string name);
Godot 4.5.1 source identifies it as AudioServer's debug profiler label. It
remains retained rather than described as perfectly clean shutdown. No ObjectDB or resource-in-use warning accompanies it.

### Audio mixer retirement race reproduced after clean runs

The next release attempt, `31a0e4a` / run 44579035899, passed 299 native tests
but failed its third startup shutdown. Three AudioStreamWAV/AudioStreamPlaybackWAV
pairs remained alive. Earlier clean repetitions had not ruled out this race.
The complete failed attempt is retained in
[audio-retirement evidence](validation/milestone351/audio-retirement/README.md).

A small Linux fixture using the same three fog loops reproduced all three
live playback owners after `stop()`, clearing streams, scene removal and two
process frames. In Godot 4.5.1, `AudioServer::stop_playback_stream` requests
`FADE_OUT_TO_DELETION`; the mixer processes that request, and a later main-thread
`AudioServer::update` cleans the playback list. Fast render frames can outrun
that audio cycle. The WAV resources are held by the playbacks, rather than by
unfreed game nodes.

Diagnostics now retain weak references to the real playbacks, stop their
players at the end of measurement, and wait until the mixer has relinquished
ownership before freeing the scene and quitting. A two-second deadline emits
an error if retirement fails. This is bounded diagnostic teardown, after the
measured frames; it does not add gameplay stalls or mute gameplay audio. The
same protocol is used by startup probes, both benchmark drivers, exported
self-tests and the journey recording. The paired baseline receives the same
post-measurement cleanup helper, so its teardown policy is matched too.

A new six-cycle test alternates paused and unpaused retirement and asserts that
both playback objects and the scene are gone before completion. It passes on
Linux without the reproduced WAV/ObjectDB leak. Three fresh native startups then completed without the reproduced leaks, but
exported workflow validation remains required. Those startup totals were worse
at 107.173 / 29.977 / 25.575 seconds on a different hosted runner; all are retained.
The cleanup fix is not claimed as a startup speed improvement.

## Measurement limits and remaining work

The new source-project startup probe and the historical 78.60-second exported
self-test are different entry paths. Source loading, exported shader baking and
self-test fixture overhead differ; their totals are not a matched before/after
claim. Exported app launch logs are retained separately.

The matched cohort runs all twelve locations on all three presets twice per
revision on one hosted ARM runner. Order alternates between repetitions.
Startup has three processes per revision. Separate project/user caches are
fresh initially; filesystem caches are warm and OS/driver caches are shared and
uncontrolled. Both revisions use identical diagnostic scripts. Entry samples,
steady samples, preset preparation and fixture transitions are separate.

FrameTimeline brackets callbacks; it is not a GPU timer. Godot's process/physics
monitors can carry older snapshots and must not be added to render timing or
subtracted from wall time to invent GPU cost. GPU timing is zero/unavailable.
The harness retains raw frame/timeline dictionaries, so some static-memory
growth across locations belongs to instrumentation rather than gameplay. Both
revisions run the same harness; process RSS is not total unified/GPU memory.
Material-switch counts and individual GPU shadow-pass times are not exposed by
these tools; draw calls, primitive counts, texture/static memory and process RSS
are retained instead. Static render fixtures freeze most gameplay simulation;
the full continuous journey validates active gameplay separately.

The baseline High interiors submit approximately 653 draws/1.01 million
primitives at Warehouse B, 1,017/1.69 million in the cab and 1,176/1.76 million
in the passenger car. Render submission CPU was about 1.3–1.8 ms; GPU fence
waits dominate the sampled outlier path. Those counts include shadow work.
The optimization preserves detailed meshes, normals, roughness, shadow settings,
LODs and preset resolution differences. HUD uploads and construction are reduced;
steady interior improvement must be judged from the paired distributions.

The latest exploratory startup totals were 73.558 / 21.602 / 19.805 seconds.
The first 23.630 seconds elapsed before the startup script initialized, and
another 9.788 seconds loaded the mission resources. Engine/driver startup and
built-in shader preparation cannot be split further by these script timestamps.
Scene activation was 1.826 / 1.687 / 1.342 seconds. Cold startup remains outside
target and the initial synchronous load is not yet fully responsive. The
post-load preparation overlay is visible and progresses; it does not establish
that the entire cold-launch window responds without interruption.

[Physical M1 instructions](M1_MILESTONE351.md) cover the owner's fullscreen
2020 M1, windowed mode, both perspectives, all presets, interior/fog entry,
cold/warm launches, save/resume and complete travel. That gate remains pending.


## Completed matched cohort

The final [same-host comparison](validation/milestone351/final-native/comparison/COMPARISON.md) and [complete release evidence](validation/milestone351/final-native/README.md) are now published. They supersede the pending status above while retaining the chronology of exploratory attempts.

| Measure | Exact 7df2f5a baseline | cc50670 candidate |
|---|---:|---:|
| First source-project ready state, fresh app caches | 42.104 s | 25.999 s |
| Warm ready states | 29.651 / 31.441 s | 18.579 / 19.052 s |
| Medium Harlow worst entry | 1,866.183 ms | 65.718 ms |
| High Harlow worst entry | 2,393.057 ms | 89.192 ms |
| High Warehouse A worst entry | 143.454 ms | 168.372 ms |
| High Warehouse B steady p99 | 34.907 ms | 63.724 ms |
| High cab steady p99 | 35.804 ms | 26.649 ms |
| High passenger steady p99 | 29.956 ms | 28.943 ms |
| High near-fog worst steady frame | 108.670 ms | 80.467 ms |

The large Harlow stall is substantially reduced. The all-entry 100 ms target is not met, and some steady cases regress despite the cab/fog improvements. Candidate peak sampled RSS was 632.03 MiB versus baseline 618.80 MiB. All per-attempt raw data remain available. The historical 937 ms fog outlier did not reproduce in this baseline cohort, so its elimination is not established. Startup is improved in this matched cohort; earlier fresh-runner startup totals up to 107.173 seconds remain retained and are not erased by the more favorable comparison.
