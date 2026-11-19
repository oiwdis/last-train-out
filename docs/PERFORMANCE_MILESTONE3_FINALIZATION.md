# Milestone 3 finalization performance

Godot 4.5.1, Linux, Intel Xeon Platinum 8573C, Mesa 25.0.7 llvmpipe (LLVM 19.1.7), Compatibility/OpenGL, 1280 × 720 viewport, four software-renderer threads. **These are cloud software-GPU measurements, not physical 2020 M1 measurements.** They do not establish target-Mac frame rate or thermal behavior.

Baseline: `ebfa2689d31135588ae1f7c140e1c1cf274b39d4` in a detached checkout. Journey measurements use gameplay from `993e1c3128ce7139f65505ae61e7c05eb4778625`. Subsequent fixes center the pause/results panel and defer the default route resource load until script classes finish loading; they do not change the measured world geometry, presets or fog rendering. `tools/benchmark_journey.gd` provides the same Harlow camera positions, targets, FOV, preset procedure and fog clearance to each checkout. There are 10 warmup frames and 24 directly timed rendered intervals per case; VSync is requested off, without fixed FPS or Movie Maker. The driver reports that changing VSync is unsupported.

The baseline, matched journey views, and additional route/station views ran sequentially. No other graphical renderer was drawing during sampling. Some headless validation ran concurrently on the shared host. Shader-cache state and host load were not controlled as a laboratory benchmark. In particular, faster samples below are **not a verified optimization claim**. The added world is modest in the matched Harlow view, but the spread in these short samples limits conclusions.

## Matched Harlow views

All timings are milliseconds. “Near” means the observer is 8 route metres ahead of the front; “distant” is 210 m. The train can be farther behind than the observer, so HUD warnings are not the benchmark classification.

| View | Preset | Fog | Baseline mean | Journey mean | Journey p95 | Journey maximum |
|---|---|---|---:|---:|---:|---:|
| platform | Low | distant | 90.7 | 94.2 | 109.0 | 111.5 |
| platform | Medium | distant | 198.4 | 196.7 | 204.1 | 205.3 |
| platform | High | distant | 1409.3 | 1155.1 | 1177.7 | 1191.4 |
| platform | Low | near | 108.6 | 106.3 | 114.7 | 116.9 |
| platform | Medium | near | 249.0 | 239.2 | 249.6 | 258.0 |
| platform | High | near | 1876.6 | 1292.9 | 1541.7 | 1548.5 |
| warehouse | Low | distant | 129.4 | 100.0 | 113.3 | 116.4 |
| warehouse | Medium | distant | 266.3 | 253.9 | 289.8 | 298.7 |
| warehouse | High | distant | 1605.4 | 1123.1 | 1145.6 | 1147.0 |
| warehouse | Low | near | 114.5 | 86.5 | 88.8 | 91.8 |
| warehouse | Medium | near | 294.9 | 206.1 | 213.1 | 215.6 |
| warehouse | High | near | 2023.1 | 1503.2 | 2118.1 | 2244.0 |

The distant Harlow platform adds two draw calls (327 → 329 on Low) and moves from 90.7 to 94.2 ms mean, about +3.8%. Medium is effectively unchanged in that view. Near-front overhead is visible in several cases, particularly High; High is unsuitable on this software GPU in both builds. The long route does not make the original Harlow view uniformly slower.

## Travel and new stations

The train moves along a live curved segment for the travel case; the camera follows it. Station cases use fixed observation points. The workshop is measured 8 m ahead of the front; the other added cases use 210 m. Player geometry is hidden for the fixed station eye positions so it cannot occlude the view. These are profiling fixtures, not the continuous gameplay recording.

