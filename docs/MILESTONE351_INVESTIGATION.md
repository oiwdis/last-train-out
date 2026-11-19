# Milestone 3.5.1 investigation

Baseline: `7df2f5abee54b8adcf27b8668263fba231a79033`, PR #6 on the existing integration branch. Remote inspection found no newer changes. No source branch or default setting changes; PR #6 stays draft.

The unchanged Linux suite passes **292/292 in 142.9 s**, including import/main-scene checks. Its complete logs and identity manifest are under `validation/milestone351/baseline`. The guard now retains all 292 existing tests, as well as the original source union. The same baseline passed native run 48 (95.0 s); older native cohorts/failures remain in the Milestone 3.5 evidence.

## Evidence collection before optimization

The 2,506 ms entry frame follows the preset/route transition; the 937 ms fog outlier occurs during steady sampling. Zero pipeline-counter deltas do not establish their cause. The run 46 device loss reports MoltenVK command-buffer GPU timeouts during High preparation, followed by a lost Vulkan device. Identical-artifact retry passed, with shutdown warnings retained. There is no crash-fix claim.

Opt-in `--profile-phases` records resource load, instantiation, component construction, graphics collection/application and individual preparation views. `FrameTimeline` brackets scene process/physics callbacks and pre/post-draw signals; those intervals are not GPU timings. The enhanced matrix retains raw intervals, pipeline samples, primitive counts, >33.3/50/100 ms counts and fixture transition times. All twelve locations and presets remain.

The manual CI investigation mode produces evidence only, no release artifact. It runs three startup processes, two unsampled matrices and a separate stack-sampled matrix. Sampling runs are excluded from matched FPS comparisons. The first process is a fresh graphics-cache launch on a hosted runner, with imported assets/filesystem already warmed by validation. Native phase traces and stack samples are pending; no optimization or target achievement is claimed yet.

Local Compatibility/llvmpipe traces are diagnostic only. One initial Vulkan attempt could not find `VK_KHR_surface` and fell back to OpenGL; that failed attempt is retained. The explicit Compatibility trace places roughly 0.67 s in scene activation, while destination-renderer preparation is much larger. This does not establish native-Mac startup or GPU performance.

## Next validation

Identify native stall stacks/timing, implement measured changes, rerun matched baseline/optimized cohorts, stress preparation/load/fog/cleanup, preserve all existing tests and add targeted regressions, record another controls-driven journey, and export/test the universal application. Physical 2020 M1 fullscreen acceptance remains pending hardware access.
