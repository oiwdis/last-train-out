# Build 103 release evidence

The source of this export is `48fe07d96e95d8a6bea7e3e9e249d0d0b085d09c`. Compared with build 99, the game assets, scenes, scripts, graphics settings, selector and three engine patches are identical. The compatible Metal library archive grows from 319 to 365 precompiled stages. Apple’s compiler produced the extra 46 from the signed route shaders. The original 319 compiled payloads and all 94 source groups are preserved. [Universal build workflow](https://github.com/oiwdis/last-train-out/actions/runs/44822226233) · [Compiler output and two-host trial](../build-99/entry-libraries/README.md)

The release job rebuilt the native player with Xcode 26.6 (17F113) from upstream Godot `f62fdbde15035c5576dad93e586201f4d41ef0cb`. The ad-hoc-signed arm64 binary is byte-identical to build 99 and the two-host trial. Its SHA-256 is `bc06ab5d56e536bd1c6ad8dabaf226109ce841bf7273ae6ef0f1b91e4c292a04`. [Compiler log, patch hashes and binary provenance](template-provenance.zip)

## Download and identity

**[LastTrainOut-macos-universal.zip](https://github.com/oiwdis/last-train-out/actions/runs/44822226233/artifacts/14673852596)** is 332,320,165 bytes. An independent download passed all eight ZIP integrity checks. Its SHA-256 matches GitHub’s artifact digest, `abfb1842e86b044d0a4a143a683d64fa52bdf0d3a957c25a38e6cfec6b94a3bd`. It contains one `Last Train Out.app`, the universal stock player, universal renderer selector, separate arm64 native Metal runtime and one shared game pack. This development build uses an ad-hoc signature. Both architectures’ stock machine-code sections match build 99. The entire native Metal executable and selector match build 99 byte for byte. [Download receipt and slices](../build-103.json) · [ZIP validation](../build-103-zip.log) · [Machine-code hashes](stock-executable-code.json)

The PR workflow stamps the bundle with GitHub’s test-merge commit `7a040c7a02392d15ad0ea89844b00c1ea781b566`. The first local identity check expected the branch-head hash and stopped. GitHub’s Git objects confirm the branch head is the test merge’s second parent and that both have the identical complete tree `8f1f2c2838f57031e1939e2c1404ea2ea2dbe590`. All 94 signed source hashes and all 83 signed library hashes passed. The delivered 83 groups are byte-identical to the archive used on the two trial Macs. [Initial verification output](initial-identity-check.log) · [Verified Git trees, parents and compiled inventory](../build-103.json)

The game pack’s SHA-256 is `e4dfd14ccfa967a6d72fc46c5adcf809400449140118b650637c6370133e515d`. Both exports contain 908 resources. Of these, 882 have byte-identical payloads. The packaged train-car script differs in two ignored alignment bytes after the `Wheels` string. The 23 changed block-compressed texture imports retain their dimensions, format and mip counts. Decoding every mip found 19,839 different pixels among 78,293,667 in those imports (0.025%), with a maximum channel difference of 20/255. Two baked Vulkan cache entries also changed names. These differences are recorded alongside the SHA-256 hashes. The matched driver comparison within each release uses that release’s single PCK. [PCK member and decoded-texture comparison](game-pack-comparison.json)

## Comparison that selected the additional shaders

Two fresh hosted Macs each ran signed copies of the same player and PCK with the 319- and 365-stage inventories. On the host that ran the extended inventory first, Low Harlow’s worst entry fell from 1,221.532 to 18.199 ms and Low Warehouse A from 1,517.104 to 72.622 ms. On the other host the corresponding changes were 60.655 to 8.744 ms and 107.706 to 50.562 ms. Every traced route matrix still created 184 compute and 538 render pipelines. Source compilations fell from 46 to zero on both Macs.

The extended-first host still recorded 280.862 ms entering the High passenger car and 216.011 ms steady there on Medium. On this host steady p99 increased from 31.702 to 48.881 ms across all scenes. The other host improved from 55.126 to 36.577 ms. The evidence supports removing these observed source compilations and leaves a separate device/pipeline pacing problem open. [Every timing interval and both repeat passes](../build-99/entry-libraries/frames.csv) · [72 screenshot pairs and visual differences](../build-99/entry-libraries/README.md)

## Automated gameplay and export checks

The hosted run passed all 305 tests in 126.2 s. The separate local run used the same pinned Godot 4.5.1 source revision and passed all 305 in 135.3 s. The identity guard found all 305 distinct source tests. Four diagnostic-parser regressions and three shader-library delivery tests also passed locally. [Hosted results](raw/linux-tests.zip) · [Local logs, reports and pinned engine version](linux-local.zip)

The hosted macOS run passed 305/305 in 153.7 s. Its separate continuous route passed 167/167 checks with one Save/Continue and zero debug travel teleports. The fuel-shortage scenario passed 35/35, the stranded scenario 24/24 and fresh-process restore 17/17. The export host’s universal stock player passed 46/46 headless and 49/49 in a Vulkan window. [macOS suite, scenarios and restore evidence](raw/test-logs.zip) · [Export inventory, headless and windowed runs](raw/selftest-build.zip)

The independent Intel download passed 46/46 checks using the x86_64 slice headless. An explicit Metal request on Intel stopped before starting the engine. Intel GPU rendering remains unmeasured. [Intel self-test and backend selection](raw/selftest-x86_64.zip)

The independently downloaded Apple Silicon default Vulkan app also passed 46/46 headless and 49/49 windowed checks on this run. Its packaged diagnostics produced all 72 matrix phase rows. Build 99’s independent window lost the device after releasing cargo. Both outcomes remain in the record. [Independent Vulkan app and packaged diagnostic reports](raw/selftest-arm64.zip) · [Prior fresh failure](../build-99/fresh-vulkan-job.zip)

The final packaged sampler control reproduced one stock warning, zero corrected viewport warnings and one warning from an intentionally unsupported direct sampler. Each of the six corresponding images had the same decoded RGBA SHA-256 in all three processes. [Original warnings, 18 images and hashes](raw/metal-sampler.zip)

## Fresh Apple Silicon native player

A newly allocated macOS 26.7.2 arm64 host launched the normal native High player before other Godot workloads. Both launches reported `forward_plus/metal`, used system audio, reached play, recorded their first 30 gameplay frames and exited successfully. The warm start reused the player’s private save directory and shader cache. [Fresh native reports, launch logs, signposts and worker samples](raw/selftest-arm64-metal.zip)

| Selector-to-play measure | Cold | Warm |
|---|---:|---:|
| First script marker | 8.165 s | 4.383 s |
| Threaded mission resource load | 10.827 s | 6.847 s |
| First combined world and fog draw | 8.322 s | 7.332 s |
| First playable frame | **35.115 s** | **26.127 s** |
| Longest frame on loading/progress UI | 720.807 ms | 64.160 ms |
| Worst of first 30 playable frames | 29.382 ms | 18.100 ms |

The first launch used zero native source compilations. All 184 compute and 253 render pipeline creation intervals paired. Their elapsed unions were 4.762 and 2.687 s respectively. The longest render pipeline ran for 401.794 ms. The fresh source-only control on this same host took 77.038 s to play, using the existing writable cache after the two compiled launches. It exited cleanly. All six library-selection, source-preservation and fallback checks passed. The real loading UI advanced through four reported progress values on the first launch, with a 721 ms maximum frame gap. The unavailable hardware GPU timestamps leave transfer and GPU completion time unmeasured. [First-launch signpost totals](fresh-signposts.csv) · [Breakdown by shader](fresh-signposts-shaders.csv)

The independently downloaded Metal player also passed 49/49 rendering, gameplay and native-audio interactions. Its idle shutdown completed in 0.980 s. Three finite-queue shutdown trials with eight queued tasks each completed in 2.016, 1.721 and 1.852 s. All four exited without engine diagnostics. [Original audio and shutdown evidence](raw/selftest-arm64-metal.zip)

## Matched frame pacing across all 12 locations and three presets

Both renderers used the same build 103 PCK, host, fixed cameras, scene and fog state, 960×540 window and disabled V-sync. Two timing passes reversed the driver order. Entry and steady-state frames have separate distributions. Screenshot processes ran separately. All six timing and image processes completed with the requested backend and zero engine diagnostics. [All 36 locations and preset combinations](matched/README.md) · [Per-attempt CPU, draws, primitives, texture allocation and memory](matched/frames.csv) · [Complete logs, raw frame arrays and screenshot PNGs](raw/metal-drivers.zip)

| Driver and phase | Frames | Mean | Median | p95 | p99 | Worst | Over 33.3 / 50 / 100 ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| Metal entry | 4,320 | 8.612 ms | 7.163 ms | 14.933 ms | 30.753 ms | 237.189 ms | 38 / 17 / 8 |
| Vulkan entry | 4,320 | 12.368 ms | 10.161 ms | 22.805 ms | 56.981 ms | 155.445 ms | 96 / 53 / 11 |
| Metal steady | 12,960 | 7.649 ms | 6.923 ms | 13.082 ms | 17.317 ms | 58.834 ms | 7 / 1 / 0 |
| Vulkan steady | 12,960 | 11.822 ms | 10.215 ms | 20.510 ms | 40.120 ms | 142.521 ms | 184 / 86 / 5 |

Low Harlow and Warehouse A peaked at 21.932 and 53.856 ms on Metal. On Medium and High, Warehouse A still reached 135.153 and 179.721 ms. Approaching fog produced Metal’s longest entries on every preset, 155.282, 234.746 and 237.189 ms on Low, Medium and High. The worst steady intervals were Low Blackwater on Metal and Medium Ashford workshop on Vulkan. The earlier one-second Warehouse A outlier was absent from these two matched passes.

High Warehouse B steady p99 was 17.562 ms on Metal and 50.336 ms on Vulkan. High cab measured 22.862 / 23.051 ms, passenger car 23.591 / 19.809 ms, approaching fog 16.166 / 16.836 ms and dangerous fog 15.075 / 33.782 ms, in the same driver order. Peak process RSS in the timed passes ranged from 544.1–564.8 MiB on Metal and 469.0–532.4 MiB on Vulkan. Recorded texture memory was 290.8–361.4 and 289.9–360.3 MiB respectively. The virtual adapter returned no usable hardware GPU frame times. [Global distributions](matched/global.csv) · [All per-view values](matched/pooled.csv)

## Native stress and lifecycle

All 95 scheduled native processes completed cleanly, including 92 rendered runs and three headless isolation controls. Each native cold and warm preset completed. The three repeated preset/fog/Save/Continue scenarios, three exits during preparation and three station-entry sequences also passed. The original process logs contain zero sampler warnings, device losses, timeouts or resource-lifetime diagnostics. The three shader-seeding matrices peaked at 122.790 ms entry and 38.942 ms steady. The station-entry sequences peaked at 128.515 and 31.398 ms. [Every scenario and worst frame](metal-stress/STRESS.md) · [Individual processes](metal-stress/every-process.csv) · [Both startup clocks and target counts](startup-cohorts.csv)

| Native stress launches | Clean | Selector to play min / median / p95 / max (s) | Within target | Worst first 30 frames |
|---|---:|---:|---:|---:|
| High cold | 20/20 | 18.007 / 24.188 / 32.501 / 35.794 | 18/20 | 130.004 ms |
| High warm | 20/20 | 16.242 / 20.659 / 24.451 / 28.493 | 0/20 | 97.364 ms |
| Medium cold | 10/10 | 15.490 / 23.554 / 35.499 / 35.499 | 9/10 | 177.977 ms |
| Medium warm | 10/10 | 17.326 / 20.646 / 24.698 / 24.698 | 0/10 | 139.717 ms |
| Low cold | 10/10 | 15.532 / 23.705 / 40.675 / 40.675 | 9/10 | 104.743 ms |
| Low warm | 10/10 | 17.649 / 19.594 / 21.445 / 21.445 | 0/10 | 111.838 ms |

The diagnostic fixture met 30 s in 36/40 cold launches and 15 s in 0/40 warm launches. Each condition used an isolated application cache. Driver and OS caches persist on each host. The ordinary native High player on the separate fresh Mac took 35.115 and 26.127 s. [High shard](raw/metal-stress-high.zip) · [Low and Medium shard](raw/metal-stress-low-medium.zip) · [Mixed shard](raw/metal-stress-mixed.zip)

## Full packaged journey

The packaged `LastTrainOutMetal` player reported Forward+/Metal on Medium and passed all 167 checks. The continuous run scavenged Harlow supplies, carried and stored cargo, departed and traversed the curve, reached Ashford, recovered fuel and refueled under fog pursuit, reached Blackwater, saved and used Continue once, then escaped after 4,260.006 m. It preserved cargo without duplication. There were zero debug travel teleports and zero engine diagnostics. The separate 17-check fresh-process restore also exercised persisted state. [Route checks, real save, input driver and original stills](raw/metal-journey-diagnostics.zip)

The full H.264/AAC file is 960×540 and runs 23:30.417. Its 12 fps is the fixed offline Movie Maker rate. All 16,925 frames decoded, with zero all-black frames and zero isolated brightness pulses under the documented thresholds. The video SHA-256 is `6f418f125ce755b188edc7f6e3be5985594934a6fe55740d7d6053db93e663f9`. [Watch the film](../../../recording/milestone354-native-metal.mp4) · [Original workflow download](https://github.com/oiwdis/last-train-out/actions/runs/44822226233/artifacts/14677653047) · [Stream metadata](movie-streams.json) · [Decoded motion audit](movie-motion.json)

## Visual compatibility

The gallery pairs 53 captures at 960×540. Each pair has the native Metal frame on the left and the Vulkan frame on the right. The same cameras show the survivor’s face, hair, coat, hands, walking and carrying poses, locomotive wheels and connecting rods, cab gauges, windows, passenger interior, station surfaces and the two fog views. Both drivers drew the expected materials and geometry in these captures. The continuous native film also shows the changes in pose, lighting and fog during travel. Its frame audit detects full-frame blackouts and isolated brightness pulses. Fine shimmer on a physical fullscreen display remains an owner check. [Character poses and hands](gallery/character.jpg) · [Locomotive, interiors and stations](gallery/train-and-station.jpg) · [Unmodified art captures and poses](raw/metal-art.zip)

Lighting differs most on High outdoors. Mean image luma on the 0–255 scale was 102.714 on Metal and 92.312 on Vulkan at High Ashford. The freight yard measured 98.593 and 89.402, and the first-person hands view measured 88.923 and 83.137. The direction can reverse on other presets. Low Ashford measured 95.068 and 99.713, and the Medium curve measured 81.031 and 83.125. Fog remained visible on each preset. These comparisons document the difference at the shipped settings. No preset, material or detailed model was lowered for this build. [Low](gallery/low.jpg) · [Medium](gallery/medium.jpg) · [High](gallery/high.jpg) · [All 53 pixel comparisons](gallery/pixel-comparison.csv) · [Original route frames](raw/metal-drivers.zip)

## Vulkan device-loss investigation

All 95 Vulkan stress processes started. Of those, 85 completed cleanly and ten lost the GPU. All 40 warm launches, 20 cold Low and Medium launches and 15 lifecycle processes completed. Native Metal completed the same 95-process schedule cleanly. Each schedule included three headless controls. [Vulkan scenario table](vulkan-stress/STRESS.md) · [All Vulkan processes](vulkan-stress/every-process.csv) · [Low and Medium logs](raw/release-stress-low-medium.zip)

Ten of the 20 cold High stress launches lost the GPU. Nine logged the completed platform preparation view as their last phase, and one logged the combined world/fog preparation view. Each failed process recorded a MoltenVK command-buffer submit timeout and presentation timeout, the Metal callback `kIOGPUCommandBufferCallbackErrorTimeout`, a failed Godot fence wait and SIGTRAP. The reports identify the failing synchronization point. The virtual device did not expose the individual GPU command responsible. Observed process RSS for these ten failures ranged from 397.8 to 483.1 MiB. The ten successful High starts ranged from 451.2 to 490.3 MiB. Those overlapping process-memory measurements cannot identify GPU allocation pressure. All 20 warm High launches completed. [Ten original failure records](device-losses.csv) · [Eight crash reports and logs from the High shard](raw/release-stress-high.zip) · [Two crash reports and logs from the mixed shard](raw/release-stress-mixed.zip)

One successful cold Vulkan High launch on the High shard (`cold-1`) recorded 1,012.648 ms on frame 15 of its first 30 playable frames. This separate launch fixture captured a larger freeze than the matched route matrix. The preceding build also lost a Vulkan device during the fresh windowed gameplay check. Its logs and the earlier active preset/fog failure remain part of the release decision. [First-window intervals and attempts](startup/first-frames.csv) · [Build 99 fresh gameplay failure](../build-99/fresh-vulkan-job.zip) · [Original device-loss investigation](../../../RENDERER_CRASH_INVESTIGATION.md)

## Startup controls

Two independently provisioned Macs reversed the order of the High startup fixtures. All 11 processes on each Mac passed. The earlier 3.5.3 stock control reported mission readiness at 78.590 and 151.767 s cold, and 15.389 and 27.594 s warm, on those same hosts. Its clock starts inside Godot. The current selector-to-play clock also includes setup before Godot starts. Seeding helped both cold starts. Warm local starts were faster than seeded starts on both hosts. [Seed-first host](raw/metal-seed-first.zip) · [Local-first host](raw/metal-local-first.zip) · [Every startup phase](startup/startup-phases.csv)

| High startup control | Seed-first Mac | Local-first Mac |
|---|---:|---:|
| Cold seeded / locally compiled | 18.513 / 56.495 s | 34.525 / 114.736 s |
| Warm seeded / locally compiled | 16.588 / 15.999 s | 37.328 / 29.893 s |
| Original-position / platform fog preparation, selector to play | 17.252 / 15.107 s | 27.103 / 26.837 s |
| Ordinary loading scene, first / second launch after the other controls | 19.424 / 20.463 s | 31.750 / 32.486 s |

Seven packaged Metal library-policy controls completed on one host. Godot’s immediate policy reached High gameplay in 82.962 s cold and 27.328 s warm. The shipped first-use policy took 32.745 and 25.475 s. Each cold startup logged the same 94 source groups installed and 76 bundled-group loads. The separate, OS-cache-conditioned immediate trace reached play in 25.201 s and recorded 194 shader compilation intervals plus 184 compute and 253 render pipeline creations. Its aggregate timings differ from the earlier cold process. [All seven processes, timings and original signposts](raw/metal-library-policy.zip) · [Paired timing intervals](policy-signposts.csv)

The complete first-use policy matrix reached 205.119 ms entering High approaching fog and 91.626 ms steady in the Low cab. Immediate creation peaked at 183.478 ms on High Warehouse A entry and 61.858 ms steady at that same view. Selecting immediate creation would therefore impose a measured cold-start penalty while still leaving entries above 100 ms. [Per-view measurements and frame arrays](raw/metal-library-policy.zip)

## Source-project comparison against Milestone 3.5

A separate macOS 26.7.2 arm64 runner compared source revisions `7df2f5abee54b8adcf27b8668263fba231a79033` and `48fe07d96e95d8a6bea7e3e9e249d0d0b085d09c` on Vulkan with identical diagnostic code and 960×540 windows. It used separate project and user caches and shared OS/driver caches. Mission-ready times on the three baseline starts were 122.400, 37.151 and 28.583 s. The corresponding current starts took 33.989, 29.359 and 28.215 s. The first baseline start and matrix logged MoltenVK pipeline-cache write diagnostics. The three current starts and two current matrices exited without engine diagnostics. [All source process logs and JSON](raw/source-performance.zip) · [Original workflow artifact with the separate Vulkan movie](https://github.com/oiwdis/last-train-out/actions/runs/44822226233/artifacts/14677229410)

The table shows the maximum frame across three presets and both passes for each location. Entry windows contained 4,320 frames in total for each revision. Steady windows contained 43,200 per revision. The current High Blackwater entry, approaching-fog entry and passenger-car entry all regressed in this comparison. The per-view table includes the distribution and every threshold count. [Every preset and location, mean through maximum](source-vulkan-before-after.csv)

| Source Vulkan view | Baseline worst entry / steady (ms) | Current worst entry / steady (ms) |
|---|---:|---:|
| Harlow platform | 3,961.085 / 77.696 | 87.843 / 54.561 |
| Warehouse B | 58.220 / 138.280 | 29.689 / 78.091 |
| Locomotive cab | 58.959 / 86.136 | 58.991 / 70.567 |
| Passenger car | 114.687 / 79.320 | 118.333 / 53.568 |
| Approaching fog | 89.265 / 103.273 | 118.389 / 103.078 |
| Inside dangerous fog | 38.833 / 102.719 | 32.060 / 84.006 |
| Blackwater Crossing | 57.413 / 85.201 | 754.869 / 59.894 |

Across all 12 locations, the worst entry fell from 3,961.085 ms at High Harlow to 754.869 ms at High Blackwater, and the worst steady interval fell from 401.252 ms on the Medium curve to 103.078 ms on Low approaching fog. The number of frames over 100 ms fell from 13 to eight on entry and from seven to one during steady rendering. The source Vulkan journey also passed 167/167 checks with one Save/Continue and zero debug travel teleports.

## Release decision

**Hold the merge and retain the existing Vulkan default.** The opt-in native Metal player is the first choice for testing the physical 2020 M1. It completed all 95 stress processes, fixed the reproducible viewport warning, completed the full journey and substantially improved steady frame times on the hosted adapter. The ordinary native player missed both startup targets, its cold loading UI paused for 721 ms and the final driver comparison still recorded a 237 ms fog entry. A default change needs physical fullscreen timings, an acceptable loading and entry experience, and explicit owner approval. The launcher selects a backend before engine initialization. Quit the game to switch drivers. [Physical test, camera checks and log collection](../../../M1_MILESTONE354.md)

The release workflow finished with 18 successful jobs and two failed Vulkan stress jobs. The optional investigation-only and Developer ID signing jobs did not run. Linux, macOS, both fresh Apple Silicon windows, Intel headless, the native recording and all native stress jobs passed. The development ZIP is available for evaluation under its verified digest. [Final workflow jobs and artifact digests](workflow.json) · [GitHub Actions](https://github.com/oiwdis/last-train-out/actions/runs/44822226233)