| View | Preset | Mean ms | p95 ms | Maximum ms | RSS MiB |
|---|---|---:|---:|---:|---:|
| Curve travel | Low | 78.7 | 120.7 | 127.1 | 622 |
| Curve travel | Medium | 140.4 | 173.4 | 206.9 | 639 |
| Curve travel | High | 442.1 | 440.9 | 688.5 | 698 |
| Ashford yard | Low | 27.5 | 29.2 | 30.1 | 666 |
| Ashford yard | Medium | 59.9 | 62.5 | 63.9 | 667 |
| Ashford yard | High | 239.4 | 252.7 | 264.9 | 699 |
| Ashford workshop | Low | 49.0 | 51.3 | 51.8 | 667 |
| Ashford workshop | Medium | 148.5 | 151.0 | 152.1 | 667 |
| Ashford workshop | High | 436.9 | 592.1 | 712.7 | 713 |
| Blackwater crossing | Low | 31.6 | 32.5 | 33.1 | 681 |
| Blackwater crossing | Medium | 84.1 | 89.1 | 92.8 | 681 |
| Blackwater crossing | High | 258.3 | 261.1 | 262.4 | 714 |
| Blackwater stores | Low | 48.1 | 51.5 | 55.0 | 681 |
| Blackwater stores | Medium | 148.5 | 155.6 | 168.4 | 681 |
| Blackwater stores | High | 392.6 | 498.9 | 592.2 | 713 |

Low travel averaged 78.7 ms, with a 127.1 ms maximum. Low new-station views averaged 27.5–49.0 ms. High remains expensive (239–437 ms averages in those station views); this is not a claim that it meets the target Mac budget. The scripts also record Godot process/physics monitor values for diagnostics. Those monitors update less often than the direct frame samples and can retain setup/previous-preset history; they are not used for the timing conclusions above.

## Memory and loading

* Engine-managed static allocation at the matched Low Harlow platform rises from 99.7 to 118.5 MiB, about **18.8 MiB**. Additional route/station cases remain around 118.5–118.6 MiB, with a reported peak of about 130.6 MiB. This excludes some graphics-driver allocations.
* RSS ranges from about 716–1,073 MiB in the baseline, 567–909 MiB in the matched journey pass, and 622–714 MiB in the separate station pass. Driver/allocator history differs between processes; do not infer a memory saving from the lower journey RSS.
* The journey controller’s initial route/station setup and binding took **304–325 ms**. All three small stations remain resident. Arrival only changes the stop/mission cursor and fog station metadata; it does not instantiate or unload station scenes.
* Startup to eight rendered frames was 9,792 ms for the baseline and 3,798/4,894 ms for the journey passes. These include import/shader/cache and rendering costs with different cache histories and are **not matched cold-start measurements**.
* The baseline profiling process logged an X11 pointer-grab error before timing (an idle capture window held the pointer) and a shutdown allocator warning after writing the report. The measured frames completed. The journey profiling passes completed without engine errors. These fixture issues are separate from the clean game smoke/test/native-app checks.

## Budgets and next validation

Rails and sleepers use MultiMesh batches in 120 m visibility chunks. Track collision stays resident so riders and dropped items are never unloaded. Simple reusable station shells, shared materials, existing light-distance limits and unchanged Low/Medium/High presets bound the additional work. No expensive global fog pass or new shadowing scheme was added.

A physical 2020 M1 fullscreen session is still required for the user’s actual target. Repeat travel, first arrivals, interiors and near-front cases at that machine’s native fullscreen resolution, include cold/warm launch and a sustained thermal run, and compare the eventual combined PR #4/#5 build. This PR does not claim 60 FPS on M1 or photorealistic station assets.

Raw data: [baseline](validation/milestone3-finalization/performance-baseline.json), [matched journey](validation/milestone3-finalization/performance-journey.json), [travel/stations](validation/milestone3-finalization/performance-stations.json).

```sh
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 --script res://tools/benchmark_journey.gd -- --mission --out=/tmp/journey.json
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 --script res://tools/benchmark_journey.gd -- --stations-only --out=/tmp/stations.json
```

For the baseline, copy this profiling harness into a detached `ebfa2689` checkout and omit `--mission`/`--stations-only`. First import the checkout with Godot 4.5.1. The original fog-performance report remains as historical evidence; this report covers the expanded journey.
