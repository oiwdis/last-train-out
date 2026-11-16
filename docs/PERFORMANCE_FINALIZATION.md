# Milestone 2.6 finalization performance

This compares original M2.5 (`8cde10cf78c1ea0cf7f7bafb5fc146d2e12514c2`),
previous M2.6 (`dfbfdf8ccf3e466788cc085ae5563a14e6382670`) and finalization.
The physical 2020 M1 fullscreen target is **unverified**. Use the reproducible
[physical-M1 procedure](M1_BENCHMARK.md); neither software rendering nor a hosted
Mac's virtual GPU establishes that target.

## Method

All revisions use Godot 4.5.1, Forward+, the same camera coordinates/FOV,
960×540 output, VSync disabled and real elapsed frame intervals. No fixed FPS,
Movie Maker, tests, imports or competing render jobs run during measurements.
Low/Medium/High preserve their real revision-specific material/effect budgets.
The High ablation series disables volumetrics to match the hosted virtual GPU's
capability. It selectively removes one feature at a time, restores High between
cases, and repeats High at the end. No diagnostic omission is saved as a preset.

The preset suite samples platform and Warehouse B. The route suite runs after the same startup/preset preparation used in play,
then warms on the platform and pans through the warehouse entrance, retaining
the worst frame. The final runtime prepares scene-authored warehouse/freight
views behind a loading panel, pausing/restoring play or a new preset; baseline revisions do not have that feature.
Preparation elapsed time is logged explicitly and its preparation frames are not
counted as measured route frames. This compares the actual post-load experience,
not a claim that first-use compilation has no cost. Baseline source trees keep their original
artwork. Broken historical import metadata is repaired only when source image
bytes are identical, and cached scene dependencies are rebuilt. This benchmark
uses each revision's actual lighting; unlike the controlled still gallery, it
does not replace M2.5's original night sky with the final HDR fixture.

Frame interval is end-to-end pacing. Godot's render-CPU monitor is submission
work, not total CPU time. Process/physics monitors are periodically refreshed
snapshots, so early samples can retain loading work; they are not summed or used
to infer an isolated CPU bottleneck.
Both tested drivers on the hosted virtual GPU report render-GPU time as zero, which means
unavailable, not zero cost. Texture memory is the engine monitor, not total app
resident memory. Rendered primitive counts include additional passes; they are
not unique source triangle counts. Pipeline counters are cumulative and help
locate initial compilation, rather than indicating steady-state material swaps.

## Changes and bottlenecks

Flat floors, walls and bevelled box parts now receive metre-scaled per-face UVs
and generated tangents once, then share cached PBR materials. This replaces three
triplanar map fetches per pixel with ordinary UV sampling while preserving scanned
colour, normal and roughness maps. Inverse-transpose normals also fix distortion
on nonuniformly scaled geometry. Shared meshes/materials, existing MultiMeshes,
imported LODs, compressed textures and simple collision shapes remain.

No new real-time reflection effect, shadow light, collider or fog simulation is
added. Skin scattering is disabled in shipped presets; its separate-specular
rendering path is investigated independently. High retains native pixels,
2× MSAA, SSAO and authored shadows. Low keeps colour maps with 65% rendering and
a 720p height budget; Medium retains normal/roughness maps with an 85% scale and
1080p budget. Small-detail visibility remains a presentation budget.

The new character, damaged structure and mechanism add geometry, so draw-call or
triangle count alone cannot establish an optimization. Disabling animation also
allows shadow-map reuse; that ablation measures the combined rendering effect,
not isolated GDScript animation time. Transparency and overdraw are constrained
with alpha-scissor hair/vegetation, sparse soft particles and existing visibility
ranges. No overdraw heatmap or direct material-switch counter was available, so
those are structural observations, not invented measurements.

## Final hosted Mac comparison (run 34)

