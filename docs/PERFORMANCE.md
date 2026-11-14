# Rendering performance — Milestone 2.5

The target reported by the user is a **2020 M1 Mac running full-screen**. Its macOS
version and display resolution are unspecified. No physical M1 was available. The
expanded scene is more expensive than Milestone 2 on the available software renderer;
this update does not establish playable M1 performance or a 60 FPS result.

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
| Normal / roughness maps | Simplified constant response | Full PBR maps | Full PBR maps |
| Ambient occlusion | Off | Off | On (Forward+) |
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

## Matched-view measurements

Godot **4.5.1**, Linux, **Intel Xeon Platinum 8573C**, Mesa **llvmpipe/lavapipe LLVM 19.1.7**,
Vulkan Forward+, four software-rendering threads, 1280×720 window, VSync disabled.
This is a shared cloud CPU running a software GPU, not an Apple GPU. These numbers
locate costs and compare render settings; they are unsuitable for predicting M1 FPS.

`tools/benchmark_milestone25.gd` was run on M2 commit `444fafc` and this working tree.
It uses identical fixed camera positions, FOV 78, player positions, resolution and
quality presets; legacy cutaway monitoring is disabled in the comparison. The main
camera controller is disabled for these fixed views. Each row has 8 warm-up frames
and 24 measured frames after initial scene warm-up, with no `--fixed-fps` or Movie Maker.
The scene and material workload changed, and High now includes ambient occlusion.
Short samples and a shared host limit confidence in small differences.

| View / preset | M2 median ms | M2.5 median ms | M2.5 mean FPS | M2.5 p95 ms | Draw calls | Primitives |
|---|---:|---:|---:|---:|---:|---:|
| Platform / Low | 61.4 | 117.3 | 8.3 | 127.3 | 207 | 219001 |
| Platform / Medium | 130.8 | 264.9 | 3.7 | 300.8 | 382 | 344885 |
| Platform / High | 196.0 | 501.5 | 1.9 | 566.4 | 506 | 374737 |
| Warehouse B / Low | 52.2 | 142.3 | 6.9 | 160.3 | 374 | 192773 |
| Warehouse B / Medium | 130.5 | 263.9 | 3.8 | 270.7 | 637 | 219585 |
| Warehouse B / High | 224.4 | 532.0 | 1.9 | 545.9 | 816 | 239997 |

The main added costs are PBR texture sampling, beveled/curved geometry and High's extra
lighting passes. The train-facing view has fewer draw calls than M2 despite substantially
more geometry; cylinder/rivet fittings are batched by material. Low keeps textured albedo
but disables triplanar normal and roughness maps. Its measured median frame time changed:

| Low view | Before simplified shading | After | Change |
|---|---:|---:|---:|
| Platform | 150.6 ms | 117.3 ms | -22.1% |
| Warehouse B | 155.9 ms | 142.3 ms | -8.7% |

This is a measured improvement within M2.5 on this renderer, not a claim that M2.5 is faster
than M2. Process-time monitors in the raw reports can include renderer waits and retain a
previous sampling interval; they are not exclusive GDScript timings. Physics monitors in
the final rows are roughly 0.6–1.6 ms. Real GPU profiling is still needed.

## Budgets and decisions

- Eight shared 1K material sets, with mipmaps and VRAM compression; no 4K/8K textures,
  displacement, SSR, SDFGI or runtime reflection probes. Original GLB imports generate LODs.
- Static boxes, braces, cylinders and rivets batch by material; beveled shape/material
  combinations are cached during the live scene. The moving cars retain simple collision.
- Low disables shadow passes, ambient occlusion, normal/roughness texture fetches, bloom
  and volumetrics. Medium keeps the directional shadow and full maps; High adds authored
  local shadows, 2× MSAA and supported atmosphere. Gameplay collision is unchanged.
- Warm hall/interior lights are unshadowed. Distant local lights fade in Low/Medium.
  Transparent glass is limited to train windows; smoke, dust and motes stay bounded.
- Inventory refreshes on signals, search processing runs only during a search, and loose
  items sleep after settling. Cab speed text refreshes at 10 Hz. Camera collision uses
  one swept sphere; interaction rays are refreshed by the HUD at 10 Hz and when used.

[Final raw samples](performance/milestone25_matched_3d.json),
[M2 matched samples](performance/milestone2_matched_3d.json), and
[before Low shading simplification](performance/milestone25_before_low_shading.json).
[The previous M2 report](MILESTONE_2_PERFORMANCE.md) is retained unchanged.

A physical full-screen M1 playtest should record actual window resolution, preset,
renderer, frame-time distribution and thermal state while riding, switching views,
and exploring both warehouses. The available evidence does not complete that check.
