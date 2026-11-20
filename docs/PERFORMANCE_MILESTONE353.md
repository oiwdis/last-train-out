# Milestone 3.5.3 performance and renderer stability

**Release remains blocked.** The default exported game lost the device in 9 of 95 hosted processes. An independent rebuild had six more cold High losses in its own 95-process schedule. Native Metal completed the same 95-process schedule with zero device losses. A further 67-process replication also completed. Together 71 of 162 processes logged a sampler warning and cold readiness reached 169.565 s. High Warehouse B and train-interior tails remain slower than the matched original integration. Physical 2020 M1 validation is pending. PR #6 remains draft.

The investigation started with a repeatable Apple Paravirtual GPU timeout in the shipped High workload. The standalone renderer probe completed all 31 hosted processes including Metal API validation. The complete mission reproduced the timeout with camera preparation disabled, at reduced pixel coverage during preparation, and with PSO persistence disabled. None of those changes qualifies as a cure. The default remains Godot 4.5.1 Forward+/Vulkan.

[Crash signatures, stacks and hypotheses](RENDERER_CRASH_INVESTIGATION.md) · [All 28 controlled full-game experiments](validation/milestone353/probes/workload.md) · [Original failing runs and raw downloads](validation/milestone353/origin/README.md)

## Changes to the game and measurements

- The locomotive uses the most recent distance, speed and regulator/brake state to avoid reapplying an identical pose. When any changes, the wheels, rods, gauges and steam still follow the actual train, including a stopped train restored to another part of the route. In a 120-frame parked probe each sampled wheel, rod and gauge received 146 inherited transform notifications before and 26 after. During 60 moving frames each received 179 more in both versions. A focused integration test observes real transform notifications and a distance change at zero speed.
- Fog still has six authored sheets, with two/four/six active by quality. The observer updates the Environment only when its values change, and publishes a new sheet transform once when the front advances. A stationary sheet received 120 transform notifications before and zero after in the same probe. The shader's right edge uses `1.0 - smoothstep(0.9, 1.0, UV.x)`. GLSL leaves results undefined for the previous reversed edges. This corrects shader portability without identifying it as the cause of a device loss. Exposure, events, damage and shelter still run in their original simulation.
- Stair treads and stringers, rail profiles and fasteners, and connecting rods assemble through CPU mesh arrays. The previous industrial flight alone appended 98 intermediate GPU-backed boxes. An expanded triangle comparison of 29 unique gameplay meshes and 42,696 indexed corners found identical positions, UVs, vertex counts, index counts and winding. The maximum normal-component difference was 0.000116 from eliminating an intermediate packing round trip.
- The exported startup trace waits for the mission's ready flag and the end of the preparation pause before its three physics ticks. It retains the next 30 individual frame intervals. The existing entry/steady benchmark still includes every location and every outlier.

[Parked and moving probe](validation/milestone353/probes/motion-probe.gd.txt) · [Before](validation/milestone353/probes/idle-before.log) · [After](validation/milestone353/probes/idle-after.log) · [Geometry arrays and comparison fixture](validation/milestone353/probes/assembly-geometry.zip)

## Validation design

The 304 starting test identities are pinned to `6038bfcd`. The release workflow verifies the universal bundle and publishes the ZIP after the automated tests and export, then exercises that exact artifact. Independent fresh downloads, stress and measured comparisons still run if another renderer check fails. A missing test, device loss, wrong backend, incomplete run or cleanup error leaves the corresponding release gate failed. The optional signing job depends on all acceptance jobs.

The original 31-process stress sequence retains its ten mixed cold starts, ten warm starts, all-preset seed and lifecycle cases. Two additional independent runners fill out 20 High, 10 Medium and 10 Low launches under **each** cache condition. Every process uses the same signed executable and a byte-identical copy of its exported pack. A headless preflight verifies private user data. Each warm cohort has an explicit seed. Baked shaders remain in the pack. Filesystem, driver and OS caches are shared; the tests do not measure a cold OS. Each attempt and series has a deadline. Failing data remain available.

[Historical baseline test identities](validation/milestone353/baseline/test-manifest.json) · [Physical 2020 M1 instructions, crash collection and acceptance criteria](M1_MILESTONE353.md)

## Development export and native startup

