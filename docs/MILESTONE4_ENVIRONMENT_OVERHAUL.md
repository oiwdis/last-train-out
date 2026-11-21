# Milestone 4 environment overhaul

Milestone 4 is stacked on the open, unmerged PR #6 at `684df38f0d9ba39a876d4788696855f0b64d5b29`. PR #7 targets `integration/milestone-3-5-photoreal-survival`. The route, rolling stock, survival simulation, save format and renderer selection come from that integration. [Development PR #7](https://github.com/oiwdis/last-train-out/pull/7) · [Integration PR #6](https://github.com/oiwdis/last-train-out/pull/6) · [Renderer history](PERFORMANCE_MILESTONE354.md)

## Development build 118

**Keep PR #7 and its integration base in draft.** The rebuilt embankment, depots and layered fog follow the existing railway. Build 118 also repairs the Ashford workshop floor and corrects a native Metal pipeline-worker race. The owner's physical 2020 M1 measurements still cover build 103. Build 111 remains available for the planned fullscreen Medium visual comparison. [Current universal app](https://github.com/oiwdis/last-train-out/actions/runs/44877553078/artifacts/14698763058) · [Owner’s build 111](https://github.com/oiwdis/last-train-out/actions/runs/44859769512/artifacts/14689604118) · [Matched native gallery](validation/milestone4/GALLERY.md) · [Complete frame distributions](validation/milestone4/FRAME_TIMES.md) · [Uncut route movie](recording/milestone4-native-metal.mp4)

Build 118 completed 95/95 native Metal and 95/95 default Vulkan stress processes on hosted Apple Silicon. The default series recorded 0 device losses. The matched Medium Harlow redraw reached 833.39 ms, and the physical M1 result still covers build 103. [Release series and failed attempts](validation/milestone4/renderer-stress.json) · [Preset handoff measurements](validation/milestone4/PRESET_ENTRY.md)

The tested source is `86007236d795713a9271dec69977ddde5e9441d5` on `feature/milestone-4-environment-overhaul`. The packaged PR test-merge is `16d0978d855a6316c33afc2c675d31f3ac104b18` and its Git tree matches the source commit. The independent download verified GitHub's checksum, ZIP CRC, the universal arm64 and x86_64 default player and selector, the arm64 native Metal executable and every signed shader group. The pack contains 941 entries, including all 385 checked project resources and the explicitly checked corridor, vegetation and fog assets. The universal development app is ad-hoc signed. The optional Developer ID and notarization job was skipped. [Independent receipt](validation/milestone4/development-build.json) · [Bundle verification](validation/milestone4/zip-verification.log) · [All CI jobs and artifacts](validation/milestone4/workflow.json)

| Download | Bytes | SHA-256 |
|---|---:|---|
| LastTrainOut-macos-universal.zip | 340,821,856 | `a3a129d80ec95ae5d880f4d9bc92dde469df04350c9c949bdfa8584abf12b9c5` |

The compatible macOS 26 Apple5 profile has 97 source groups and 86 read-only library groups. The 16-view measurement recorded 30 source-compile intervals for 28 unique stages before offline preparation and 0 on a fresh application cache after it. The render pipelines observed before and after numbered 558 and 558. Their overlapping creation intervals occupied 10.18 s and 1.31 s on the build host. Other device profiles retain the native source fallback. [Shader comparison](validation/milestone4/shader-groups.json) · [Native traces and compilation records](validation/milestone4/world-stage-preparation.zip)

## Frame pacing and startup on native Metal

Each pair gives the PR #6 build 104 result followed by Milestone 4 build 118. Both ran on the same hosted Apple paravirtual GPU at 960 × 540. Each preset contributes 5,760 steady and 1,920 entry intervals per build. The tables include every interval. GPU timestamp counters were unavailable on this adapter.

