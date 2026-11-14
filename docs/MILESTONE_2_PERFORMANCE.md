# Rendering performance — Milestone 2

The reported target is a **2020 M1 Mac running full-screen**. The macOS version and actual
display resolution are unspecified. The earlier low FPS report is real user feedback; its
cause is not established by these tests. No physical M1 Mac was available for this update,
so there is no claimed M1 FPS improvement or 60 FPS guarantee.

## Graphics controls

Use **F2** (often Fn+F2 on Mac), or **Tab / I → Graphics**. Medium is the default on a
fresh install. Choices take effect immediately and persist in `user://graphics.cfg`.
Try Low first on the reported full-screen M1, then compare Medium at the same location.

| Setting | Low | Medium (default) | High |
|---|---|---|---|
| 3D resolution | 65%, at most 720 pixels high | 85%, at most 1080 pixels high | Native |
| Interface resolution | Full | Full | Full |
| Moon shadows | Off | On, 45 m range | On, 90 m range |
| Authored local shadows | Off | Off | On |
| Volumetric haze | Off | Off | On where hardware supports it |
| Depth haze / warm lamps | On | On | On |
| Bloom | Off | On | On |
| MSAA | Off | Off | 2× |
| Particle count | Half | Authored | Authored |
| Local-light distance fade | Starts at 28 m | Starts at 40 m | Disabled |
| Positional shadow atlas | 512 | 1024 | 2048 |

At a 2560×1600 window, the computed Low scale is **0.45** (1152×720) and Medium **0.675**
(1728×1080), while text remains at the window resolution. A regression test verifies those
values. The calculation uses actual window pixels, not stretched UI coordinates, which can
remain near 1280×720 despite a much larger rendered full-screen image. This prevents a
full-screen resolution change from silently bypassing the intended rendering budget.

All presets preserve silhouettes, warm lights, interaction prompts and the exact same
collisions, Jolt settings, 60 Hz physics, camera, train integration and movement configuration.
Low trades shadow depth and edge quality for less rendering work. The original GPU capability
guard still prevents unsupported volumetric fog from being enabled by High.

## Investigation and changes

| Suspected cost | Evidence / response |
|---|---|
| Volumetric fog | Separate baseline run disables only volumetrics; Low/Medium use the existing depth haze instead. Hardware support is checked before enabling High. |
| Dynamic lighting | Separate run disables local lights; presets fade distant lights while retaining nearby guidance. Supplies add no lights. |
| Shadows | Separate run disables all shadows. Low removes them; Medium retains only the moon shadow with a shorter range and smaller atlas. |
| Materials | Source audit: existing opaque StandardMaterial3D scenery, roughness 0.82, batched by material; no expensive custom material shader or new texture stack. New props use the same builder. |
| Geometry / draw calls | Recorded for both camera positions below. Existing batched architecture remains. Thirteen supply props add a small number of primitive meshes; no level collision is removed. |
| Transparency | Cutaway walls use alpha only during the transition, then hide; their collision remains. Existing small smoke/mote/dust particle pools are the other alpha surfaces. Low halves their counts. No new translucent world effects were added. |
| Per-frame scripts | Supply interactables do not poll relative speed; search processing runs only during a search; static loose items sleep after settling; inventory UI refreshes on signals and checks storage reach at 10 Hz while open. Physics timing is recorded but is not a complete script profiler. |

Rendering changes are conservative and configurable. The measurements isolate broad rendering
features; they do not identify which cost dominates on Apple's Metal driver. Further material,
geometry or physics simplification would need evidence from the target Mac.

## Comparative measurement

Raw result tables and their hardware metadata are stored in `docs/performance/`. The baseline
is an archive of completed Milestone 1.5 commit `7571753`; its only addition is the identical
standalone benchmark script. Milestone 2 uses implementation `0146f29` with the new supplies
and UI present. Both use official Godot 4.5.1, Forward+, 1280×720, disabled VSync, no frame cap,
and real-time frame sampling (no fixed-FPS flag and no Movie Maker).

Each of the platform and Warehouse B views settles for 30 frames. Every case warms for 24
frames, then measures 72 `frame_post_draw` intervals. Baseline cases run in the listed order;
Milestone 2 runs Low, Medium, High. The two suites run sequentially without another Godot
process, capture job or test suite running locally. This is a shared cloud host: scheduling
noise and case ordering remain limitations. An earlier exploratory run made alongside debug
processes was discarded rather than used in the comparison.