The downloadable universal app was built from PR head 5534cf82c2e6e494cbf54add169e6ab4e8101b46. Its build-73 Info.plist records the CI merge commit 89bc264fccbe547b9f125e063e5bbd877744a743. Both commits have tree 9d4799cdd8a7c054498688e09070190903d6ef17. The ZIP SHA-256 is `e779c8b73b9e46a1b46c4a95c327e421d7f3da393b3123bc8d7cdb26b884f2a7`. The PCK SHA-256 is `dd21a5ccd9a1537a99bba028b16825ed2bc40ec7fa843b8861dc839fd4bae72d`. A fresh download contained one Last Train Out.app with executable arm64/x86_64 slices, 371 required project files and 144 baked shader-cache files. Independent bundle and ZIP checks passed 22/22 and 11/11. The build uses an ad-hoc development signature.

[Download the universal development ZIP](https://github.com/oiwdis/last-train-out/actions/runs/44675841777/artifacts/14602615877) · [Independent verification](validation/milestone353/candidate/independent-bundle.log)

The source-build runner's first three Low startup probes measured the following seconds from Godot's engine clock. Caches warmed across processes. The native executable spends time before the first script marker. The load span includes resources and decompression, and activation includes synchronous scene construction, physics registration and gameplay wiring. The final span includes GPU preparation, the unpause and the physics readiness check. GPU command timestamps and separate engine/OS decompression times are unavailable.

| Attempt | Engine to script | Script to load | Load | Instantiate | Activate | Activated to ready | Total ready | Worst next 30 frames, ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| First | 5.757 | 0.162 | 9.497 | 0.026 | 1.648 | 33.666 | 50.756 | 81.578 |
| Second | 4.919 | 0.103 | 1.428 | 0.008 | 1.172 | 11.442 | 19.072 | 38.855 |
| Third | 4.947 | 0.148 | 1.350 | 0.008 | 1.368 | 11.794 | 19.615 | 39.308 |

The first surrounding-world/fog-material pass took 22.524 s and the platform pass took 7.608 s on the first launch. Their timings fell to 4.420/4.593 s on the second. These spans include rendering and queue waits. They do not measure fog shader compilation alone. The earlier 6038bfcd Low series measured 59.688, 20.019 and 15.774 s on another runner. The paired and packaged distributions below carry more weight for acceptance.

[Native startup events, phase counters and process logs](validation/milestone353/candidate/performance-startup.zip) · [Earlier hosted Low series](validation/milestone352/final-native/README.md) · [Three-way matched history](validation/milestone353/history/README.md)

## Before and after on the default renderer

One hosted Apple Paravirtual GPU ran two 960×540 uncapped, windowed matrices per revision in alternating order. Each location/preset contributed 120 entry intervals and 1,200 steady intervals across both passes. The 120 settling frames per pass, initial scene preparation, preset switches and fixture transitions were timed separately. Every measured interval is retained. The benchmark fixes the camera for comparison. The continuous route below uses ordinary controls.

| Matched measure | Original 7df2f5a | Candidate 5534cf8 |
|---|---:|---:|
| Low mission-ready time, three attempts, s | 112.927 / 25.446 / 22.185 | 27.933 / 20.579 / 16.412 |
| High Harlow worst entry, ms | 2,166.518 | 99.056 |
| High Warehouse B steady p99, ms | 20.72 | 24.77 |
| High locomotive cab steady p99, ms | 16.75 | 24.11 |
| High passenger car steady p99, ms | 17.94 | 19.88 |
| Low Warehouse B steady p99, ms | 23.38 | 13.65 |
| Medium dangerous fog steady worst, ms | 33.391 | 28.321 |
| High near advancing fog worst entry, ms | 46.60 | 179.033 |
| Medium results screen steady worst, ms | 24.197 | 952.577 |
| Entry frames over 33.3 / 50 / 100 ms, of 4,320 | 45 / 23 / 8 | 40 / 18 / 5 |
| Steady frames over 33.3 / 50 / 100 ms, of 43,200 | 32 / 6 / 0 | 37 / 9 / 3 |
| All steady median / p95 / p99, ms | 9.213 / 15.293 / 18.744 | 8.909 / 15.955 / 19.677 |
| Matrix peak RSS, first / second process, MiB | 629.73 / 612.69 | 630.06 / 612.03 |

The 3.5.1 changes prepared the destination view through the renderer's queued frames before restoring play. Harlow retained that benefit across the three-revision isolation and this longer comparison. The first startup probe on each revision counted 94 cold shader-code misses. On later runs the cache was populated. The original first process also ran first on a newly allocated host, so 112.927 versus 27.933 s combines code and host warmup. Activation on the two warm launches fell from 6.576/6.476 to 1.402/0.930 s. The actual packaged cold cohorts still reached 79.312 s on Vulkan and 126.599 s on native Metal. The original early PSO serialization diagnostic occurred on two processes that still exited successfully. The candidate source timing and startup logs had no engine diagnostics with the stricter reader.

High Warehouse B still issued 653 draws and 1,007,915 primitives. Render-server CPU time averaged 0.88/1.06 ms in the original passes and 1.22/1.21 ms in the candidate passes. In the cab the scene submitted about 1,017 draws and 1.69 million primitives. The candidate High Warehouse B, locomotive cab and passenger car tails were slower. The 3.5.2 pair had measured Warehouse B at 39.59/49.00 ms on a different runner. The lower absolute 24.77 ms here cannot establish recovery against that host. Low and Medium Warehouse B improved against their matched original. The original and candidate matrix RSS peaks were within 1 MiB on corresponding passes. The mesh and stationary-transform probes isolate specific CPU savings. Those savings do not establish that the High interiors recovered. No controlled result identifies one of the added interior preparation views as a cause of a steady-state regression.

The historical 389.66 ms Medium dangerous-fog frame did not recur in this comparison. The candidate's 28.321 ms worst frame spent 26.440 ms between render callbacks. Medium near-fog entry reached 159.230 ms in a 157.556 ms render bracket and High near-fog entry reached 179.033 ms in a 177.167 ms bracket. The High near-fog entry window added zero surface, draw and specialization pipelines in both attempts. These separate views remain over the entry target. The danger simulation, exposure, damage, visual layer counts and shelter behavior remain active in gameplay.

All three candidate steady frames over 100 ms occurred at mission completion. The 952.577 ms Medium frame had 951.724 ms between render callbacks, 0.008 ms each in process and physics, 0.018 ms of render setup CPU and zero pipeline-count deltas throughout the steady window. The other candidate Medium pass peaked at 8.041 ms there. Six short exported Vulkan stress matrices on independent runners peaked between 6.687 and 13.255 ms in that cell, with 24 steady samples apiece. The actual result UI pauses the world and still draws its 3D background. The available samples do not identify a scene script, shader compilation or a hardware GPU duration for the long wait. High results included two additional steady frames over 100 ms. The full-journey pacing target is open.

[Every location, preset, startup stage, shader cache and memory comparison](validation/milestone353/candidate/comparison/COMPARISON.md) · [CPU time, draws, texture memory and all threshold counts](validation/milestone353/candidate/comparison/pooled-distributions.csv) · [Per-frame callback evidence](validation/milestone353/candidate/comparison/worst-frames.csv) · [Original logs, images, raw intervals and continuous-journey checks](validation/milestone353/candidate/performance-and-journey-logs.zip)

## Independent confirmation on a second hosted Mac

A second matched comparison retained the Harlow entry reduction at **2,510.907 → 81.929 ms**. High Warehouse B p99 was 19.365 → 19.470 ms on this runner. High cab and passenger-car p99 improved modestly here after worsening in the primary pair. Medium dangerous fog went from 31.533 to 42.277 ms. The historical 389.66 ms steady spike did not recur in this cell in either comparison. The second candidate's Medium results-screen worst was 44.373 ms, and **Low Warehouse B instead reached 976.263 ms**, including 931.360 ms in the render bracket with no pipeline-count change. The original also had a 603.403 ms High Ashford workshop frame on this runner. Long steady frames remain a release blocker.

The separately rebuilt export passed both 305-test suites, all six rendered lifecycle checks, both fresh downloads and another continuous 167/167 journey. Six of 20 cold High launches lost the device. Every warm launch completed. Across both default acceptance cohorts the recorded loss counts were nine in build 73 and six in build 77. The latter PCK differed only in its UID cache mapping for an external test script.

[Second matched table, both stress failures, full recording, checksums and original crash reports](validation/milestone353/confirmation/README.md)

## Mechanics, ownership and game integrity

The hosted Linux and macOS suites each passed **305/305**, in 98.9 and 143.4 seconds respectively. Independent Linux runs passed in 157.7 and 140.6 seconds. The later run also passed all four log-parser regressions and rechecked the 304 original identities. The source manifest checks every one of the 304 starting identities. The headless journey passed all 167 checks with zero travel teleports and one ordinary Save/Continue restoration. The fuel-shortage scenario passed 35 checks, natural stranding/fog failure passed 24, and separate-process resume passed 17. The build-runner export passed 46 headless and 49 windowed checks. A fresh ARM download also passed all 46 headless and 49 windowed checks on Forward+/Vulkan and all 81 packaged benchmark cases. The fresh Intel download passed 46 headless checks. The Intel runner provides no accelerated rendering gate.

All six rendered ownership checks passed. They cover cancellation, pause/camera restoration, material reuse, rapid preset switching, HUD invalidation and a rider with cargo restored during preparation. Their full logs retain the engine's static `servers` StringName and the MoltenVK allocation snapshot before Metal-device release. There were no game ObjectDB/resource-in-use warnings in that suite. A crashed or forcibly terminated process cannot establish successful cleanup.

[Hosted macOS suite and headless journey logs](validation/milestone353/candidate/test-logs.zip) · [Hosted Linux](validation/milestone353/candidate/linux-tests.zip) · [Final independent Linux, manifest and log parser](validation/milestone353/candidate/final-local-linux.zip) · [Local Linux](validation/milestone353/candidate/local-linux-suite.json) · [Rendered lifecycle and cleanup log](validation/milestone353/candidate/renderer-stress.zip) · [Build-runner self-tests and native export](validation/milestone353/candidate/selftest-build.zip)

[Fresh Apple Silicon download including the 81 packaged cases](validation/milestone353/candidate/selftest-arm64.zip) · [Fresh Intel download](validation/milestone353/candidate/selftest-x86_64.zip)

The controls harness also ran against the candidate PCK in a separate Linux headless sanity check. It mounted a two-script input archive with replacement disabled, drove the shipped scenes through all 167 checks and restored the one real save. That supplementary process emitted a Jolt job-capacity warning while independent software-renderer visual work was running. Its original log is retained. No causal attribution to the concurrent workload is available.

[Supplemental Linux packaged-data journey and warning](validation/milestone353/candidate/linux-packed-journey/raw.log)

## Default Vulkan failed release acceptance

The actual development export completed **86 of 95** scheduled processes across three fresh hosted ARM runners. Nine returned SIGTRAP after the Metal command-buffer timeout. None was skipped or retried. The 80 launch attempts included **8/20 cold High** and **1/10 cold Low** device losses. Cold Medium passed 10/10. Every warm launch passed (20 High, 10 Medium and 10 Low). All 15 supporting processes passed, comprising three isolation preflights, three warm-cache seeds, three preset/fog/Save/Continue cycles, three exits during preparation and three station-entry matrices. The two failing release gates are red. Five separate controlled hosts also exercised the **original 6038bfc** export with reduced shadow atlases. That older pack lost its device in 27/80 cold High trials across all four atlas settings. Its failures are kept separate from the candidate release denominator.

| Default Vulkan | Successful / attempted | Median ready, s | Slowest successful ready, s | Worst next 30 frames, ms |
|---|---:|---:|---:|---:|
| Cold High | 12/20 | 29.252 | 77.058 | 169.121 |
| Cold Medium | 10/10 | 25.402 | 67.719 | 158.300 |
| Cold Low | 9/10 | 21.659 | 79.312 | 130.436 |
| Warm High | 20/20 | 21.078 | 24.886 | 100.833 |
| Warm Medium | 10/10 | 17.076 | 21.253 | 114.025 |
| Warm Low | 10/10 | 17.380 | 22.888 | 83.493 |

The separate seed and station-entry matrices recorded worst entries of 177.084 and 137.214 ms. The startup probes also exceeded 100 ms after reporting readiness. Successful cold readiness topped out at 79.312 s across the three runners, compared with 89.107 s in the earlier, smaller 6038bfcd mixed cohort. The difference does not establish a matched cold-start win. The cold Low failure occurred at 420.83 MiB sampled RSS after the surrounding-world/fog pass reported 20 specializations. The issue is present below High quality and below the commonly observed 76-specialization boundary.

[All categories, p95 and full ranges](validation/milestone353/candidate/stress/STRESS.md) · [Every process and startup stage](validation/milestone353/candidate/stress/every-process.csv) · [Mixed series with both native crash reports](validation/milestone353/candidate/release-stress-mixed.zip) · [High series with seven native crash reports](validation/milestone353/candidate/release-stress-high.zip) · [Low/Medium series](validation/milestone353/candidate/release-stress-low-medium.zip) · [Mixed job log](validation/milestone353/candidate/release-mixed-job.log) · [High job log](validation/milestone353/candidate/release-high-job.log)

## Optional Apple Silicon mitigation

On the **same development ZIP and PCK**, the optional native Metal series completed **95/95** processes across three hosted ARM runners. All 92 rendered processes used the requested driver and three headless preflights verified isolation. After auditing stderr interleaving, **46/95** were diagnostic-clean and **49/95** emitted the Metal sampler LOD-bias warning. There were zero device losses. These included 20 cold and 20 warm High, 10 cold and 10 warm Medium, 10 cold and 10 warm Low, plus all 15 preflights, seeds and lifecycle processes. The owner-facing launcher also passed 49/49 windowed gameplay checks with native audio and emitted the same sampler warning. The executable reported the actual method and driver as `forward_plus/metal`. The comparison with the default Vulkan cohorts used the same launch matrix on separate fresh runners. It isolates an actionable backend choice while leaving uncertainty about the fault inside the Vulkan translation and device stack.

| Native Metal | Completed / attempted | Median ready, s | Slowest ready, s | Worst next 30 frames, ms |
|---|---:|---:|---:|---:|
| Cold High | 20/20 | 22.025 | 114.683 | 127.219 |
| Cold Medium | 10/10 | 20.806 | 122.811 | 109.693 |
| Cold Low | 10/10 | 21.091 | 126.599 | 103.309 |
| Warm High | 20/20 | 16.755 | 25.005 | 96.794 |
| Warm Medium | 10/10 | 16.523 | 18.474 | 129.904 |
| Warm Low | 10/10 | 15.492 | 22.076 | 151.805 |

Every cache condition could still exceed 100 ms in the first frames on at least one preset. The High warm group peaked at 96.794 ms. The first cold process on each Metal runner was much slower than subsequent fresh-user starts. The tested optional launch preserves Forward+, all preset choices and the shipped game. Normal double-click and Intel continue using the project's Vulkan configuration. Keep the optional driver available for physical M1 testing before considering any default change.

[Opt-in launcher and owner commands](M1_MILESTONE353.md#optional-comparison-on-apple-silicon) · [Complete Metal stress table and timing CSV](validation/milestone353/alternatives/metal/STRESS.md) · [High raw](validation/milestone353/alternatives/followup-forward-metal-high.zip) · [Mixed and lifetime raw](validation/milestone353/alternatives/followup-forward-metal-mixed.zip) · [Low/Medium and owner launcher](validation/milestone353/alternatives/native-metal-low-medium.zip) · [Mobile stress table](validation/milestone353/alternatives/mobile/STRESS.md) · [Mobile original logs](validation/milestone353/alternatives/followup-mobile-vulkan-mixed.zip)

The required three-method source comparison covers Forward+/Vulkan, Mobile/Vulkan and Compatibility/OpenGL. The first two completed all 36 steady and entry views and produced 72 screenshots. The hosted Mac selected software OpenGL, expanded BPTC textures, and missed every launch and matrix deadline. A supplemental Linux three-way screenshot comparison shows the Compatibility appearance at the same camera positions. Mobile improved average throughput but had worse High dangerous-fog p99 and a 180-second cold deadline miss in the actual pack. A second mixed Mobile runner completed 31/31 cleanly with up to 59.586 s cold readiness and 729.391 ms station entry. Both series together had 61/62 process completions, zero GPU-loss signatures and one missed deadline.

[Renderer timings, memory, features and visual comparisons](validation/milestone353/backends/README.md)

A second native Metal cohort reran the mixed and dedicated High series with the corrected strict reader. All **67/67** processes completed, **45** were clean and **22** emitted the sampler warning. Its first cold High took 144.937 s and cold Low took 169.565 s. Cold Low also reached 250.236 ms in the first 30 frames after readiness. Combining separately identified native Metal cohorts gives **162/162 completed, 91 clean, 71 warned, zero device losses**. The two Metal stress jobs in the corrected workflow failed on diagnostics.

[Every independent repetition, including raw job logs, shadow failures and Mobile's second cohort](validation/milestone353/alternatives/repeats/README.md)

The direct driver comparison kept Forward+, the shipped pack, viewpoints and host fixed. Native Metal lowered pooled p99 from 21.166 to 18.382 ms and High Warehouse B p99 from 26.834 to 19.520 ms. Its worst steady frame increased from 50.960 to 655.378 ms. Both Metal intervals over 100 ms occurred in Low Warehouse A in the second matrix. High passenger-car worst also increased. Each of the three Metal measurement/capture processes emitted the sampler warning. All three Vulkan processes were clean.

[Both drivers, 72 screenshots, full intervals and warnings](validation/milestone353/alternatives/driver-comparison/README.md)

## Continuous gameplay

The default Forward+/Vulkan recording followed normal controls from Harlow scavenging through a 4.26 km train journey, Ashford fuel and cargo recovery, fog pursuit, Blackwater Save/Continue and escape. It passed all 167 checks, recorded zero travel teleports and restored one actual saved position. The source-runner recording contains 16,925 frames at 960×540. The MP4 ran 23 minutes 30.42 seconds and decoded end to end. Its SHA-256 is `a323a9dd4d145862b4d8c0153cc666f782f1e4e887798d6cc4e84fff547b5c4c`. Movie Maker rendered Medium offline at 12 fps. Real-time frame pacing is measured in the separate uncapped matrices.

[Watch or download the continuous journey](recording/milestone353-full-journey.mp4) · [Media metadata](recording/milestone353-media.json) · [Original recording, stage screenshots, checks and played save from CI](https://github.com/oiwdis/last-train-out/actions/runs/44675841777/artifacts/14605555821)

The optional native Metal route used the **exported** app with its checksum-verified PCK, in an isolated user directory. Two external scripts only drove controls and collected results. Godot mounted them with resource replacement disabled. The repeat reached the same 4,260.006 m escape, checked all 167 interactions and restored one real save with zero travel teleports. Its 16,925-frame, 23:30.42 MP4 decoded end to end with SHA-256 `73a86001e8d442ac037e2d16f19fa8916b673afe069d4a2b8f351ea5f3ae4eb5`. The original attempt and the repeat both logged the scaled-preset sampler warning and both failed strict acceptance. The corrected recorder preserved the repeat MP4 before returning failure.

[Original exported attempt, checks and warning](validation/milestone353/alternatives/native-metal-journey-first.zip) · [Second attempt with verified MP4, input scripts and played save](validation/milestone353/alternatives/native-metal-journey-audited.zip) · [Failed recording gate and complete downloadable media](https://github.com/oiwdis/last-train-out/actions/runs/44682971905/artifacts/14605652344)

## Acceptance decision

Keep the PR in draft and the universal ZIP labeled as a development build. The build, 305 gameplay tests on both platforms, six native ownership checks, fresh ARM/Intel downloads and complete default journey passed. The required mixed and High exported Vulkan stress jobs failed. The recorded Harlow entry improvement survived, a dangerous-fog steady outlier did not repeat, and the default still missed the full-journey frame-pacing, startup and crash goals.

On Apple Silicon, evaluate Forward+ with the explicit native Metal launcher first. It preserves the artwork and completed every launch in the original 95-process cohort. The sampler warning, slower first launches and long frames in Low Warehouse A require physical testing. Mobile has different lighting, a cold timeout and slower High dangerous fog. Hosted Compatibility selected a software renderer and missed its deadlines. There is no evidence for an across-the-board engine upgrade or an automatic driver switch. Changing the project default remains an owner decision after the physical fullscreen measurements.

[Evidence index, file checksums and reproducible commands](validation/milestone353/README.md) · [Default release gates](https://github.com/oiwdis/last-train-out/actions/runs/44675841777) · [Physical M1 procedure, pass criteria and crash collection](M1_MILESTONE353.md) · [Draft PR #6](https://github.com/oiwdis/last-train-out/pull/6)