| Preset | Steady median (ms) | p95 (ms) | p99 (ms) | Worst (ms) | Worst entry (ms) | Steady frames >33.3 ms | Entry frames >100 ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| Low | 6.7 / 7.1 | 11.9 / 12.7 | 17.8 / 18.4 | 51.3 / 61.3 | 152.5 / 135.0 | 4 / 7 | 2 / 2 |
| Medium | 8.6 / 9.1 | 14.9 / 17.3 | 21.4 / 26.5 | 82.9 / 81.5 | 691.3 / 833.4 | 11 / 22 | 4 / 4 |
| High | 10.2 / 10.2 | 17.7 / 17.3 | 26.0 / 25.3 | 91.4 / 59.4 | 1183.5 / 278.6 | 19 / 15 | 5 / 3 |

| Medium location | Steady p95 (ms) | Steady p99 (ms) | Worst entry (ms) | Mean draw calls | Mean render CPU (ms) |
|---|---:|---:|---:|---:|---:|
| Harlow track | 18.0 / 20.7 | 23.3 / 32.5 | 118.5 / 84.4 | 953 / 971 | 1.65 / 1.68 |
| Bonded Stores interior | 14.2 / 15.2 | 26.4 / 21.5 | 46.0 / 48.1 | 384 / 407 | 1.00 / 0.97 |
| Curved embankment | 13.1 / 12.5 | 24.7 / 15.5 | 74.8 / 52.6 | 286 / 289 | 0.91 / 0.84 |
| Warehouse B | 12.3 / 17.7 | 16.0 / 30.0 | 19.9 / 91.4 | 460 / 475 | 1.03 / 1.12 |
| Locomotive cab | 15.8 / 17.9 | 18.4 / 30.4 | 198.9 / 255.3 | 984 / 1001 | 1.61 / 1.60 |
| Passenger car | 17.1 / 24.7 | 21.0 / 56.8 | 44.9 / 66.6 | 1109 / 1124 | 1.77 / 1.99 |
| Ashford Depot | 12.2 / 13.6 | 17.6 / 25.7 | 26.0 / 24.1 | 159 / 222 | 0.79 / 0.82 |
| Blackwater Crossing | 10.5 / 13.7 | 17.6 / 21.8 | 38.3 / 37.8 | 175 / 230 | 0.74 / 0.84 |
| Distant fog | 10.6 / 12.7 | 18.5 / 24.2 | 16.0 / 35.4 | 319 / 334 | 0.87 / 0.87 |
| Near advancing fog | 12.1 / 13.2 | 18.7 / 18.5 | 31.9 / 16.0 | 319 / 334 | 0.87 / 0.94 |
| Inside dangerous fog | 15.3 / 13.3 | 21.8 / 30.7 | 17.7 / 15.9 | 315 / 333 | 0.92 / 0.96 |

| Matched selector-to-play time | Cold (s) | Warm (s) | Cold threaded loading (s) |
|---|---:|---:|---:|
| Low | 31.05 / 29.86 | 27.27 / 29.26 | 8.09 / 11.48 |
| Medium | 21.87 / 28.48 | 21.83 / 32.01 | 6.86 / 10.71 |
| High | 29.29 / 36.81 | 26.02 / 34.93 | 8.19 / 9.58 |

[All 16 views on all three presets](validation/milestone4/FRAME_TIMES.md) · [Complete distributions, FPS, draw calls, triangles and memory](validation/milestone4/locations.csv) · [All frames above 50 ms and their callbacks](validation/milestone4/slow-frames.csv) · [Raw paired runs](validation/milestone4/raw-environment.zip)

On Medium, the integration / overhaul p95 across all steady views was 14.87 / 17.29 ms. Inside dangerous fog it was 15.34 / 13.31 ms. Warehouse B measured 12.33 / 17.67 ms, the workshop 11.20 / 13.28 ms, the locomotive cab 15.77 / 17.93 ms and the passenger car 17.11 / 24.66 ms. The workshop submitted 191 / 254 mean draw calls and 130,477 / 281,373 primitives per frame. The expanded Ashford freight yard submitted 159 / 222 mean draw calls. The ordinary Medium texture counter averaged 305.94 / 310.06 MiB during steady sampling. Peak process RSS on the reference first and repeat passes was 621.3 and 549.1 MiB. The corresponding candidate passes reached 628.6 and 576.7 MiB. [Locations and submitted geometry](validation/milestone4/locations.csv) · [Process samples](validation/milestone4/runs.json)

