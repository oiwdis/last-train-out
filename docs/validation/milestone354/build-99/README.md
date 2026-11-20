# Build 99 release evidence

The downloadable development build was exported from `a7a4c1a7c828199aef0c5d37d109f2d919a99e7c`. Both the universal main executable and the universal selector contain arm64 and x86_64 slices. The additional native Metal player is arm64. Both players read the same game pack. The Mac export job used Godot 4.5.1. The build host identified macOS 26.7.2, an Apple M2 Pro (Virtual) CPU and an Apple Paravirtual GPU. The owner’s physical 2020 M1 results are pending. [Universal ZIP](https://github.com/oiwdis/last-train-out/actions/runs/44804764620/artifacts/14666253056) · [GitHub Actions run](https://github.com/oiwdis/last-train-out/actions/runs/44804764620)

| Download or component | SHA-256 |
|---|---|
| LastTrainOut-macos-universal.zip, 330,035,528 bytes | `a49497c51f951f52524743afd878463f0dc08959ca1a411f5c2854a04bdd71d5` |
| Shared game PCK | `3076fc36e0dd8cf2bd33c1e18e276c12ceb0d5060260bca73d11c4e1a0774474` |
| Native Metal executable, compiled and ad-hoc signed with Xcode 26.6 | `bc06ab5d56e536bd1c6ad8dabaf226109ce841bf7273ae6ef0f1b91e4c292a04` |

After an independent download, ZIP CRC, executable modes, Mach-O slices, game-pack hash and all 94 source and 79 precompiled group hashes were checked. The receipt also identifies the source GPU family, argument-buffer tier and Metal language version. The development app is ad-hoc signed. [Verified receipt](../build-99.json) · [ZIP checks](../build-99-zip.log) · [Compiler log and three engine-patch hashes](template-provenance.zip)

## Gameplay tests

| Check | Result | Evidence |
|---|---|---|
| Hosted Linux, Godot 4.5.1 | 305/305, 108.3 s | [Suite and individual test IDs](raw/linux-tests.zip) |
| Hosted macOS, Godot 4.5.1 | 305/305, 99.4 s | [Suite, route and resume reports](raw/test-logs.zip) |
| Separate local Linux run, pinned Godot 4.5.1 | 305/305, 137.0 s. Original-ID guard, four diagnostic-parser tests and three library-delivery tests passed. | [Raw logs and local version check](linux-local.zip) |
| macOS source run | 167/167 continuous escape, 35/35 fuel-shortage checks, 24/24 stranded checks and 17/17 fresh-process restore checks | [Full scenario reports and logs](raw/test-logs.zip) |
| Export host running the packaged app | 46/46 headless and 49/49 in a Vulkan window | [Bundle self-tests and export inventory](raw/selftest-build.zip) |
| Independently downloaded Apple Silicon native Metal app | Both ordinary High launches, 6/6 library-selection and fallback checks, 49/49 native-audio interactions, idle shutdown and three queued shutdown trials passed. | [All launch, cache and exit records](raw/selftest-arm64-metal.zip) |
| Independently downloaded Apple Silicon default app | 46/46 headless. The Vulkan window lost its device and exited with code 133 after it released physical cargo at 98.149 s. | [Window and headless logs](raw/selftest-arm64.zip) · [Original Actions job output](fresh-vulkan-job.zip) |
| Independently downloaded Intel app | 46/46 x86_64 headless. Explicit native Metal selection on Intel exited before launch. | [Intel report and selector output](raw/selftest-x86_64.zip) |

The ZIP includes the engine. Developer ID signing, notarization and a physical Intel GPU were outside the measured build. [Physical M1 procedure](../../../M1_MILESTONE354.md)


## Character, train and environment

The 17 authored comparison views used identical pose transforms, resolution, lighting selection and High preset on both drivers. Skin and hair, clothing, running and carrying poses, both first-person hands, the moving wheel gear, cab gauges and carriage windows render on each path. The platform and distant freight yard are visibly brighter on Metal. [Character and hands](gallery/character.jpg) · [Train, warehouses and station](gallery/train-and-station.jpg) · [Original PNGs and camera transforms](raw/metal-art.zip)

## Ordinary native startup

These fresh Apple Silicon jobs each launched the normal High player before any other Godot process. The warm launch reused its writable cache. The two builds ran on independently allocated hosts. Build 99’s source-only fallback then used the same save directory and writable cache as its two precompiled launches.

| Process-to-gameplay measure | Build 93 source cold / warm | Build 99 precompiled cold / warm |
|---|---:|---:|
| First script marker | 42.153 / 5.468 s | 8.846 / 4.502 s |
| Threaded mission resource load | 25.010 / 6.422 s | 8.926 / 7.234 s |
| First combined fog and world preparation draw | 28.755 / 8.891 s | 7.315 / 7.083 s |
| First playable frame | 105.046 / 29.365 s | 33.137 / 26.620 s |
| Worst interval while the progress screen was visible | 1,081.816 / 165.735 ms | 335.786 / 86.074 ms |
| Worst of the first 30 playable frames | 125.373 / 47.439 ms | 42.794 / 61.603 ms |

Build 99’s trace paired every first-launch creation interval and found zero source compilations, 184 compute pipeline creations and 253 render pipeline creations. The compute and render intervals covered 6.725 and 2.372 seconds respectively. Switching that same Mac to the source-only fallback reached play in 116.982 s and exited cleanly. It was the first launch using the source-only strategy on that host. The 79 precompiled groups stayed in the signed bundle. All corresponding writable source groups retained their signed source hashes. [Native signpost totals](fresh-signposts.csv) · [Fresh reports, fallback checks and original logs](raw/selftest-arm64-metal.zip) · [Build 93 source control](../build-93/README.md)

In two further counterbalanced startup jobs, the cold diagnostic fixture measured 19.305 and 27.600 s with the signed shader inventory, versus 65.715 and 99.218 s with local shader preparation. On warm runs the two strategies measured 16.479 / 17.680 s on one host and 24.860 / 21.392 s on the other. All 22 processes completed, including the original PCK, both preparation cameras and six normal player entries. [Signed inventory first](raw/metal-seed-first.zip) · [Local shader preparation first](raw/metal-local-first.zip)

## Where the long entry frames waited

A separate fresh Mac ran the actual build 99 player with timestamped stage markers, native Metal signposts and one-second Apple thread samples. All 72 stage markers were observed. The trace paired all shader and pipeline intervals. Clock alignment used the stage-file write and the game tick on that same host, with 3.65 ms of allowance. The fixture waits for the production scene and preset preparation, places a fixed camera at each location, and measures the next frames. The continuous journey uses ordinary player movement. [Capture and four native stacks](raw/warehouse-metal-entry.zip) · [Alignment and per-stage results](warehouse-entry) · [Capture tool](../../../../tools/macos/profile_metal_entry.py)

The third Low Warehouse A entry frame took 1,210.421 ms, including 1,209.431 ms between render callbacks. The native sample began about 287 ms into that frame. In 79 of 102 main-thread observations, Godot was in `RenderingDevice::_stall_for_frame` waiting on `RenderingDeviceDriverMetal::fence_wait`. A 2,742 ms clustered render-pipeline creation ended about 111 ms into the frame. A source compilation ended about 3 ms before its start, inside the alignment margin. GPU completion and the virtual host’s scheduling remain unmeasured. The Low cab’s 207.314 ms steady outlier overlapped no signposted source or pipeline creation. [Per-phase intervals and create calls](warehouse-entry/entry-phases.csv) · [Main-thread sample counts](warehouse-entry/native-stacks.csv)

The first Low Harlow platform frame above a second took 1,278.170 ms. Two clustered fragment source compilations lasting 1,317 and 1,367 ms overlapped that interval, as did multiple native render-pipeline creations. The sampled matrix invoked 46 source stages outside the 319 used at High startup. All 46 mapped uniquely to the signed source inventory. Godot’s three per-frame pipeline counters stayed flat during the sampled Low platform and warehouse windows despite the native activity. The unprofiled second matrix on that host peaked at 129.174 ms near advancing fog and 128.317 ms on High Warehouse A entry. [Native trace and both complete matrices](raw/warehouse-metal-entry.zip)

The packaged library-policy control independently measured a 1,034.041 ms third Low Warehouse A frame and a 633.119 ms steady Low Harlow frame on the default first-use policy. The subsequent immediate-policy matrix peaked at 139.751 ms on High Warehouse A entry and 54.883 ms steady inside dangerous fog. On that host High startup took 86.109 s cold and 34.451 s warm with immediate library creation, versus 29.403 and 28.914 s with first use. Each matrix logged 92 loads from the 79 read-only groups, including repeat uses. All seven processes completed. The order and shared driver cache limit causal interpretation of the matrix difference. [Seven original trials and signposts](raw/metal-library-policy.zip)

Apple subsequently compiled the 46 observed stages and compared the two inventories on two fresh hosts. Low Warehouse A and Harlow first-use frames improved in both orders. Remaining long passenger-car frames and all repeat passes are retained. [Two-host extension decision](entry-libraries/README.md)

## Ordinary player comparison on two Macs

Each host ran 12 normal players with system audio and the same exported PCK in a 960×540 window. The first driver was reversed between hosts. Each preset and driver started with a private empty application cache, then reused it for its warm launch. macOS and driver caches persisted between launches. The selector timed every result through the first playable frame. Both hosts reported macOS 26.7.2 on arm64. [Per-process times, diagnostics and exits](paired-ordinary-launches.csv) · [Metal-first raw records](raw/players-metal-first.zip) · [Vulkan-first raw records](raw/players-vulkan-first.zip)

| Preset and cache | Metal on Metal-first host | Vulkan on Metal-first host | Metal on Vulkan-first host | Vulkan on Vulkan-first host |
|---|---:|---:|---:|---:|
| High cold | 38.666 s | 58.050 s, shutdown timeout | 36.599 s | 79.721 s, shutdown timeout |
| High warm | 27.427 s | 29.359 s | 27.049 s | 26.175 s |
| Medium cold | 23.535 s | 21.160 s | 30.546 s | 22.134 s |
| Medium warm | 23.229 s | 20.314 s | 26.064 s | 20.250 s |
| Low cold | 32.318 s | 31.919 s | 39.944 s | 32.444 s |
| Low warm | 29.879 s | 20.399 s | 27.570 s | 22.120 s |

All 12 native players and 10 of the 12 Vulkan players exited cleanly. The two cold High Vulkan processes reached play with first-window frame maxima of 152.753 and 151.154 ms, wrote their reports and remained alive until the 300 s process deadline. Each of the four Apple samples taken 12 or 45 s after its report showed `WorkerThreadPool::exit_languages_threads` on the main thread. The original Vulkan executable still uses the stock worker pool. These two attempts had zero device-loss messages. The separate fresh-download Vulkan test reported a GPU device loss. [Comparison run with both failed jobs](https://github.com/oiwdis/last-train-out/actions/runs/44815138847) · [Matched worker fixture with original and corrected pools](../../../PERFORMANCE_MILESTONE354.md#why-the-cold-process-stayed-open)

## Stress and lifecycle

All 95 scheduled native processes completed cleanly. The 92 rendered processes identified `forward_plus/metal` and the packaged native executable. Three headless isolation preflights used the stock executable. There were zero device losses, timeouts, skipped processes or engine diagnostics, including zero sampler and resource-lifetime warnings. Three repeated preset/fog/Save/Continue scenarios, three exits during preparation and three station-entry sequences completed. [Native scenario ledger](metal-stress/STRESS.md) · [Every native process](metal-stress/every-process.csv) · [Selector and engine clocks](startup-cohorts.csv)

| Native stress fixture | Clean | Selector to playable min / median / p95 / max (s) | Under 30 s cold or 15 s warm | Worst first 30 frames |
|---|---:|---:|---:|---:|
| High cold | 20/20 | 16.56 / 19.19 / 22.82 / 24.16 | 20/20 | 103.792 ms |
| High warm | 20/20 | 14.95 / 18.16 / 21.25 / 21.69 | 1/20 | 91.140 ms |
| Medium cold | 10/10 | 18.12 / 21.43 / 28.66 / 28.66 | 10/10 | 118.456 ms |
| Medium warm | 10/10 | 16.21 / 17.81 / 21.32 / 21.32 | 0/10 | 67.707 ms |
| Low cold | 10/10 | 17.80 / 20.01 / 36.58 / 36.58 | 8/10 | 71.119 ms |
| Low warm | 10/10 | 15.13 / 16.60 / 20.26 / 20.26 | 0/10 | 118.779 ms |

Each shard used a fresh Mac and had its own startup and driver-cache history. The stress fixture reached play in under 30 s in 38/40 cold cases and under 15 s in 1/40 warm cases. Separate ordinary native High players took 33–39 s cold. In one of the three stress matrices, Low Warehouse A entry reached 322.890 ms and Low Harlow steady rendering reached 424.511 ms. The three station-entry processes peaked at 129.453 ms entry and 42.282 ms steady. [High raw logs](raw/metal-stress-high.zip) · [Low and Medium](raw/metal-stress-low-medium.zip) · [Mixed and lifecycle](raw/metal-stress-mixed.zip)

The default Vulkan release gate completed 87/95 cleanly. Eight of its 20 cold High launches lost the device. All 20 warm High, 40 Low/Medium and 15 lifecycle or isolation processes passed. Each failure produced a native crash report, MoltenVK submit and presentation timeouts with `kIOGPUCommandBufferCallbackErrorTimeout`, a failed Godot `fence_wait` and a trap. The last completed preparation marker was the platform in seven attempts and the fog material in one. Those markers do not identify the failing GPU command. The separate fresh-download window also lost its device after releasing cargo. The matched ordinary cold High Vulkan processes reached play, then hung in the stock worker-pool exit barrier. [All eight individual failures](vulkan-device-losses.csv) · [Raw logs and eight macOS crash reports](raw/release-stress-high.zip) · [Vulkan scenario ledger](vulkan-stress/STRESS.md) · [All three cohorts’ startup and frame distributions](startup)

## Frame pacing and rendered output

Two matched timing passes on one hosted Apple Silicon GPU reversed the driver order. Each driver supplied 4,320 entry frames and 12,960 steady frames across the same 36 views. The first-use trace above ran on a different fresh host. Both sets of observations count toward the acceptance decision. [All 12 locations on Low, Medium and High](matched/README.md) · [Raw frame arrays and screenshots](raw/metal-drivers.zip)

| Driver and interval | Mean | Median | p95 | p99 | Worst | Frames over 33.3 / 50 / 100 ms |
|---|---:|---:|---:|---:|---:|---:|
| Metal entry | 4.954 ms | 4.493 ms | 7.743 ms | 11.526 ms | 99.149 ms | 14 / 4 / 0 |
| Vulkan entry | 6.260 ms | 5.748 ms | 9.888 ms | 12.894 ms | 79.770 ms | 5 / 2 / 0 |
| Metal steady | 4.785 ms | 4.410 ms | 7.793 ms | 10.368 ms | 42.623 ms | 20 / 0 / 0 |
| Vulkan steady | 6.143 ms | 5.707 ms | 9.450 ms | 11.008 ms | 21.309 ms | 0 / 0 / 0 |

In the two timed passes, Metal used 575.7–576.7 MiB peak RSS and Vulkan used 544.1–549.0 MiB. Average render CPU time per location and phase ranged from 0.331–1.287 ms on Metal and 0.307–1.386 ms on Vulkan. Draw-call averages ranged from 121–1,182 on Metal and 122–1,181 on Vulkan. The virtual adapter returned no usable GPU frame-time samples. The Medium curve produced Metal’s worst steady frame. High Warehouse A produced each driver’s worst entry in this run. High Warehouse B steady p99 was 15.4 ms on Metal and 11.7 ms on Vulkan. [Per-attempt CPU, triangles, draw calls, texture memory and RSS](matched/frames.csv)

Both renderers showed the warehouse contents, cab instruments, carriage windows, curve, approaching fog, dangerous fog and mission results. High Metal was visibly brighter outdoors, especially at Ashford and Blackwater. High Ashford averaged 97.90 versus 88.30 luma units on the 0–255 scale. Medium dangerous fog and the results screen closely matched. Low approaching fog was darker on Metal. Each gallery pair has the same camera, preset, view and target resolution. [Low](gallery/low.jpg) · [Medium](gallery/medium.jpg) · [High](gallery/high.jpg) · [All 53 pixel comparisons](gallery/pixel-comparison.csv)

## Complete Metal journey and sampler controls

The packaged native executable reported `forward_plus/metal` and passed all 167 checks. It escaped after 4,260.006 m through Harlow, Ashford and Blackwater. The input driver used ordinary movement, carrying, train controls and interactions, with zero travel teleports. The one legitimate Blackwater Save/Continue restored the rider and cargo. The log contains zero engine diagnostics. The 960×540 H.264 recording includes AAC audio, runs 23:30.417 and contains 16,925 frames at an offline Movie Maker rate of 12 fps. Decoding the full file found zero all-black frames or one-frame brightness pulses under the recorded thresholds. Smaller flicker requires comparison during play. [Full build 99 film](https://github.com/oiwdis/last-train-out/blob/48fe07d96e95d8a6bea7e3e9e249d0d0b085d09c/docs/recording/milestone354-native-metal.mp4) · [Original route report, input driver, save and stills](raw/metal-journey-diagnostics.zip) · [Stream metadata](movie-streams.json) · [Motion audit and SHA-256](movie-motion.json)

The build 99 sampler regression reproduced one viewport warning with stock Metal, zero with the patched viewport and one with an explicitly invalid sampler. The six corresponding draws matched in all three cases. [Original logs and 18 rendered controls](raw/metal-sampler.zip)

## Source Vulkan comparison with the original integration

The release workflow also compared `7df2f5abee54b8adcf27b8668263fba231a79033` and the build 99 game revision with the same Godot editor, diagnostic script, 960×540 window and five-core hosted Mac. Both revisions used Forward+/Vulkan. Each view contributed 120 entry and 1,200 steady frames across two passes. The first mission-ready marker fell from 55.038 to 16.888 s on this host. The two repeat values were 18.934 and 21.435 s on the baseline, and 13.047 and 14.482 s on the candidate. These clocks start inside the engine. [Both revisions, all 36 views](source-vulkan-before-after.csv) · [Original process logs, frame arrays and source journey](raw/source-performance.zip) · [Workflow artifact including the source film](https://github.com/oiwdis/last-train-out/actions/runs/44804764620/artifacts/14671571651)

| Measurement | Original integration | Build 99 revision |
|---|---:|---:|
| Worst entry, any location or preset | 1,846.242 ms, High Harlow platform | 81.152 ms, High Warehouse A |
| Worst steady frame | 16.903 ms, Medium Warehouse A | 17.628 ms, High locomotive cab |
| High Warehouse B steady p99 | 10.241 ms | 10.715 ms |
| High cab steady p99 | 11.254 ms | 11.401 ms |
| High passenger car steady p99 | 10.904 ms | 11.263 ms |
| High approaching fog steady p99 | 10.990 ms | 8.617 ms |
| High dangerous fog steady p99 | 11.690 ms | 9.124 ms |

The first baseline startup and first baseline matrix emitted MoltenVK `VK_INCOMPLETE` pipeline-cache write errors. All ten processes returned zero. The five candidate processes recorded zero engine diagnostics. The fresh-download Vulkan device loss and both ordinary Vulkan shutdown failures remain separate acceptance failures.
