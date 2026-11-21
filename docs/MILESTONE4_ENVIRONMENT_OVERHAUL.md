# Milestone 4 environment overhaul

Milestone 4 is stacked on the open, unmerged PR #6 at `684df38f0d9ba39a876d4788696855f0b64d5b29`. PR #7 targets `integration/milestone-3-5-photoreal-survival`. The route, rolling stock, survival simulation, save format and renderer selection come from that integration. [Development PR #7](https://github.com/oiwdis/last-train-out/pull/7) · [Integration PR #6](https://github.com/oiwdis/last-train-out/pull/6) · [Renderer history](PERFORMANCE_MILESTONE354.md)

## Development build 111

**Keep both PRs in draft.** Native Metal rendered the repaired terrain at every preset and completed the 4.26 km journey. The default Vulkan player again lost its device on cold High starts, and an independent native Metal High launch crashed during pipeline creation. Build 111 is available for the owner’s Medium evaluation. [Native failure and correction](validation/milestone4/build-111-native-high/README.md) Startup is slower than the integration baseline, and the owner’s physical 2020 M1 has yet to verify fullscreen Medium. [Matched native gallery](validation/milestone4/GALLERY.md) · [All measured views](validation/milestone4/FRAME_TIMES.md) · [Continuous native journey](recording/milestone4-native-metal.mp4)