The longest candidate interval was 833.39 ms in Harlow platform on Medium, in the first pass, entry frame 0. The render callbacks bracketed 831.37 ms, gameplay processing 0.48 ms and physics 1.54 ms. The sampled window recorded 0.0 draw, 0.0 surface and 0.0 specialization pipeline changes. The adapter did not expose GPU timestamps. Build 115 also recorded an intermittent 665.57 ms first Medium platform redraw after changing the preset and camera. Its first pass at that same position took 6.19 ms. Its ordinary cold and warm Medium launches peaked at 18.09 and 18.44 ms in their first 30 playable frames. [Every interval above 50 ms](validation/milestone4/slow-frames.csv) · [This build’s preset-to-first-draw counters](validation/milestone4/preset-handoff.csv) · [Build 115 frame analysis](validation/milestone4/build-115/MEDIUM_ENTRY.md)

The build 117 repeat also spent 899.67 ms on its first Medium Harlow frame and 957.33 ms on the first High pass. The same integration runner reached 676.88 ms on Medium. Across builds, the other world captures and ordinary launch and mission-result sequences provide independent comparisons. [First platform redraws and raw counters](validation/milestone4/PRESET_ENTRY.md)

The latest matched host recorded 339 of 5,760 steady Medium frames above a 16.67 ms refresh interval, versus 166 on the integration. Passenger-car p95 was 24.66 ms versus 17.11 ms. The same geometry on the previous hosted run gave the opposite comparison. On the current passenger repeat, the slowest 5% averaged 39.04 ms between render callbacks, 0.60 ms in gameplay processing and 0.16 ms in physics. The independent native library runs and the mesh-by-mesh software controls put those intervals alongside actual submissions. Medium performance on the physical 2020 M1 remains an open acceptance item. [Interior timing, per-pass results and mesh controls](validation/milestone4/MEDIUM_INTERIORS.md)

### Fresh native Metal High player launches

These unmodified app downloads ran on separate hosted Macs with native audio at 960 × 540. Each cold start used an empty app cache and its warm repeat reused that cache. Launch time and signpost interval unions include overlapping work. Different runners can have different driver caches and load.

| Build | Cold playable (s) | Warm playable (s) | Cold / warm resource load (s) | Cold / warm first fog and world draw (s) | Cold source compilations |
|---|---:|---:|---:|---:|---:|
| PR #6 build 104 | 37.85 | 28.36 | 8.15 / 6.76 | 11.12 / 8.24 | 0 |
| Build 108 | 56.42 | 39.15 | 18.82 / 12.84 | 18.57 / 9.92 | 24 |
| Build 111 | 48.75 | 44.70 | 12.48 / 11.82 | 13.70 / 13.64 | 0 |
| Build 115 | 39.00 | 35.18 | 12.59 / 9.04 | 9.00 / 10.15 | 0 |
| Build 117 | 34.01 | 27.34 | 12.49 / 10.59 | 8.43 / 6.78 | 0 |
| Build 118 | 31.84 | 28.50 | 10.75 / 10.09 | 7.98 / 7.47 | 0 |

