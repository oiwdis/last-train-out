# Environment continuation — rendering comparison

The same Godot 4.5.1 script and cameras compare the previous M2.6 commit `86b2473` with this environment pass. These are short, uncapped **Low** samples on Linux with an Intel Xeon Platinum 8573C and Mesa lavapipe/llvmpipe LLVM 19.1.7 software rendering, Forward+, 1280×720, `LP_NUM_THREADS=4`, VSync off, 65% 3D scale. No tests, imports, video captures or other rendering jobs ran during either measurement. Eight warmup frames precede 24 measured frame intervals in each view.

This CPU renderer is not playable in either version and does not predict physical M1 performance. The timings are noisy short samples on a shared host. Draw-call counts show the effect of replacing old decorative batches and instancing the new facades; higher triangle counts reflect the added geometry. Do not treat these changes as a sustained FPS guarantee.

| Low view | Before median ms | After median ms | Change | After p95 ms | Draw calls before → after | Primitives before → after |
|---|---:|---:|---:|---:|---:|---:|
| Platform | 588.6 | 479.0 | -18.6% | 586.4 | 217 → 217 | 357892 → 387697 |
| Warehouse B | 701.9 | 667.4 | -4.9% | 688.5 | 307 → 282 | 268187 → 359797 |
| Freight yard | 389.7 | 372.9 | -4.3% | 388.6 | 166 → 143 | 164727 → 243548 |

Raw [before](validation/milestone26/environment/performance-before.json) and [after](validation/milestone26/environment/performance-after.json) reports and logs are committed. Reproduce by copying `tools/benchmark_environment.gd` to the `86b2473` checkout, then running each checkout separately:

```sh
LP_NUM_THREADS=4 godot --path <checkout> --audio-driver Dummy --resolution 1280x720 --script tools/benchmark_environment.gd -- --samples=24 --out=<report.json>
```

The cloud Linux host additionally requires its downloaded Mesa ICD (`VK_ICD_FILENAMES=/tmp/lto-vulkan/usr/share/vulkan/icd.d/lvp_icd.json`, `LD_LIBRARY_PATH=/tmp/lto-vulkan/usr/lib/x86_64-linux-gnu`) and Xvfb display. Do not silently compare an OpenGL fallback against Forward+.

The macOS workflow retains the separate matched Low/Medium/High comparison against Milestone 2.5 at 960×540, with actual viewport equality enforced. Its build-specific hardware, native results and artifacts are reported in PR #4. Those hosted windowed measurements do not establish full-screen performance on the user's physical 2020 M1 Mac.