The downloadable game comes from branch `feature/milestone-4-environment-overhaul` at `6c8a3248fa7d5390c3a71fdbfbba5674a1a3b952`. The workflow packaged PR test-merge `2dc2fcb41b9725bc83bf6aecb4760c76a0df9f1e`. Its Git tree matches the branch commit exactly. The independent download verified the archive CRC, universal arm64 and x86_64 runtime and selector, arm64 native Metal runtime, signed shader inventories, and 941 PCK entries. The pack contains all 385 checked project resources plus the explicitly verified corridor and environment assets. The development bundle is ad-hoc signed. [Download LastTrainOut-macos-universal.zip](https://github.com/oiwdis/last-train-out/actions/runs/44859769512/artifacts/14689604118) · [Build receipt](validation/milestone4/development-build.json) · [ZIP check](validation/milestone4/zip-verification.log)

| Download | Size | SHA-256 |
|---|---:|---|
| LastTrainOut-macos-universal.zip | 340,821,630 bytes | `527af2233d5cb88ea444aded3c7d40b13f3a2176a52bd20d5c5ffb48f5df538a` |

The compatible macOS 26 Apple5 profile contains 97 source groups and 86 matching read-only library groups. Before offline preparation, the 16-view world replay emitted 30 source-compile intervals for 28 unique stages. They occupied 5.19 seconds across overlapping workers. A fresh game cache after preparation recorded zero source compilations and created all 558 render pipelines observed in the first pass. Creation occupied 8.26 seconds before and 0.85 seconds after, on the same build machine with shared OS driver caches. This check verifies stage coverage. Ordinary cold and warm launch measurements use separate processes. [World signposts and compiler receipts](validation/milestone4/world-stage-preparation.zip) · [Stage counts](validation/milestone4/world-stage-preparation.json) · [Changes to individual signed groups](validation/milestone4/shader-groups.json)

## Frame pacing and startup on native Metal

Each pair gives the PR #6 build 104 result followed by Milestone 4 build 111. Both ran on the same hosted Apple paravirtual GPU at 960 × 540. Each preset contributes 5,760 steady and 1,920 entry intervals per build. The tables include every interval. GPU timestamp counters were unavailable on this adapter.

| Preset | Steady median (ms) | p95 (ms) | p99 (ms) | Worst (ms) | Worst entry (ms) | Steady frames >33.3 ms | Entry frames >100 ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| Low | 2.7 / 2.7 | 3.8 / 4.2 | 4.3 / 5.0 | 13.0 / 6.3 | 44.2 / 25.1 | 0 / 0 | 0 / 0 |
| Medium | 3.7 / 3.8 | 5.9 / 5.6 | 7.5 / 6.1 | 8.9 / 7.5 | 31.7 / 39.2 | 0 / 0 | 0 / 0 |
| High | 4.8 / 3.7 | 7.7 / 5.6 | 9.3 / 6.2 | 12.1 / 7.2 | 288.9 / 247.9 | 0 / 0 | 2 / 1 |

| Medium location | Steady p95 (ms) | Steady p99 (ms) | Worst entry (ms) | Mean draw calls | Mean render CPU (ms) |
|---|---:|---:|---:|---:|---:|
| Harlow track | 5.3 / 5.8 | 5.6 / 6.3 | 15.7 / 17.4 | 952 / 971 | 0.73 / 0.75 |
| Bonded Stores interior | 3.8 / 4.8 | 3.9 / 5.4 | 8.2 / 8.9 | 384 / 407 | 0.45 / 0.47 |
| Curved embankment | 4.8 / 5.6 | 5.6 / 6.0 | 7.4 / 16.5 | 286 / 289 | 0.45 / 0.49 |
| Warehouse B | 3.6 / 5.2 | 3.8 / 5.5 | 4.9 / 5.6 | 460 / 475 | 0.46 / 0.57 |
| Locomotive cab | 8.0 / 5.7 | 8.5 / 6.1 | 31.7 / 39.2 | 985 / 1004 | 0.91 / 0.75 |
| Passenger car | 6.8 / 6.3 | 8.1 / 6.7 | 9.3 / 7.6 | 1110 / 1126 | 0.93 / 0.86 |
| Ashford Depot | 4.4 / 5.4 | 4.8 / 6.1 | 5.9 / 6.2 | 159 / 222 | 0.39 / 0.46 |
| Blackwater Crossing | 4.7 / 4.6 | 5.0 / 4.9 | 5.6 / 9.0 | 173 / 229 | 0.41 / 0.44 |
| Distant fog | 6.2 / 3.5 | 7.1 / 3.7 | 7.0 / 6.2 | 320 / 336 | 0.52 / 0.40 |
| Near advancing fog | 5.5 / 3.7 | 6.2 / 4.0 | 8.8 / 4.3 | 319 / 334 | 0.55 / 0.41 |
| Inside dangerous fog | 4.4 / 3.4 | 4.6 / 3.5 | 4.8 / 3.9 | 315 / 333 | 0.50 / 0.39 |

| Matched selector-to-play time | Cold (s) | Warm (s) | Cold threaded loading (s) |
|---|---:|---:|---:|
| Low | 24.23 / 27.25 | 21.91 / 27.17 | 5.89 / 8.80 |
| Medium | 20.76 / 28.10 | 18.94 / 24.78 | 5.57 / 8.77 |
| High | 19.91 / 25.23 | 20.39 / 24.99 | 5.04 / 8.59 |

[All 16 views on all three presets](validation/milestone4/FRAME_TIMES.md) · [Complete distributions, FPS, draw calls, triangles and memory](validation/milestone4/locations.csv) · [All frames above 50 ms and their callbacks](validation/milestone4/slow-frames.csv) · [Raw paired runs](validation/milestone4/raw-environment.zip)

Medium’s pooled p95 was 5.87 ms on the integration and 5.57 ms on the overhaul. Inside dangerous fog it was 4.41 and 3.44 ms respectively. All 5,760 steady Medium intervals on each build finished below 33.3 ms. Warehouse B rose from 3.61 to 5.16 ms p95, and Ashford workshop rose from 4.36 to 5.64 ms. In the workshop the mean draw count grew from 192 to 255 and submitted primitives from 131,000 to 281,000. The geometry remains visible in the corresponding gallery panels.

The worst candidate interval was the first High Harlow platform frame in the repeat, at 247.94 ms. The render callbacks bracketed 246.29 ms. Gameplay processing occupied 0.14 ms and the sampled window recorded zero new draw, surface or specialization pipelines. The reference repeat recorded 288.90 ms at the same point. The first candidate pass recorded 97.21 ms there. The render callback interval includes waiting and submission. The GPU timestamps needed to identify the exact work inside it were unavailable.

Peak process RSS was 587.3 and 551.8 MiB in the first and repeat reference runs, and 651.7 and 597.8 MiB in the corresponding candidate runs. Medium’s texture counter rose by 4.13 MiB. The benchmark host was faster on both packs than the earlier build 108 host. Results from different runners are reported in their own tables. On the matched host all three presets reached play later with the new world. Medium’s 7.34 s cold increase includes 3.20 s more threaded resource loading. [Process RSS and scene preparation](validation/milestone4/runs.json) · [Native screenshots](validation/milestone4/GALLERY.md)

### Fresh High player launches

These are unmodified downloads on three separate hosted Macs. Each cold launch starts the bundled Metal executable on a fresh runner with native audio and a 960 × 540 window. Its warm launch keeps that app’s private cache. The first scene draw includes the fog proxy and surrounding world. Different hosts and launch order limit comparisons of wall time.

| Build | Cold playable (s) | Warm playable (s) | Threaded load, cold / warm (s) | First fog and world draws, cold / warm (s) | Native cold source compiles |
|---|---:|---:|---:|---:|---:|
| PR #6 build 104 | 37.85 | 28.36 | 8.15 / 6.76 | 11.12 / 8.24 | 0 |
| Rejected build 108 | 56.42 | 39.15 | 18.82 / 12.84 | 18.57 / 9.92 | 24 |
| Milestone 4 build 111 | 48.75 | 44.70 | 12.48 / 11.82 | 13.70 / 13.64 | 0 |

The 184 compute pipeline creations occupied 6.29 s of the candidate’s cold launch. Its 266 render pipeline creations occupied 3.38 s across overlapping threads, close to the original 3.44 s and down from 14.63 s in build 108. The cold journey setup phase grew from 0.31 s on the integration to 2.40 s. Its first 30 playable frames peaked at 34.78 ms cold and 54.00 ms warm. Startup remains a cost of the overhaul. [Ordinary launches, phases and native signposts](validation/milestone4/fresh-player-startup.json) · [Build 111 native launch logs](https://github.com/oiwdis/last-train-out/actions/runs/44859769512/artifacts/14690921096)

## What changed in the world

| Owner observation | Diagnosis | Change in the playable mission |
|---|---|---|
| Harlow track was bright white | Journey construction removed the material-assigned Harlow main line. The replacement straight track had empty material slots for its rail, timber and ballast. The straight extended beyond the start of the swept line. | Keep and trim the authored main line at route metre 280. Use the same weathered web, burnished steel head, scanned wood and gravel on the straight, siding and swept track. A crowned rail profile catches a narrow highlight. Exposure and sunlight retain their original values. |
| Daylight showed between the brickwork and green wall in Bonded Stores | The kit's outward-facing brick skin sits at local Z 4.88 m. The green side walls ended at 4.60 m. Their scaled bevels opened additional gaps at the corners. | Build a continuous masonry return and inward-facing leaf between those surfaces. Cut it to match the kit's actual upper glazed openings. Square the structural ends, rear wall and roof. Apply the same joint to the second Harlow warehouse. The working side-door passage retains its collision opening. |
| Abrupt edges and bare gray ground through curves | Independent, 620-metre-wide rectangular ground boxes rotated with individual chord segments. Inside a bend they overlapped, and outside a bend their edges separated. The tops also obscured authored station paving. | Sweep a continuous strip through route cross sections. Share its outermost points between chunks and derive collision from the very same triangles. Gravel shoulders lead to drainage, scanned turf, groups of scrub and trees, telegraph wires and fences. |
| Fog resembled a uniform gray mass | The front used overlapping flat sheets and a largely uniform height falloff. Observer fog predominantly changed the scene's overall density. | Use bowed, irregular banks, a wind-advected density field and observer-dependent scattering. The four hazard states, warning HUD and survival calculations continue to use the original simulation. |
| Ashford was sparse and Blackwater objectives were hard to recognize | Much of each station was a single undifferentiated ground slab around similar buildings. Small objects did little to identify the next station from a train. | Differentiate Ashford with freight-handling equipment and a maintenance yard. Give Blackwater a road crossing, cottages, a station frontage, a shop awning and evacuation-register signs. The original caches and note retain their positions. |

### Track, terrain and materials

The original baked Curve3D still determines train placement and travel distance. Each 120 m terrain section contains cross sections every 6 m. The inside 18 m follows the rail's local lateral axis. Farther out, widening runs toward world north and south, keeping distant rim vertices from folding over on a curve. Both neighboring chunks sample the same rim, including UV coordinates and elevation. A route-wide raycast found 205 of 1,105 tree and scrub roots floating over 35 cm in the first revision. Planting on the actual mesh triangle put all 1,105 original roots between 4.49 and 4.51 cm beneath the surface. The rebuilt hedgerows bring the final total to 1,355. The route-wide physics test verifies the contact of every root. The same sampling locates pole and fence feet. All 43 chunks retain physical ground. Nearby visibility extends 520 m along the corridor and exceeds the 350 m review-camera range. The track shoulder provides standing room for moving ladder boarding. The drainage channel begins outboard of that shoulder.

The corridor ships as a compressed scene with mesh, collision, instance transforms and batch bounds baked together. A matching route geometry signature selects it during ordinary threaded mission loading. A custom route can rebuild its own geometry. A bulk transform buffer and explicit bounds preserve rail sleepers and vegetation on headless build machines. Ties, poles, fences and cutout foliage are batched or range-limited. An original atlas with four alder and scrub variations and seamless fog field supplement the existing licensed environment kit. Rob Tuytel's CC0 grass-and-rock scan supplies colour and relief. The asset manifest records the source files and digests. [Material provenance](../assets/pbr/sources.json) · [Original texture generator](../tools/build_route_atmosphere.py) · [Corridor bake](../tools/assets/bake_route_corridor.gd)

### Fog and stations

The banks move with the existing route front. Individual layers have different widths, irregular heights and curved profiles. Their separation across 16 m intervals yields parallax as the player or train moves. A mipmapped density lookup supplies the broad shape. A second lookup supplies fine wind movement on two leading Medium banks and all six High banks. Distance fog attenuates the actual train, buildings and distant ground. Desaturation, light colour and sky response increase further inside. Low draws two layers, Medium four, and High six. Medium uses ordinary distance fog and these meshes. All share the same shader and existing material-preparation lifetime. High retains the integration's separately controlled volumetric setting.

Ashford's transfer gantry spans the loading pads. An elevated coal tipple, inclined conveyor, freight siding, box van and weathered containers identify the yard. Numbered bays stage uncollected crates. Tool storage, an overhead pipe and fitter's bench distinguish the workshop interior. Fixed architectural footprints share the station's original static collision body. Dressing may disappear at detail range independently of the permanent surfaces the player walks on.

Blackwater has crossing gates, painted stop lines, a main road, gabled houses, utility lights and a parked delivery van. An awning and window frames distinguish Crossing Stores. A second sign points to the evacuation register, and the track-crew shed identifies its coal reserve. Shallow concrete thresholds join the outdoor grade to the existing walk-through doorways.

## Inspection and validation method

The source baseline passed 305/305 on pinned Godot 4.5.1. Five additional scene tests exercise the live mission. They check rail surface assignments and junction alignment, both directions through the masonry return, door and window structure, all 42 terrain joins, ground raycasts on both sides of bends, saved instances and bounds, fog mesh depth, texture assignments, station landmarks, physics ownership, shared line materials, bounded wire geometry and the actual rendering features at each preset. The unchanged gameplay suites still exercise moving ladders, interiors, heavy cargo, rider restoration, saves and outcomes. [Scene inspections](../tests/integration/test_environment_overhaul.gd)

Build 111 passed **310/310 on Linux** in 129.8 seconds and **310/310 on macOS** in 102.9 seconds. All 305 original test identifiers passed on both operating systems. The continuous input journey passed 167 checks, the fuel-shortage scenario passed 35, the stranded failure passed 24 and a new process restored the saved run in all 17 checks. Two further Linux journeys at fixed 60 and 12 simulation frames per second reached the escape boundary. The rendered Linux tests used a software Vulkan adapter. [Passing identifiers](validation/milestone4/test-preservation.json) · [Linux logs](validation/milestone4/hosted-linux.zip) · [Mac logs](validation/milestone4/hosted-macos.zip) · [Mission outcomes](validation/milestone4/gameplay-results.json) · [Local runs](validation/milestone4/linux-and-journey.zip)

The matched Metal review uses the PR #6 build 104 download with ZIP SHA-256 `95d5ccbc65700a2d1f7b8e641eef3fd880f35b34221d09077ebd58a45a49b5ee`. One shared external camera script runs against each exported PCK, using the packaged Apple Silicon selector. The curved view looks along a 14.6-degree change of heading over 145 m, starting at route metre 2,020. The timing matrix covers 16 positions. A separate process captures them plus three closer station views on every preset at a 960 × 540 window size. Camera, target, observer and danger-front coordinates are recorded and compared. The separate image passes remove the route and inventory panels and keep the warning overlay in fog views. Motion in individual wisps follows the running shader clock.

The camera fixture repositions the observer for repeatable views. The independent full-route validation uses movement and interaction inputs to travel between stations. Timing passes keep the gameplay UI and disable VSync. Each pose records 60 entry intervals, 48 settling frames and 180 steady intervals, in two new processes per build with the order reversed for the repeat. Every measured interval is retained. Preset preparation, scene construction, first draw and ordinary cold/warm player launch use separate records. The selector-to-play test uses system audio. The fixed-view matrix uses the dummy audio driver. App shader caches are private per build and ordinary-player preset. The runner and its OS/driver caches are shared. GPU and CPU counters describe different parts of the pipeline and can overlap. Static engine memory excludes allocations in other libraries. RSS is polled independently. [Measurement driver](../tools/macos/compare_environments.py) · [Benchmark scene](../scripts/diagnostics/integration_benchmark.gd)

The matched launch driver points the normal loading scene at an isolated copy of each PCK and selects the preset through the packaged launcher. That override disables installation of writable source-cache seeds. The compatible read-only Metal libraries remain active. The independent fresh-download job also launches the unmodified app without scene or pack overrides and captures first and warm play times. Those results are identified separately.

## Continuous native Metal gameplay

The packaged Medium player recorded an uncut **23 min 30.83 s** journey at 960 × 540. The input driver uses ordinary movement, interaction, camera, cargo and train controls. It waits at Ashford for the pursuing fog and leaves heavy spares behind. It visits Harlow, Ashford and Blackwater, reads the evacuation register, reloads through Save/Continue and escapes at 4,260.006 m. All 167 route checks passed. One save restoration repositioned the rider and cargo. Travel used zero teleports. The successful run stayed ahead of damaging exposure. The matched weather views separately show conditions inside dangerous fog. Movie Maker encoded 16,930 frames at 12 FPS offline. The frame-time tables use independent real-time runs. [Continuous MP4](recording/milestone4-native-metal.mp4) · [Original movie artifact](https://github.com/oiwdis/last-train-out/actions/runs/44859769512/artifacts/14691130624) · [Inputs, outcomes and recording receipt](validation/milestone4/recorded-journey.zip)

The decoded film has zero all-black frames and zero isolated brightness pulses at the documented thresholds. At Blackwater, frame 14,635 now shows the grass and pavement continuously through its two neighbors. The same frame in the rejected recording contained a black foreground polygon. [Three consecutive frames from both films](validation/milestone4/blackwater-film-comparison.jpg) · [All-frame audit](validation/milestone4/movie-motion.json) · [Stream details](validation/milestone4/video-stream.json)

## Physical 2020 M1 procedure

The owner's build 103 native Metal fullscreen observations were approximately 60 FPS on Medium in ordinary gameplay and in fog, approximately 30 FPS on High normally and 20–25 FPS on High in fog. Physical validation of the revised game is pending. The hosted comparison uses a paravirtual GPU. Preserve the physical launch log with the machine and OS version. The phrase `Loaded bundled Metal library group` identifies use of the compatible precompiled profile. Other supported profiles can compile from the shipped source.

Replacing the app bundle preserves the manual slot. Builds 103 and 111 use the same schema version 1 and the same file outside the application, `~/Library/Application Support/Godot/app_userdata/Last Train Out/harlow_escape_v1.json`. Both apps share this slot. To keep the exact original checkpoint while testing, copy that JSON before making a new manual save. Use **J → Continue** to resume. A separate headless process wrote a moving-train save using the exact build 103 PCK, then the build 111 PCK restored the rider, held cargo, inventory, fog and ongoing movement in all 17 checks. Continuing preserved the original file SHA-256. [Cross-build save, checks and engine logs](validation/milestone4/save-103-to-111.zip)

For the owner's build 111 test, use fullscreen Medium. Its independent cold High native crash is still under investigation. Steps 2 and 5 cover the later all-preset candidate once its native High checks have been reviewed.

```sh
"/Applications/Last Train Out.app/Contents/MacOS/choose-renderer" metal --fullscreen -- --graphics=medium
```

1. Keep the old and revised apps in separate folders. Record macOS version, native and scaled display resolution, refresh rate and memory. Use the same screen, mode, power state and resolution for both. Record the bundle build ID and ZIP SHA. Start each app from native Terminal with its explicit selector, for example `"/Applications/Last Train Out.app/Contents/MacOS/choose-renderer" metal --fullscreen --verbose`. An ordinary double-click uses the integration default, Vulkan.
2. In native Terminal run the command below from each build's checkout, changing the app path and using a different new output directory for each. The existing owner harness records fullscreen and windowed runs, Low/Medium/High, cold/warm startup, frame intervals, logs and process memory. It creates private application data directories. Keep failures and any crash reports alongside successful attempts. The driver recorded in a Metal log is `forward_plus/metal`.
3. In fullscreen Medium, walk from Harlow platform level to the main line and photograph the rail head, sleeper and ballast. Look at the Bonded Stores corner both inside and out, then walk through both warehouse side doors. Inspect the curved embankment in the cab, in third person and on foot. Look for gaps, abrupt popping and hovering detail.
4. Board normally, take coal through the Ashford freight entrance, visit the workshop and refuel. At Blackwater, follow the marked road to Crossing Stores, read the evacuation log and use Save/Continue. Compare the far bank, approaching wisps and visibility from inside fog. Keep the real warning text visible and record FPS and frame pacing in each state.
5. Repeat those fog and station views on Low and High. Include first launch, warm re-entry, any visible hitch, shutter-like noise, crash or abnormal exit. Retain the exact preset, window mode, rendered resolution, raw interval files and OS diagnostic report with each observation.

```sh
bash tools/macos/benchmark_m1_renderers.sh "/path/to/Last Train Out.app" "$HOME/Desktop/LTO-M4-M1-results"
```

For the 16 Milestone 4 views in fullscreen, run the external script from the Milestone 4 checkout with each app. Use a unique output filename for each build. The JSON records the actual viewport and render scale, each camera and hazard state, and all frame intervals.

```sh
app="/Applications/Last Train Out.app"
"$app/Contents/MacOS/choose-renderer" metal --fullscreen \
  --script "$PWD/scripts/diagnostics/integration_benchmark.gd" -- \
  --graphics=low --suite=environment --warmup=120 --samples=600 \
  --out="$HOME/Desktop/LTO-M4-fullscreen-world.json"
```

[Existing M1 hardware and renderer procedure](M1_MILESTONE354.md)

## Failures found during development

The first implementation passed 307 of 309 Linux tests. Its drainage profile put the ground beside the departing crew-car ladder too low to board. The station art also owned a new physics body and a rail siding whose detail ranges belonged to rail infrastructure. The revised shoulder preserves the boarding surface, fixed scenery uses the existing station body and the siding belongs to the station. A subsequent run passed all 309 assertions and still failed strict shutdown. Constructing and discarding one unused station reproduced one leaked Jolt body. Allocating it when the station enters the tree removed that leak. Both the reproduction and the corrected exit are archived.

The real input journey stopped at an Ashford loading bay, the lip of the Blackwater station doorway, and a van protruding into the return route. The bays moved clear of the existing approach, shallow thresholds join the pavement to the building floors, and the van occupies the opposite side of the street. The journey input driver and its navigation targets are unchanged. The final source run passed 167 checks, reached 4,260.006 m and restored one save with zero travel teleports. The rider-and-cargo preparation race also passes in the full test suite.

Early macOS validation rejected the fog texture's import settings. The fog density field, copse atlas and grass scan now use explicit mipmaps, GPU compression and channel handling. The asset audit covers 31 production models and 141 compressed textures. Build 105 retained the original regressions, and build 106 retained the shutdown failure. GitHub superseded queued build 107 before it ran. A separate raycast pass found the floating foliage described above. [Raw failures and reproductions](validation/milestone4/investigation.zip) · [Local tests and full input journeys](validation/milestone4/linux-and-journey.zip)

## Archived first development build

Build 108 packages the runtime source at `9b6f67cd15cc12fecb64bbc3112b39fd4a307dc5`. The PR test-merge embedded in the bundle is `13d7cbde24b62ef23ec6426d42ab58e699e9c64a`, whose Git tree matches the branch revision. The independently downloaded 340,416,790-byte ZIP has SHA-256 `e9b7573db2dd05a4109eb7c82bef304173c0ae8b1f598b707fc725dea3afd639`. The pack digest is `2a00fdd9c90987660c5c4e9e06730b710eb9de5230cb73b30b167afed4c5bcee`.

The ZIP contains one `Last Train Out.app`. It includes its Godot 4.5.1 runtime, a universal arm64/x86_64 default executable and selector, and the opt-in arm64 native Metal executable. The pack includes all 385 checked project files, the baked corridor and the new shader/texture assets. The packaged shader profile contains 97 native source groups and 82 matching precompiled library groups. Build 104 contained 94 and 83 respectively. Of its source groups, 93 retain identical SHA-256 hashes. Four groups enter the new scene inventory and one retires. [Shader inventory comparison](validation/milestone4/build-108/shader-groups.json) Source-only fallback is available on other device profiles. This is an ad-hoc-signed development build. [Universal ZIP](https://github.com/oiwdis/last-train-out/actions/runs/44850871725/artifacts/14686450857) · [Independent build receipt](validation/milestone4/build-108/development-build.json) · [ZIP verification](validation/milestone4/build-108/zip-verification.log) · [Workflow](https://github.com/oiwdis/last-train-out/actions/runs/44850871725)

## Default Vulkan renderer

The dedicated High series in build 111 lost the Vulkan device in **7 of 17 cold starts**. The corresponding series lost the device in three of 17 on PR #6 build 104 and zero of 17 on build 108. Each of the seven build 111 logs reached the `warmup_view_Platform` marker. Each Apple crash report shows `SIGTRAP` in the same `RenderingDeviceDriverVulkan::command_queue_execute_and_present` path as build 104. MoltenVK reports a GPU command-buffer timeout followed by a lost device. GPU execution is asynchronous, so the last completed CPU marker does not identify the faulting draw.

At the last completed phase the texture counter was 361.5 MiB on build 111 and 357.4 MiB on build 104. Build 111’s failed cold processes peaked at 406–493 MiB RSS. Successful cold attempts on that runner peaked at 460–501 MiB. These distributions overlap. The available counters provide no direct GPU-budget or faulting-command attribution. PR #6 already reproduced this failure with the old world. The two-host control ran both archives in opposite orders with identical High stress commands. Both universal binaries had the same arm64 and x86_64 UUIDs. The new pack failed more often in either order. Across both hosts, 20 of its 22 losses followed the platform marker and two followed the earlier fog-material marker. Every warm attempt completed.

| Order on each hosted Mac | PR #6 cold High losses | Build 111 cold High losses | PR #6 warm High losses | Build 111 warm High losses |
|---|---:|---:|---:|---:|
| Build 111 first | 2 / 17 | 11 / 17 | 0 / 17 | 0 / 17 |
| PR #6 first | 0 / 17 | 11 / 17 | 0 / 17 | 0 / 17 |

The failure predates the world overhaul, but the increased frequency follows the candidate across both Macs. App caches were private. Each host’s filesystem and driver caches were shared. A separate rotating same-pack experiment compares the full world, the integration fog shader on the new banks, the corridor hidden, and the unmodified world with the first fog draw at the platform. The normal acceptance workflow continues using the complete authored scene. [Every failed process log and Apple crash report](validation/milestone4/vulkan-device-loss.zip) · [Per-series counts, phase markers and backtraces](validation/milestone4/vulkan-device-loss.json) · [Matched Vulkan experiment](https://github.com/oiwdis/last-train-out/actions/runs/44864165485)

## Reproduce the review

Download and unzip both development apps, then run the commands below from the Milestone 4 checkout on an Apple Silicon Mac. Use a new output directory. The timing driver uses the standard library. The gallery builder also uses Pillow.

```sh
python3 tools/macos/verify_app.py --zip LastTrainOut-macos-universal.zip
python3 tools/macos/compare_environments.py "/path/to/PR6/Last Train Out.app" world-review \
  --candidate "/path/to/M4/Last Train Out.app"
(cd world-review && zip -qr ../native-metal-environment.zip .)
python3 docs/validation/milestone4/summarize.py native-metal-environment.zip review-results
```

The Linux geometry checks use the pinned Godot 4.5.1 executable. Rebuild the shipped corridor after changing its mesh generator, then run the full suite.

```sh
godot --headless --path . --script res://tools/assets/bake_route_corridor.gd
MIN_TESTS=310 tools/run_tests.sh godot
python3 tools/check_integration_tests.py tests/_output/results.json
```

## Build 108 native review

The first matched native Metal comparison exposed a Medium terrain defect which the Linux geometry and rendered inspections missed. On the hosted Metal adapter, 19.04% of the curve image and 22.31% of the Crossing Stores image were near black (all three 8-bit channels below six). The equivalent reference, candidate Low and candidate High views each measured under 0.01%. The black regions cover ground which the collision and raycast checks confirm is present. Build 108 is unsuitable for owner acceptance. Its pictures and frame times remain evidence of this first attempt. [Build 108 matched gallery](https://github.com/oiwdis/last-train-out/blob/8c49608c3f67daced335a0d7228d163171ed54cd/docs/validation/milestone4/GALLERY.md) · [Build 108 frame times](https://github.com/oiwdis/last-train-out/blob/8c49608c3f67daced335a0d7228d163171ed54cd/docs/validation/milestone4/FRAME_TIMES.md)

Across 5,760 steady intervals per preset and revision, the Medium p95 fell from 12.35 to 10.26 ms. Inside dangerous fog it rose from 8.53 to 11.34 ms. Medium cold selector-to-play time rose from 25.27 to 36.40 s, including an increase from 7.17 to 12.06 s for threaded resource loading. On this launch the fog preparation phase grew from 6.48 to 10.25 s. The largest High entry frame was 758.33 ms on the first Harlow platform frame after changing preset. The same measurement on the repeat was 229.05 ms, and on the reference repeat it was 599.47 ms. In the 758.33 ms frame, 755.91 ms elapsed between the renderer callbacks and 0.62 ms within the gameplay process callback. The measured pipeline counters were unchanged across the sample window. No GPU timestamps were exposed by this adapter. [Build 108 startup](validation/milestone4/build-108/launches.csv) · [Raw build 108 sessions](https://github.com/oiwdis/last-train-out/blob/8c49608c3f67daced335a0d7228d163171ed54cd/docs/validation/milestone4/raw-environment.zip)

### Isolating the Medium black regions and the startup regression

A second Mac reproduced the defect in the archived build. With the original material, 19.13% of the bend and 22.48% of the store view were near black. Turning off just the terrain's tangent-space normal feature brought both to 0.00%. Substituting a neutral normal texture reproduced 19.10% and 22.48%. Changing anisotropy, glow, sun shadows or the albedo map left both defects visible. The evidence isolates the normal-mapped terrain rendering path on this profile. The exact driver operation remains unknown. Medium now uses the mesh's slope normals and the scanned grass colour. High retains the normal scan with a tangent basis aligned to its world-space UVs. An image check measures both fixed daylight views on each preset. [Matched native control images](validation/milestone4/build-108/terrain-material-control.jpg) · [All 26 native ablations](validation/milestone4/build-108/material-controls.json)

The earlier fresh High reference recorded zero Metal source compilations. Build 108 recorded 24, covering 12.40 seconds of elapsed time across overlapping worker intervals. The 184 compute pipelines consumed 6.28 s on each host. The render pipeline interval union rose from 3.44 to 14.63 s. These intervals overlap and cannot be added to obtain startup time. Every observed hash maps to the packaged source inventory. The three new groups supplied 10 foliage, eight verge and four fog stages. Two came from a previously present group. The export now uses the integration's existing offline compiler and profile selector to prepare the stages actually used by the 16-view world run. A second isolated process checks the resulting package. Unsupported profiles retain the source path. [Signed shader inventory, native signposts and raw controls](validation/milestone4/build-108/terrain-and-startup-investigation.zip)

The revised corridor keeps nearby chunks visible before its scenery enters the rendering world. Shared paint and timber reduce distinct mesh materials from 135 to eight. The wire and fence batches retain their dimensions while removing 60,960 bevel triangles. Medium keeps two detailed leading fog banks and two broad trailing layers. The same four simulated hazard states drive every preset. The revised field boundaries contain 1,355 individually checked planted roots. All permanently resident physical ground, rail profiles and calibrated train dynamics remain in use.

### Shader verification failures

Build 110 passed all 310 tests on Linux and macOS and compiled 28 observed stages. Its independent verifier stopped publication when the same source appeared in multiple material groups. Some occurrences already had compiled bytes and others contained only source. The corrected verifier checks each occurrence against its signed input, verifies all original compiled bytes, then distributes the requested compiled stages into compatible groups. Two regression tests exercise this mixed-storage case. [Build 110 failure and compiler logs](validation/milestone4/build-110/README.md)

The historical renderer experiment also rejected build 99 in both execution orders before game launch. Its package checker was reading the Milestone 4 worktree and expected new route assets in the older game. The experiment now verifies the bundle's recorded source commit against the archive receipt and checks its entire game inventory from that revision. The current game's package check uses the Milestone 4 source. Both corrected execution orders passed all six packaged runs, including signpost collection and real rendered views. [Original replay logs](validation/milestone4/historical-replay.zip) · [Twelve corrected runs](validation/milestone4/historical-replay-results.json) · [Historical workflow](https://github.com/oiwdis/last-train-out/actions/runs/44860690626)
