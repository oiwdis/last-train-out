# Milestone 2.6 performance comparison

These are **cloud software-rendering measurements, not physical M1 results**. They cannot establish 60 FPS or full-screen playability on the user's 2020 M1 Mac. Hosted macOS launch checks exercise the exported app but are not a frame-rate benchmark. A separate CI step runs this same benchmark against both revisions on the hosted Apple Silicon runner; its raw results are in the run’s test-logs artifact and the pull request reports whether it succeeded. Those are windowed editor-runtime measurements, not the user’s full-screen device. The Mac helper uses a 960×540 window that fits inside the hosted desktop and verifies both actual viewports exactly match that size. This is a separate cohort from the Linux 1280×720 samples below; comparisons between platforms are not controlled.

Both samples use Godot 4.5.1 Forward+, Linux x86_64, an Intel Xeon Platinum 8573C host, Mesa llvmpipe/lavapipe LLVM 19.1.7, `LP_NUM_THREADS=4`, a 1280×720 Xvfb window, VSync disabled and no fixed FPS/Movie Maker. There were no concurrent test/render/build jobs during the after sample. Each cell uses 8 warmup frames and 24 measured frame intervals after selecting the same camera and preset. Short samples on a shared CPU are noisy, particularly during resource/shader activity; these are directional comparisons, not statistically precise device benchmarks.

Baseline: M2.5 `8cde10cf78c1ea0cf7f7bafb5fc146d2e12514c2`. Result: the M2.6 assets and runtime in this branch. The unchanged benchmark is `tools/benchmark_milestone25.gd`. Raw [before](validation/milestone26/performance-before.json) and [after](validation/milestone26/performance-after.json) reports include mean, median, p95, FPS from mean, draw calls, primitives and process/physics monitors.

| View / preset | Before median ms | After median ms | Change | After p95 ms | Before → after draw calls | Before → after primitives |
|---|---:|---:|---:|---:|---:|---:|
| Platform / Low | 125.2 | 456.6 | +264.7% | 476.9 | 207 → 217 | 219001 → 358134 |
| Platform / Medium | 325.7 | 1630.8 | +400.7% | 2212.5 | 382 → 420 | 344885 → 847838 |
| Platform / High | 512.0 | 5765.4 | +1026.0% | 5988.5 | 506 → 521 | 374737 → 981653 |
| Warehouse B / Low | 120.4 | 717.8 | +496.2% | 917.4 | 374 → 307 | 192773 → 268427 |
| Warehouse B / Medium | 278.3 | 2773.8 | +896.6% | 3043.8 | 637 → 479 | 219585 → 444560 |
| Warehouse B / High | 578.0 | 6552.8 | +1033.8% | 9074.3 | 816 → 605 | 239997 → 622217 |

The software-renderer regression is substantial: median frame times increased **3.6–11.3×** across these samples. Low averaged only **1.3–2.2 FPS** here. Reduced draw calls do not offset the increased rendering cost on this backend, and this environment does not meet a playable frame-rate target. Native Mac measurements must be assessed independently.

## Presets and asset budgets

Low preserves detailed models and albedo textures while disabling normal/roughness sampling, shadows, bloom and volumetrics; it uses 65% render scale with a 720p 3D budget. Medium balances resolution, material detail and lighting; High enables the existing full lighting/shadow/AO path. The UI stays sharp. Repeated props use material-sharing MultiMesh batches grouped in 20 m sections with a 65 m visibility range. Godot generates LODs, compressed imports and mipmaps. Low/Medium/High use 4/2/1-pixel mesh LOD thresholds respectively. Track sleepers/fasteners use separate 20 m batches and 100/55 m visibility limits, with small repeated plates kept below 100 triangles. Source character images are capped at 2K; industrial models and scanned material maps use 1K. Static prop triangle budgets and actual processed counts are in `assets/props/mesh_metrics.json`.

GPU texture compression is native on the target hardware but is handled by this software backend here; this comparison changes both assets and texture formats, so it cannot isolate a cause or predict M1 GPU behavior. The detailed source locomotive and skinned human add geometry; replacement shelving, crates and short track batches limit per-object drawing overhead. An intermediate implementation submitted kilometre-long batches of beveled sleepers/fasteners and reached about 857k visible primitives on Platform/Low; that implementation was rejected and replaced by locally culled, budgeted fittings. This tradeoff is visible in the table. Neither changes the original player/train collision or movement integration.

## Physical Mac acceptance still open

Test the downloaded universal build on the actual 2020 M1 Mac, at its full-screen display resolution, in all three presets. Record macOS version, resolution, median/p95 frame time and sustained play after shader warmup through platform, both warehouses and moving train. Low is the starting recommendation for this older Mac. Until that run is available, M1 playability and the 60 FPS target remain unverified.