The current cold process created 184 compute pipelines over 4.65 s and 266 render pipelines over 2.24 s. Its first 30 playable frames peaked at 18.23 ms cold and 18.56 ms warm. The paired startup table above measures the original and revised scenes on the same runner. [Ordinary launches and native signposts](validation/milestone4/fresh-player-startup.json) · [Original player logs](https://github.com/oiwdis/last-train-out/actions/runs/44877553078/artifacts/14700121967)

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

The source baseline passed 305/305 on pinned Godot 4.5.1. Seven additional tests exercise the live mission and the initial-camera policy. They check rail surface assignments and junction alignment, both directions through the masonry return, door and window structure, all 42 terrain joins, ground raycasts on both sides of bends, saved instances and bounds, fog mesh depth, texture assignments, station landmarks, physics ownership, shared line materials, bounded wire geometry and the actual rendering features at each preset, the stepped joint between the depot yard and building floors, and the renderer, OS and preset conditions for the first fog view. The unchanged gameplay suites still exercise moving ladders, interiors, heavy cargo, rider restoration, saves and outcomes. [Scene inspections](../tests/integration/test_environment_overhaul.gd) · [Preparation and resource-lifetime tests](../tests/integration/test_preparation_lifecycle.gd)

The release passed **312/312 on Linux** and **312/312 on macOS**. All 305 original test identifiers passed in both reports. The uninterrupted input journey passed all 167 checks, the fuel-shortage scenario passed 35, the stranded failure passed 24 and a fresh process passed all 17 save restoration checks. Two full Linux input runs at fixed simulation rates of 12 and 60 reached the escape, including the moving rider and cargo restore. [Test preservation](validation/milestone4/test-preservation.json) · [Linux logs](validation/milestone4/hosted-linux.zip) · [Mac logs](validation/milestone4/hosted-macos.zip) · [Mission outcomes](validation/milestone4/gameplay-results.json) · [Local runs on the exported source](validation/milestone4/linux-and-journey.zip)

The matched Metal review uses the PR #6 build 104 download with ZIP SHA-256 `95d5ccbc65700a2d1f7b8e641eef3fd880f35b34221d09077ebd58a45a49b5ee`. One shared external camera script runs against each exported PCK, using the packaged Apple Silicon selector. The curved view looks along a 14.6-degree change of heading over 145 m, starting at route metre 2,020. The timing matrix covers 16 positions. A separate process captures them plus three closer station views on every preset at a 960 × 540 window size. Camera, target, observer and danger-front coordinates are recorded and compared. The separate image passes remove the route and inventory panels and keep the warning overlay in fog views. Motion in individual wisps follows the running shader clock.

The camera fixture repositions the observer for repeatable views. The independent full-route validation uses movement and interaction inputs to travel between stations. Timing passes keep the gameplay UI and disable VSync. Each pose records 60 entry intervals, 48 settling frames and 180 steady intervals, in two new processes per build with the order reversed for the repeat. Every measured interval is retained. Preset preparation, scene construction, first draw and ordinary cold/warm player launch use separate records. The selector-to-play test uses system audio. The fixed-view matrix uses the dummy audio driver. The physical report has no measured resolution or startup time for the revised build yet. App shader caches are private per build and ordinary-player preset. The runner and its OS/driver caches are shared. GPU and CPU counters describe different parts of the pipeline and can overlap. Static engine memory excludes allocations in other libraries. RSS is polled independently. [Measurement driver](../tools/macos/compare_environments.py) · [Benchmark scene](../scripts/diagnostics/integration_benchmark.gd)

The matched launch driver points the normal loading scene at an isolated copy of each PCK and selects the preset through the packaged launcher. That override disables installation of writable source-cache seeds. The compatible read-only Metal libraries remain active. The independent fresh-download job also launches the unmodified app without scene or pack overrides and captures first and warm play times. Those results are identified separately.

## Continuous native Metal gameplay

The packaged Medium player recorded **23 min 30.83 s** at 960 × 540. It uses ordinary character movement, interaction, first- and third-person camera controls, cargo handling and locomotive inputs. The player searches Harlow, boards, crosses the curve, recovers fuel at Ashford, waits for the pursuing fog, reaches Blackwater, reads the evacuation register and resumes through Save/Continue. The train escaped at 4,260.006 m. The route passed all 167 checks with 1 save restoration and 0 travel teleports. The danger-state camera series separately records the scene inside damaging fog. The offline recording encoded 16,930 frames at 12 FPS. Real-time timings come from the separate uncapped runs. [Continuous MP4](recording/milestone4-native-metal.mp4) · [Original movie](https://github.com/oiwdis/last-train-out/actions/runs/44877553078/artifacts/14701095631) · [Film receipt, inputs and outcomes](validation/milestone4/recorded-journey.zip)

The decoded movie contains 0 all-black frames and 0 isolated brightness pulses under the recorded detection thresholds. The gallery includes consecutive Blackwater frames around frame 14,635 in the current and rejected recordings. [Consecutive frames](validation/milestone4/blackwater-film-comparison.jpg) · [All-frame audit](validation/milestone4/movie-motion.json) · [Stream details](validation/milestone4/video-stream.json)

The recording includes the wait at Ashford while the real fog advances. Approximate playback positions were matched against shots taken by the input driver. [Frame matches and nearest ties](validation/milestone4/movie-checkpoints.json)

| Time | Recorded event |
|---|---|
| 0:19 | Harlow on foot |
| 0:30 | Harlow cargo |
| 4:33 | Ashford arrival |
| 5:00 | Recovering coal |
| 16:03 | Reboarding with the fog approaching |
| 19:37 | Blackwater arrival |
| 20:35 | Evacuation log |
| 21:35 | Saved checkpoint |
| 21:40 | Continued checkpoint |
| 23:27 | Mission results |

## Physical 2020 M1 procedure

The owner's build 103 native Metal fullscreen observations were approximately 60 FPS on Medium in ordinary gameplay and in fog, approximately 30 FPS on High normally and 20–25 FPS on High in fog. Physical validation of the revised game is pending. The hosted comparison uses a paravirtual GPU. Preserve the physical launch log with the machine and OS version. The phrase `Loaded bundled Metal library group` identifies use of the compatible precompiled profile. Other supported profiles can compile from the shipped source.

Replacing the app bundle preserves the manual slot. Builds 103 and 111 use the same schema version 1 and the same file outside the application, `~/Library/Application Support/Godot/app_userdata/Last Train Out/harlow_escape_v1.json`. Both apps share this slot. To keep the exact original checkpoint while testing, copy that JSON before making a new manual save. Use **J → Continue** to resume. A separate headless process wrote a moving-train save using the exact build 103 PCK, then the build 111 PCK restored the rider, held cargo, inventory, fog and ongoing movement in all 17 checks. Continuing preserved the original file SHA-256. [Cross-build save, checks and engine logs](validation/milestone4/save-103-to-111.zip)

For the owner's planned build 111 test, use fullscreen Medium. One cold High native launch crashed in its original runtime. Build 118 includes the worker correction and was independently tested with a moving build 103 checkpoint. All 17 checks passed and Continue preserved the original save checksum. Steps 2 and 5 describe the wider all-preset test of the revised runtime. [Build 103 to 118 save evidence](validation/milestone4/save-103-to-118.zip) · [Native High investigation](validation/milestone4/build-111-native-high/README.md)

```sh
"/Applications/Last Train Out.app/Contents/MacOS/choose-renderer" metal --fullscreen -- --graphics=medium
```

1. For a side-by-side comparison, keep the two apps in separate folders. For a normal upgrade, quit the game and replace only the app in Applications. Record macOS version, native and scaled display resolution, refresh rate and memory. Use the same screen, mode, power state and resolution for both. Record the bundle build ID and ZIP SHA. Start each app from native Terminal with its explicit selector, for example `"/Applications/Last Train Out.app/Contents/MacOS/choose-renderer" metal --fullscreen --verbose`. An ordinary double-click uses the integration default, Vulkan.
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

## Native Metal and default Vulkan stability

Both backends completed all 36 High, 28 Low/Medium and 31 mixed release processes. Every default Vulkan preset/fog/Continue cycle passed all 35 checks. The same build 111 PCK ran the native High workload again on both executables, with 36/36 clean on the original and 36/36 on the corrected runtime. The earlier native High signal 11 occurred at the unprotected vertex-format lookup. Registration and lookup now take the same mutex while accessing the table. Driver compilation proceeds after the lock is released. Successful repetitions on both binaries limit what can be inferred about the intermittent crash rate. [All release processes and failures](validation/milestone4/renderer-stress.json) · [Original native crash report and source](validation/milestone4/build-111-native-high/README.md) · [Paired native series](validation/milestone4/native-high-workers.json) · [Raw launch and shutdown logs](validation/milestone4/raw-release-checks.zip)

The dedicated High series in build 111 lost the Vulkan device in **7 of 17 cold starts**. The corresponding series lost the device in three of 17 on PR #6 build 104 and zero of 17 on build 108. Each of the seven build 111 logs reached the `warmup_view_Platform` marker. Each Apple crash report shows `SIGTRAP` in the same `RenderingDeviceDriverVulkan::command_queue_execute_and_present` path as build 104. MoltenVK reports a GPU command-buffer timeout followed by a lost device. GPU execution is asynchronous, so the last completed CPU marker does not identify the faulting draw.

At the last completed phase the texture counter was 361.5 MiB on build 111 and 357.4 MiB on build 104. Build 111’s failed cold processes peaked at 406–493 MiB RSS. Successful cold attempts on that runner peaked at 460–501 MiB. These distributions overlap. The available counters provide no direct GPU-budget or faulting-command attribution. PR #6 already reproduced this failure with the old world. The two-host control ran both archives in opposite orders with identical High stress commands. Both universal binaries had the same arm64 and x86_64 UUIDs. The new pack failed more often in either order. Across both hosts, 20 of its 22 losses followed the platform marker and two followed the earlier fog-material marker. Every warm attempt completed.

| Order on each hosted Mac | PR #6 cold High losses | Build 111 cold High losses | PR #6 warm High losses | Build 111 warm High losses |
|---|---:|---:|---:|---:|
| Build 111 first | 2 / 17 | 11 / 17 | 0 / 17 | 0 / 17 |
| PR #6 first | 0 / 17 | 11 / 17 | 0 / 17 | 0 / 17 |

The failure predates the world overhaul, but the increased frequency follows the candidate across both Macs. App caches were private. Each host’s filesystem and driver caches were shared. A separate rotating same-pack experiment compares the full world, the integration fog shader on the new banks, the corridor hidden, and the unmodified world with the first fog draw at the platform. The normal acceptance workflow continues using the complete authored scene. [Every failed process log and Apple crash report](validation/milestone4/vulkan-device-loss.zip) · [Per-series counts, phase markers and backtraces](validation/milestone4/vulkan-device-loss.json) · [Matched Vulkan experiment](https://github.com/oiwdis/last-train-out/actions/runs/44864165485)

### Isolating the initial camera

In the first 64-process same-pack comparison, substituting the old fog shader and hiding the new corridor both left repeatable losses. The origin camera failed in four of 16 starts and the platform camera in zero of 16. One host saw no failures in any arm. In a separate 64-process two-host replication, the same signed pack lost the device in 11/32 origin starts and 0/32 platform starts. The cold-start treatment retains all subsequent interior and gameplay views. The first two views together prepare the same 82 specialization pipelines with either camera. The new placement prepares them together before uncovering the platform. On macOS, native Metal uses the platform on every preset. Low and Medium Vulkan start at the origin. [Four-arm controls and all failures](validation/milestone4/vulkan-world/README.md) · [Two further matched hosts](validation/milestone4/vulkan-world/replication/README.md) · [Real release process camera markers](validation/milestone4/first-fog-camera.json)

## The Ashford workshop floor

A review across presets also found yard asphalt showing through the maintenance floor. The new apron and the three building slabs shared the same top plane. All three buildings now meet the yard through their existing shallow thresholds with the finished floor four centimetres above the pavement. The real input journey completed 167 checks after the fix. [Geometry, before-and-after images and floor controls](validation/milestone4/ashford-floors/README.md)

The native screenshots compare build 111 to the revised floor at the same workshop camera on Low, Medium and High. [Three-preset native comparison](validation/milestone4/ashford-floors/native-comparison.jpg)

A thin bright strip behind the bench also appears on the original integration. Surface-color and shadow-bias controls reproduced it on the closed floor/wall joint. Rays through the lit pixels hit the floor and wall, and extending the wall changed none of the measured pixels. The common directional shadow settings still produce this small visual artifact. [Native comparison, ray hits and lighting controls](validation/milestone4/ashford-floors/wall-light-comparison.zip)

## Vulkan after a preset change

Build 117 lost the Vulkan device in three stock processes across two hosted Macs. The source lifecycle test and the exported default window failed on the build host. An independently downloaded default window on Apple Silicon also lost its device after completing the Low and Medium preparation views. The cold-start camera experiment exercised a different sequence. It recorded eleven losses in 32 starts at the origin and zero in 32 starts at the platform. The revised macOS Vulkan policy uses the platform only on initial High preparation. Later preset changes and Continue use the original camera placement. The paired experiment used the same build 117 data, fog, presets and save sequence under both camera policies. [Failed player and source logs](validation/milestone4/build-117/README.md) · [Cold-start replication on both hosts](validation/milestone4/vulkan-world/replication/README.md)

The same stock build 117 pack and executable were then tested on two additional hosted Macs with opposite starting orders. Each process began on Low and attempted three High changes, three real saves and Continues and a mission restart. Leaving the fog camera at the platform on later High preparations completed 1/8 full sequences and recorded 7 device losses. Returning that draw to the origin completed 7/8 and recorded one device loss. All eight platform processes reached the High camera. The single loss in the origin group happened during initial Low, before its first High change. The camera journal verifies the transform before each draw. Both hosts use a virtual GPU. [All attempts, partial checks, transforms and crash reports](validation/milestone4/vulkan-world/preset-switches/README.md)

### Export and renderer acceptance

| Build 118 check | Outcome |
|---|---|
| Rendered official Vulkan source lifetime and fog tests | 7/7 passed. All 22 subsequent camera phases recorded the world origin |
| Exported stock Vulkan window on the build host | 49/49 checks in the completed report |
| Independently downloaded stock window on Apple Silicon | 49/49 checks in the completed report |
| Independently downloaded native Metal window on Apple Silicon | 49/49 checks in the completed report |
| Independently downloaded Intel headless player | 46/46 checks in the completed report |

The Linux and macOS headless gameplay suites each passed 312/312. The rendered checks above independently exercise the drivers, preset changes and teardown. [Source, windows and per-process results](validation/milestone4/lifecycle-results.json) · [Unedited logs](validation/milestone4/raw-release-checks.zip) · [Full workflow](validation/milestone4/workflow.json)

All 22 active jobs passed. The optional performance-only dispatch and Developer ID signing and notarization jobs were skipped.

The independently downloaded native Metal executable completed 4/4 explicit worker shutdown probes. The archived diagnostic logs contain 0 ObjectDB or leaked-instance messages, 0 resource-in-use messages and 0 leaked allocation messages. The verbose engine logs also retain 4 occurrences of its static `servers` StringName and 96 MoltenVK memory snapshots emitted during device teardown. A crash or watchdog exit leaves teardown unverified for that process. [Searchable original warning text and filenames](validation/milestone4/shutdown-diagnostics.json) · [Integration ownership investigation](PERFORMANCE_MILESTONE351.md)

The stock Godot source investigation also ran the older 12-location workload at 960 × 540 on a different hosted GPU. The comparison used the original 3.5 integration commit `7df2f5abee54b8adcf27b8668263fba231a79033`. Both versions completed three Low launches and both 12-location timing passes. All ten processes kept their Vulkan device. The separate source recording completed. Two original-source processes, `baseline-startup-1` and `baseline-matrix-1`, logged a MoltenVK pipeline-cache write diagnostic. The previous build 117 had one Low candidate device loss here and three losses in the older source across starts and matrices. The 117 mixed production stress series also lost one warm High launch and all three preset/fog/Save/Continue processes. [All source attempts](validation/milestone4/stock-source-comparison.json) · [Source performance logs and complete timing data](validation/milestone4/stock-source-comparison.zip) · [Intermediate 117 results](validation/milestone4/build-117/README.md)

## Earlier development builds

[Build 111 owner ZIP, original timing matrix and recording](validation/milestone4/build-111/README.md) · [Build 115 native correction, Medium hitch and original Vulkan gate](validation/milestone4/build-115/README.md) · [Build 117 reproduced hot preset failures on two Macs](validation/milestone4/build-117/README.md)

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
MIN_TESTS=312 tools/run_tests.sh godot
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