[Run 34](https://github.com/oiwdis/last-train-out/actions/runs/43797534032) completes all eight benchmark processes. macOS 26.7.2, Vulkan 1.2.283.

Source `c86d6f31ffaef820e72994cc031a317634bd8c57`; Apple M1 (Virtual), Apple Paravirtual device, 3 reported CPUs. Godot 4.5.1-stable (official), Forward+ Vulkan; 960×540 windowed, 600 sampled frames and 120 warmup frames.

The historical builds use their original Metal driver and 0.3 worker ratio; the final build uses Vulkan and 0.9. This compares complete builds, not the isolated effect of an individual optimization. Export and packaged launch run first, so source measurements are cache-conditioned and are **not cold-launch measurements**. Movie Maker runs afterwards.

| View / preset | M2.5 median ms | Previous M2.6 median ms | Final median ms | Final p95 ms | Final worst ms |
|---|---:|---:|---:|---:|---:|
| Platform / Low | 3.676 | 4.535 | 6.562 | 7.477 | 8.868 |
| Platform / Medium | 4.262 | 5.880 | 10.184 | 11.536 | 15.423 |
| Platform / High | 6.045 | 7.723 | 11.943 | 14.728 | 25.380 |
| Warehouse B / Low | 3.804 | 4.186 | 7.477 | 8.805 | 17.330 |
| Warehouse B / Medium | 5.018 | 5.759 | 8.943 | 10.416 | 12.129 |
| Warehouse B / High | 7.246 | 11.090 | 13.066 | 14.673 | 16.988 |

Warehouse B steady-state median intervals are **78.6% / 55.3% / 17.8% longer**
than previous M2.6 on Low/Medium/High. This is a regression in this complete-build
comparison, not an overall native speedup. Vulkan resolves the tested export
portability/startup failure, at a measurable steady-state cost on this virtual GPU.
The High p95 is 14.67 ms at this small window size; that cannot establish physical
M1 fullscreen performance.

| Entry pan | M2.5 worst ms | Previous M2.6 worst ms | Final worst ms | Final median / p95 ms |
|---|---:|---:|---:|---:|
| Low | 46.256 | 369.521 | 13.389 | 7.224 / 8.668 |
| Medium | 15.226 | 396.093 | 13.458 | 8.862 / 10.285 |
| High | 54.874 | 522.355 | 13.784 | 11.499 / 12.449 |

All five pipeline counters stay unchanged during each final entry pan. Initial
route preparation takes 10.82 seconds; Low/Medium/High preparation takes
5.39 / 3.89 / 6.87 seconds, excluded from the sampled frames. The earlier source
preset process initially prepares in 8.44 seconds. **Loading is not free**;
these cache-conditioned source figures are separate from packaged launch timing.

| Warehouse B ablation | Previous median ms | Final median ms | Final p95 ms |
|---|---:|---:|---:|
| High | 12.362 | 12.699 | 14.239 |
| No local shadows | 9.846 | 11.066 | 12.123 |
| No directional shadows | 13.297 | 10.739 | 12.247 |
| No shadows | 11.488 | 9.316 | 10.097 |
| No local lights | 13.894 | 10.200 | 11.369 |
| No SSAO | 15.740 | 11.432 | 13.385 |
| No MSAA | 14.950 | 11.078 | 12.558 |
| No normal or roughness maps | 12.851 | 12.167 | 13.766 |
| LOD 2.5 | 11.141 | 13.380 | 16.583 |
| 65% pixels | 12.129 | 10.270 | 12.384 |
| No animation | 8.804 | 10.988 | 11.872 |
| High repeat | 11.947 | 12.173 | 14.014 |

Shadows and local lighting remain substantial costs: removing all shadows lowers
the final ablation median from 12.70 to 9.32 ms; removing local lights gives
10.20 ms. Reducing pixel count gives 10.27 ms, while removing normal/roughness
maps gives 12.17 ms. Increasing the LOD threshold does not improve this cohort.
This supports prioritizing lighting/pixel budgets over indiscriminate geometry
reduction on this host. High retains its visual effects; Low and Medium provide
the cheaper budgets. Animation omission also permits shadow-map reuse, so it
cannot isolate skeleton CPU time. The historical ablation order is noisy (some
omissions are slower than High); small differences are not reliable rankings.

In the preset High view, draws are 634 → 637, rendered primitives 896,957 →
1,024,189, texture memory 344.66 → 359.88 MiB and render submission CPU time
1.159 → 0.817 ms. The final Vulkan texture allocation is larger than the earlier
Metal candidate's; no native texture-memory saving is claimed across drivers.
GPU time is unavailable (zero) under both native drivers.
[Raw reports and 196 native test results](validation/milestone26/finalization/native-ci34/).

## Packaged delivery and remaining acceptance

The universal ZIP from run 34 is 291,281,129 bytes, SHA-256
`b5b00a441bbf8b59dc4acef826a68eda83773aac21382acc8cc2669bec182e15`.
[Candidate download](https://github.com/oiwdis/last-train-out/actions/runs/43797534032/artifacts/14196136884)
requires GitHub sign-in and expires after 30 days. It is ad-hoc signed, not notarized.
The latest exact-head build is linked from PR #4.

Both build-time launch modes pass (31 headless / 34 graphical checks). The
build-runner graphical check completes at 103.8 seconds from process start;
player-ready is 59.4 seconds, with initial view preparation of 22.5 seconds.
Low/Medium/High preparation in that check costs 13.44 / 3.99 / 10.01 seconds.
The unchanged watchdog is not bypassed. Initial application loading is still
substantial and must be measured on the physical target.

Fresh-download Intel headless gameplay and Apple Silicon headless/windowed
gameplay pass. In the first Apple Silicon attempt, the packaged presets
benchmark completes all six cases, but the following route process reports
`VK_TIMEOUT`, loses the Vulkan device and exits with SIGTRAP during initial
render preparation. No route samples are produced. This is an actual failed
process, distinct from tolerated `VK_INCOMPLETE` cache-write messages; it is
retained in [the first-attempt delivery report](validation/milestone26/finalization/native-ci34/delivery-status-attempt1.json).
A [fresh-runner repetition of the same ZIP](validation/milestone26/finalization/native-ci34/delivery-status-attempt2.json)
passes both launch modes and all six preset/three route cases. The device loss
does not reproduce in that attempt; its cause remains unproven. Both attempts
are retained, and the latest exact-head validation is linked from PR #4.

The exporter also logs Godot's off-tree `get_global_transform` diagnostics while
baking scene resources. The resulting pack, displayed labels and runtime checks
are verified separately; these logs are not described as error-free.

**Do not call the M1 performance target achieved.** The hosted steady-state
regression, substantial startup cost and one packaged device-loss failure are
reasons to require the documented physical fullscreen check before accepting
performance for merge. Further tuning should use that machine's results, not
remove effects on the strength of a virtual-GPU median alone.

<details>
<summary>Earlier Metal comparison and failed launch investigations (runs 24–33)</summary>

## Earlier native comparison (run 32)

[Run 32](https://github.com/oiwdis/last-train-out/actions/runs/43792163402) measures
`dbfbdac40564af869e64cad0bccf49c7afa2146e`. All eight benchmark processes
completed successfully. Apple M1 (Virtual), Apple Paravirtual device (Apple5),
three reported CPUs, macOS 26.7.2, Metal 3.2; 960×540 windowed, 600 samples and
120 warmup frames. The final worker ratio is 0.9; both historical projects retain
their actual 0.3 default. These are complete-build comparisons, not an isolated
measurement of one code change.

| View / preset | M2.5 median ms | Previous M2.6 median ms | Final median ms | Final p95 ms | Final worst ms |
|---|---:|---:|---:|---:|---:|
| Platform / Low | 4.502 | 5.531 | 5.689 | 7.821 | 11.188 |
| Platform / Medium | 5.240 | 7.887 | 7.731 | 10.558 | 13.286 |
| Platform / High | 7.031 | 9.778 | 9.499 | 13.884 | 21.896 |
| Warehouse B / Low | 4.928 | 6.025 | 6.272 | 11.559 | 28.730 |
| Warehouse B / Medium | 5.882 | 7.248 | 7.970 | 11.696 | 16.317 |
| Warehouse B / High | 8.120 | 11.309 | 12.214 | 15.648 | 24.135 |

Warehouse B steady-state medians are **4.1% / 10.0% / 8.0% slower** than previous
M2.6 in this cohort. The final High p95 is 15.65 ms at this small window size.
There is no consistent native steady-state speedup across runs 24, 29 and 32;
the additional artwork has a measurable cost. The source software comparison
below supports the material optimization, but does not override this native result.

| Entry pan | M2.5 worst ms | Previous M2.6 worst ms | Final worst ms | Final median / p95 ms | Preset preparation ms |
|---|---:|---:|---:|---:|---:|
| Low | 74.477 | 405.927 | 31.470 | 6.414 / 9.142 | 5803 |
| Medium | 22.691 | 350.651 | 15.005 | 7.777 / 10.299 | 5567 |
| High | 72.872 | 534.938 | 27.392 | 8.334 / 12.132 | 8435 |

The severe first-entry compilation spikes are substantially reduced **after
preparation**. All five pipeline counters remain unchanged during each final
pan. The later route process reuses compilation caches and initially prepares
in 10.98 s. In the cold source process, scene-ready arrives at 77.0 s from process
start; initial preparation takes 29.14 s and the first Low change takes 25.99 s.
The subsequent Medium/High changes take 5.60/7.91 s. Loading is not free, and
these source timings are separate from the exported-app launch gate below.

| Warehouse B ablation | Previous median ms | Final median ms | Final p95 ms |
|---|---:|---:|---:|
| High | 11.542 | 12.280 | 15.033 |
| No local shadows | 8.674 | 9.845 | 12.026 |
| No directional shadows | 11.318 | 9.886 | 14.338 |
| No shadows | 7.466 | 8.877 | 12.631 |
| No local lights | 9.011 | 8.998 | 11.661 |
| No SSAO | 10.392 | 11.393 | 16.753 |
| No MSAA | 10.517 | 10.751 | 15.296 |
| No normal or roughness maps | 11.000 | 11.049 | 15.026 |
| LOD 2.5 | 10.813 | 11.758 | 15.230 |
| 65% pixels | 10.608 | 10.855 | 14.221 |
| No animation | 10.005 | 8.387 | 12.394 |
| High repeat | 13.371 | 13.090 | 17.863 |

The repeated High result is 13.09 versus 13.37 ms, illustrating cohort/order
variation. Shadows and local lighting have larger effects here than removing
normal/roughness maps or SSAO. The animation omission also enables shadow reuse;
it does not establish that skeleton scripts consume 32% of CPU time.

In the preset High sample, draws are 634 → 637 and rendered primitives are
896,957 → 1,024,189. Texture memory is 344.66 → 340.02 MiB; render submission
CPU time is 1.057 → 1.048 ms. Native GPU time remains unavailable. These numbers
do not support claiming a geometry reduction or an isolated CPU bottleneck.

[Raw reports, logs, host metadata and 196 passing checks](validation/milestone26/finalization/native-ci32/).
The universal export and bundle/headless checks pass, but the windowed launch
fails its unchanged deadline: initial preparation takes 82.5 s and the player
check arrives at 144.3 s from process start. The worker-budget change did not
resolve packaged startup. No validated ZIP or fresh-download result is claimed.

## Native Metal investigation

[Run 24](https://github.com/oiwdis/last-train-out/actions/runs/43779162068), source
`8fbaa34`, completed all ordinary source benchmark suites and the gameplay tour,
but **failed packaged windowed startup**. It is not a downloadable final build.
Its full reports are in [native-ci24](validation/milestone26/finalization/native-ci24/).
The hosted hardware was Apple M1 (Virtual), Apple Paravirtual device (Apple5),
macOS 26.7.2 / Metal 3.2, 960×540 windowed; 60 warmup and 120 sampled frames.

| Warehouse B / preset | M2.5 median ms | Previous M2.6 median ms | Pre-bake finalization median ms | Finalization p95 ms |
|---|---:|---:|---:|---:|
| Low | 5.22 | 5.91 | 7.55 | 11.36 |
| Medium | 5.99 | 8.30 | 7.69 | 10.08 |
| High | 7.66 | 13.22 | 14.59 | 20.36 |

These samples do not show a consistent native steady-state improvement over
`dfbfdf8`: High is 10.3% slower in the preset cohort, while the first ablation
High is faster and its repeated High is slower. That variation prevents a precise
attribution from the short virtual-GPU samples. The new artwork also remains
more expensive than the simpler M2.5 build.

More significantly, the finalization's first-entry worst frames were
**665 / 840 / 1307 ms** on Low/Medium/High (previous M2.6: 418 / 343 / 522 ms).
Those are severe stalls even though the median frames are much shorter. They
are retained as evidence rather than removed as outliers.

Enabling the optional skin-scattering path then exceeded a separate 90-second
probe deadline. The captured Mac stack has the main rendering thread waiting
for a pipeline task and worker threads inside the Metal compiler. All shipped
presets disable this effect; character initialization/teardown also avoids a
transient enable. The failed probe is an explicit forensic command now, so its
compiler-service work cannot compete with subsequent ordinary release checks.

The packaged self-test spent about 40 seconds loading the scene and reached
its initial standing check at 120 seconds, then completed its gameplay checks
but expired before the screenshot checks. The enabled shader-baker preset had
been silently ignored because the exporter used the dummy headless renderer.
The corrected export initializes Forward+ Metal, builds an export-only inventory
of generated material variants, and requires shader-cache entries in the PCK.
Run 25 finished baking and signing, then queued 133 redundant texture imports
because the authored import records still enabled editor auto-detection. Explicit
3D, normal and roughness handling now prevents this second import. The build
directory is excluded from the editor scan. Its compressed full export log is
retained in [native-ci25](validation/milestone26/finalization/native-ci25/).
Godot 4.5.1 also reports offline Metal compilation errors in unused voxelization
variants and retains their source fallback; the game does not enable SDFGI.
Those engine-export diagnostics are distinct from gameplay errors, and do not
replace validation of the shipping render paths in a freshly downloaded app.
The shader baker stores intermediate Metal code; GPU-specific pipelines still
need validation on the destination hardware.

### Entry preparation check (run 27)

The final source preset and route suites completed and exited successfully in
[run 27](https://github.com/oiwdis/last-train-out/actions/runs/43786384588), using
600 samples and 120 warmup frames on the same class of hosted Metal device.
The run was then cancelled during ablations to advance CI to the export fixes;
its incomplete three-revision cohort is not a final comparative result.

| Entry route | Median ms | p95 ms | Worst ms | Preparation ms |
|---|---:|---:|---:|---:|
| Low | 4.981 | 7.019 | 9.049 | 4675 |
| Medium | 5.854 | 8.374 | 11.211 | 5317 |
| High | 8.322 | 11.410 | 15.188 | 8141 |

Every pipeline counter stays unchanged between the start and end of each pan.
Compilation has a visible loading cost: the initial cold source preset process
spent 35.6 seconds preparing its first views and 25.2 seconds preparing Low.
The following route process reused compilation caches; its initial preparation
was 9.4 seconds. These costs are reported, not included as ordinary play frames.
One static-platform Medium sample still reached 595.7 ms despite unchanged
pipeline counters. This run alone does not prove the absence of all stutter.
[Raw partial-run evidence](validation/milestone26/finalization/native-ci27/).

### Exported startup gate (run 29)

[Run 29](https://github.com/oiwdis/last-train-out/actions/runs/43787562000),
source `a4450fd`, completed the full 600-sample comparison and new tour. The
universal Metal export completed in 16 min 26 s without the redundant texture
reimport. Bundle checks and all 31 packaged arm64 headless checks passed.
**The windowed launch still failed its unchanged 120-second watchdog.** The main
scene-load milestone arrived at 47.6 s from process start (including engine
initialization), initial preparation took 67.8 s, and the initial player check
arrived at 134.4 s. It reached carrying/storage checks
but expired before preset and screenshot validation. No final ZIP was published.

The prepared entry-pan worst frames were 9.64 / 31.18 / 29.97 ms versus previous
M2.6's 466.41 / 606.39 / 564.37 ms. Warehouse B High median was 11.40 versus
13.71 ms, but the separate repeated-High ablation was 15.12 versus 13.56 ms.
These mixed steady-state results are retained; faster prepared pans do not excuse
a failed cold packaged launch. This run predates the 0.9 worker-budget candidate.
[Full comparison and failure evidence](validation/milestone26/finalization/native-ci29/).

### Controlled driver comparison (run 33)

[Run 33](https://github.com/oiwdis/last-train-out/actions/runs/43796061709)
reused the complete baked export cache and exported in 91 seconds. Its default
Metal launch reached rendering checks but failed with “Shader was generated for
a newer Apple GPU” and failed shader creation. A bounded alternative-driver
probe ran the **same exported app on the same runner**, Apple M2 Pro (Virtual),
using Vulkan through Godot's bundled MoltenVK. All 34 graphical gameplay checks
passed in 79.1 seconds, within the unchanged 120-second watchdog. Initial view
preparation took 18.30 seconds and the player-ready check arrived at 42.64 seconds.
The actual window was 1024×649; its VSync smoke sample is not a benchmark.

The probe logged two MoltenVK `VK_INCOMPLETE` pipeline-cache write messages and
an ObjectDB exit warning. Godot 4.5.1's [Vulkan cache serializer](https://github.com/godotengine/godot/blob/4.5.1-stable/drivers/vulkan/rendering_device_driver_vulkan.cpp#L4467)
explicitly accepts `VK_INCOMPLETE` when a cache grows between its size query and
serialization. This points to cache persistence rather than failed draw-shader
creation; it is not evidence that all caches persisted successfully. The Godot
error counter was zero, but that does not make the native log warning-free. Run 33 remained failed and published no ZIP;
the diagnostic did not override the failed default-driver gate.
[Raw controlled comparison](validation/milestone26/finalization/native-ci33/).

The final Mac configuration now explicitly selects Vulkan while retaining
Forward+. Its export cache uses a separate namespace, including customization
metadata, so old Metal libraries cannot skip the new driver's shader bake.

</details>

## Software Vulkan diagnostics

Intel Xeon Platinum 8573C / llvmpipe LLVM 19.1.7, four threads. Both versions are far below playable speed on this CPU renderer. The twelve-sample distributions are noisy; use the native Mac comparison for hardware evidence.

| Warehouse B case | Previous median ms | Final median ms | Final p95 ms |
|---|---:|---:|---:|
| High | 3544.3 | 2635.5 | 2998.0 |
| No local shadows | 3174.1 | 2520.6 | 3213.8 |
| No directional shadows | 3388.2 | 2361.4 | 2405.1 |
| No shadows | 3897.9 | 2210.6 | 2250.0 |
| No local lights | 3603.0 | 2370.0 | 2454.4 |
| No SSAO | 1929.4 | 1561.6 | 1586.7 |
| No MSAA | 3254.8 | 3233.5 | 3366.0 |
| No normal or roughness maps | 1128.2 | 1120.2 | 3472.7 |
| LOD 2.5 | 3683.3 | 2568.6 | 3235.0 |
| 65% pixels | 1974.6 | 1606.6 | 1886.7 |
| No animation | 3105.0 | 2455.8 | 2839.9 |
| High repeat | 3273.0 | 2518.7 | 3220.3 |

High median decreases 25.6% in this run; the repeated High sample decreases 23.0%. Draw calls are 633 → 634, rendered primitives 896477 → 999929, and texture memory 485.5 → 480.6 MiB. Render submission CPU time is 2.05 → 1.48 ms, while the software-GPU monitor is 3820.1 → 2715.4 ms. This supports a pixel/material workload bottleneck in software rendering, rather than an inference based on polygon count.

Removing SSAO or reducing pixel count has a large effect. Some ablations are non-monotonic and the normal/roughness-map case has a wide tail; those short samples do not justify removing the authored maps or ranking small optimizations.

[Raw before](validation/milestone26/finalization/profile-before.json), [raw final](validation/milestone26/finalization/profile-after.json), and corresponding logs are committed.

## Reproduce

`tools/macos/benchmark_compare.py` runs the three source revisions and twelve
Warehouse B ablations on the hosted Mac. The workflow retains raw JSON/logs,
hardware details, elapsed benchmark stages and pipeline counters. The optional
`--skin-probe` investigation is bounded and its timeout is reported as a
diagnostic failure, never as a passing gameplay benchmark. Ordinary CI does not
repeat that unsafe, non-shipping effect ahead of release validation.

For one source checkout with imported assets and an available graphical display:

```sh
godot --path . --audio-driver Dummy --resolution 960x540 \
  --script tools/benchmark_milestone25.gd -- \
  --suite=presets --warmup=120 --samples=600 --out=/tmp/lto-presets.json
godot --path . --audio-driver Dummy --resolution 960x540 \
  --script tools/benchmark_milestone25.gd -- \
  --suite=route --warmup=120 --samples=600 --out=/tmp/lto-route.json
godot --path . --audio-driver Dummy --resolution 960x540 \
  --script tools/profile_finalization.gd -- \
  --warmup=120 --samples=600 --out=/tmp/lto-ablations.json
```

The local software runs use the same profiler with eight warmup frames and twelve
samples, `LP_NUM_THREADS=4`, a dedicated Xvfb display and Mesa llvmpipe LLVM 19.1.7.
Their short, noisy samples diagnose large effects only. They cannot rank small
changes reliably or predict hardware FPS. Raw intermediate SSS-enabled reports
are retained for diagnosis and are not labelled final preset results.

## Software renderer shutdown investigation

The default Godot worker-pool configuration repeatedly hung after the route
finished and requested quit on local llvmpipe. An ordinary Low launch/quit passed.
A debugger trace places the main thread in the worker-pool shutdown wait, with
workers idle; it does not show gameplay continuing or a failed route assertion.
Otherwise identical 320×180 and 960×540 diagnostics exit with a temporary
`threading/worker_pool/low_priority_thread_ratio=1.0` override, while the default
control times out again. The project now uses a 0.9 background-worker ratio, which yields the same
four-worker budget on this host while avoiding a ratio of exactly one on
single-worker pools. The 960×540 route then exits normally without an override.
This is scheduling evidence, not a physical-Mac result. Earlier hosted Metal
preset/route processes already exited normally with the old defaults. The failed raw run and debugger trace remain in the
validation evidence; completed samples alone are never labelled a successful
process. The software ablation comparison above measures the material/geometry pass at
`8fbaa34`, before the later startup-preparation and worker-budget changes, with
the original worker settings on both revisions. Final native reports include
processor count and the actual worker ratio.