Hardware: **Intel Xeon Platinum 8573C host, Linux x86_64, Mesa llvmpipe/lavapipe
LLVM 19.1.7, four software-rendering worker threads, Xvfb**. This is CPU-based rendering,
not an M1 GPU or a representative player machine. Samples were captured on 14 November 2026 UTC.

### Milestone 1.5 feature comparisons

| View | Case | Mean frame ms | p95 ms | FPS (1 / mean) | Draw calls |
|---|---|---:|---:|---:|---:|
| Platform | Milestone 1.5 | 180.9 | 189.1 | 5.53 | 406 |
| Platform | No volumetrics | 169.7 | 188.1 | 5.89 | 406 |
| Platform | No shadows | 182.6 | 194.7 | 5.48 | 255 |
| Platform | No local lights | 153.6 | 161.9 | 6.51 | 406 |
| Platform | 65% render scale | 131.5 | 139.3 | 7.60 | 406 |
| Warehouse B | Milestone 1.5 | 196.9 | 208.6 | 5.08 | 308 |
| Warehouse B | No volumetrics | 174.2 | 201.4 | 5.74 | 308 |
| Warehouse B | No shadows | 168.6 | 187.0 | 5.93 | 170 |
| Warehouse B | No local lights | 155.9 | 165.6 | 6.41 | 308 |
| Warehouse B | 65% render scale | 136.2 | 150.3 | 7.34 | 308 |

### Milestone 2 presets

| View | Preset | Mean frame ms | p95 ms | FPS (1 / mean) | Draw calls | Primitives |
|---|---|---:|---:|---:|---:|---:|
| Platform | Low | 56.4 | 60.7 | 17.73 | 268 | 53692 |
| Platform | Medium | 137.3 | 153.2 | 7.28 | 417 | 60196 |
| Platform | High | 186.8 | 198.5 | 5.35 | 420 | 60256 |
| Warehouse B | Low | 48.6 | 52.0 | 20.59 | 184 | 35078 |
| Warehouse B | Medium | 115.0 | 123.8 | 8.69 | 281 | 37718 |
| Warehouse B | High | 194.8 | 203.8 | 5.13 | 332 | 38498 |

In this run, Medium's mean frame time was **24–42% lower** than the original Milestone 1.5
across the two views; Low's was **69–75% lower**. High was about 3% slower on the platform
and 1% faster in Warehouse B, so it offers no consistent improvement over the baseline and
has the new props/UI to render. These are **software-renderer comparisons only**. The chosen
presets change several rendering features together, so these figures cannot attribute the
whole gain to one feature or predict M1 performance.

The baseline feature comparisons show a measurable cost for local lighting and pixel count;
volumetric and shadow effects vary by view, and removing shadows alone did not improve the
platform sample. Visible geometry is roughly 35–60 thousand reported primitives across the
new presets/views, with 184–420 draw calls. The new physics-processing monitor averages
0.57–1.08 ms in these samples, far below the total frame interval. This supports retaining
the tested collision/physics path, but is not a standalone script or target-GPU profile.


`process_ms` in the raw Godot monitor includes frame processing/render work and waiting;
it is not a measurement of GDScript execution alone. `physics_ms` is the physics processing
monitor. These samples show a rendering cost on this software renderer, not a definitive
profile of the user's M1.

## Reproduce on the target Mac

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 \
  --script tools/benchmark_rendering.gd -- --suite=presets --samples=180 \
  --out=/tmp/last-train-out-presets.json
```

Repeat with `--fullscreen` at the display's normal resolution; do not add `--fixed-fps` or
`--write-movie`. Record macOS version, monitor resolution/scaling, power/battery state and
thermal conditions alongside the JSON. For a before/after baseline, archive `7571753`, copy
only `tools/benchmark_rendering.gd` into it, import using Godot 4.5.1, and run `--suite=baseline`
at identical resolution. Restart between repeat trials and compare the same two views.

The in-game F1 debug menu exposes FPS for an informal manual check. Compare all presets
while stationary at the same point, then ride the moving train through both warehouses.
The shipped app can select a preset on launch with `-- --graphics=low` (or medium/high).
