# Milestone 4 environment overhaul

Milestone 4 is stacked on the open, unmerged PR #6 at `684df38f0d9ba39a876d4788696855f0b64d5b29`. PR #7 targets `integration/milestone-3-5-photoreal-survival`. The route, rolling stock, survival simulation, save format and renderer selection come from that integration. [Development PR #7](https://github.com/oiwdis/last-train-out/pull/7) · [Integration PR #6](https://github.com/oiwdis/last-train-out/pull/6) · [Renderer history](PERFORMANCE_MILESTONE354.md)

## What changed in the world

| Owner observation | Diagnosis | Change in the playable mission |
|---|---|---|
| Harlow track was bright white | Journey construction removed the material-assigned Harlow main line. The replacement straight track had empty material slots for its rail, timber and ballast. The straight extended beyond the start of the swept line. | Keep and trim the authored main line at route metre 280. Use the same weathered web, burnished steel head, scanned wood and gravel on the straight, siding and swept track. A crowned rail profile catches a narrow highlight. Exposure and sunlight retain their original values. |
| Daylight showed between the brickwork and green wall in Bonded Stores | The kit's outward-facing brick skin sits at local Z 4.88 m. The green side walls ended at 4.60 m. Their scaled bevels opened additional gaps at the corners. | Build a continuous masonry return and inward-facing leaf between those surfaces. Cut it to match the kit's actual upper glazed openings. Square the structural ends, rear wall and roof. Apply the same joint to the second Harlow warehouse. The working side-door passage retains its collision opening. |
| Abrupt edges and bare gray ground through curves | Independent, 620-metre-wide rectangular ground boxes rotated with individual chord segments. Inside a bend they overlapped, and outside a bend their edges separated. The tops also obscured authored station paving. | Sweep a continuous strip through route cross sections. Share its outermost points between chunks and derive collision from the very same triangles. Gravel shoulders lead to drainage, scanned turf, groups of scrub and trees, telegraph wires and fences. |
| Fog resembled a uniform gray mass | The front used overlapping flat sheets and a largely uniform height falloff. Observer fog predominantly changed the scene's overall density. | Use bowed, irregular banks, a wind-advected density field and observer-dependent scattering. The four hazard states, warning HUD and survival calculations continue to use the original simulation. |
| Ashford was sparse and Blackwater objectives were hard to recognize | Much of each station was a single undifferentiated ground slab around similar buildings. Small objects did little to identify the next station from a train. | Differentiate Ashford with freight-handling equipment and a maintenance yard. Give Blackwater a road crossing, cottages, a station frontage, a shop awning and evacuation-register signs. The original caches and note retain their positions. |

### Track, terrain and materials

The original baked Curve3D still determines train placement and travel distance. Each 120 m terrain section contains cross sections every 6 m. The inside 18 m follows the rail's local lateral axis. Farther out, widening runs toward world north and south, keeping distant rim vertices from folding over on a curve. Both neighboring chunks sample the same rim, including UV coordinates and elevation. A route-wide raycast found 205 of 1,105 tree and scrub roots floating over 35 cm in the first revision. Planting each instance on its actual mesh triangle puts all 1,105 roots between 4.49 and 4.51 cm beneath the surface. The same sampling locates pole and fence feet. All 43 chunks retain physical ground. Nearby visibility extends 520 m along the corridor and exceeds the 350 m review-camera range. The track shoulder provides standing room for moving ladder boarding. The drainage channel begins outboard of that shoulder.

The corridor ships as a compressed scene with mesh, collision, instance transforms and batch bounds baked together. A matching route geometry signature selects it during ordinary threaded mission loading. A custom route can rebuild its own geometry. A bulk transform buffer and explicit bounds preserve rail sleepers and vegetation on headless build machines. Ties, poles, fences and cutout foliage are batched or range-limited. An original atlas with four alder and scrub variations and seamless fog field supplement the existing licensed environment kit. Rob Tuytel's CC0 grass-and-rock scan supplies colour and relief. The asset manifest records the source files and digests. [Material provenance](../assets/pbr/sources.json) · [Original texture generator](../tools/build_route_atmosphere.py) · [Corridor bake](../tools/assets/bake_route_corridor.gd)

### Fog and stations

The banks move with the existing route front. Individual layers have different widths, irregular heights and curved profiles. Their separation across 16 m intervals yields parallax as the player or train moves. Two mipmapped texture lookups drive broad changes in density and slower filaments. Distance fog attenuates the actual train, buildings and distant ground. Desaturation, light colour and sky response increase further inside. Low draws two layers, Medium four, and High six. Medium uses ordinary distance fog and these meshes. All share the same shader and existing material-preparation lifetime. High retains the integration's separately controlled volumetric setting.

Ashford's transfer gantry spans the loading pads. An elevated coal tipple, inclined conveyor, freight siding, box van and weathered containers identify the yard. Numbered bays stage uncollected crates. Tool storage, an overhead pipe and fitter's bench distinguish the workshop interior. Fixed architectural footprints share the station's original static collision body. Dressing may disappear at detail range independently of the permanent surfaces the player walks on.

Blackwater has crossing gates, painted stop lines, a main road, gabled houses, utility lights and a parked delivery van. An awning and window frames distinguish Crossing Stores. A second sign points to the evacuation register, and the track-crew shed identifies its coal reserve. Shallow concrete thresholds join the outdoor grade to the existing walk-through doorways.

## Inspection and validation method

The source baseline passed 305/305 on pinned Godot 4.5.1. Four additional scene inspections exercise the live mission. They check rail surface assignments and junction alignment, both directions through the masonry return, door and window structure, all 42 terrain joins, ground raycasts on both sides of bends, saved instances and bounds, fog mesh depth, texture assignments, station landmarks and physics ownership. The unchanged gameplay suites still exercise moving ladders, interiors, heavy cargo, rider restoration, saves and outcomes. [Scene inspections](../tests/integration/test_environment_overhaul.gd)

The matched Metal review uses the PR #6 build 104 download with ZIP SHA-256 `95d5ccbc65700a2d1f7b8e641eef3fd880f35b34221d09077ebd58a45a49b5ee`. One shared external camera script runs against each exported PCK, using the packaged Apple Silicon selector. The curved view looks along a 14.6-degree change of heading over 145 m, starting at route metre 2,020. A separate process captures each game at the same 16 coordinates, three presets and 960 × 540 window size. Camera, target, observer and danger-front coordinates are recorded and compared. The separate image passes remove the route and inventory panels and keep the warning overlay in fog views. Motion in individual wisps follows the running shader clock.

The camera fixture repositions the observer for repeatable views. The independent full-route validation uses movement and interaction inputs to travel between stations. Timing passes keep the gameplay UI and disable VSync. Each pose records 60 entry intervals, 48 settling frames and 180 steady intervals, in two new processes per build with the order reversed for the repeat. Every measured interval is retained. Preset preparation, scene construction, first draw and ordinary cold/warm player launch use separate records. The selector-to-play test uses system audio. The fixed-view matrix uses the dummy audio driver. App shader caches are private per build and ordinary-player preset. The runner and its OS/driver caches are shared. GPU and CPU counters describe different parts of the pipeline and can overlap. Static engine memory excludes allocations in other libraries. RSS is polled independently. [Measurement driver](../tools/macos/compare_environments.py) · [Benchmark scene](../scripts/diagnostics/integration_benchmark.gd)

## Physical 2020 M1 procedure

The owner's previous native Metal fullscreen observations were approximately 60 FPS on Medium in ordinary gameplay and in fog, approximately 30 FPS on High normally and 20–25 FPS on High in fog. Physical validation of the revised game is pending. The hosted comparison uses a paravirtual GPU.

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

## Universal development build

Build 108 packages the runtime source at `9b6f67cd15cc12fecb64bbc3112b39fd4a307dc5`. The PR test-merge embedded in the bundle is `13d7cbde24b62ef23ec6426d42ab58e699e9c64a`, whose Git tree matches the branch revision. The independently downloaded 340,416,790-byte ZIP has SHA-256 `e9b7573db2dd05a4109eb7c82bef304173c0ae8b1f598b707fc725dea3afd639`. The pack digest is `2a00fdd9c90987660c5c4e9e06730b710eb9de5230cb73b30b167afed4c5bcee`.

The ZIP contains one `Last Train Out.app`. It includes its Godot 4.5.1 runtime, a universal arm64/x86_64 default executable and selector, and the opt-in arm64 native Metal executable. The pack includes all 385 checked project files, the baked corridor and the new shader/texture assets. The packaged shader profile contains 97 native source groups and 82 matching precompiled library groups. Build 104 contained 94 and 83 respectively. Of its source groups, 93 retain identical SHA-256 hashes. Four groups enter the new scene inventory and one retires. [Shader inventory comparison](validation/milestone4/shader-groups.json) Source-only fallback is available on other device profiles. This is an ad-hoc-signed development build. [Universal ZIP](https://github.com/oiwdis/last-train-out/actions/runs/44850871725/artifacts/14686450857) · [Independent build receipt](validation/milestone4/development-build.json) · [ZIP verification](validation/milestone4/zip-verification.log) · [Workflow](https://github.com/oiwdis/last-train-out/actions/runs/44850871725)

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
MIN_TESTS=309 tools/run_tests.sh godot
python3 tools/check_integration_tests.py tests/_output/results.json
```

## Build 108 native review

The first matched native Metal comparison exposed a Medium terrain defect which the Linux geometry and rendered inspections missed. On the hosted Metal adapter, 19.04% of the curve image and 22.31% of the Crossing Stores image were near black (all three 8-bit channels below six). The equivalent reference, candidate Low and candidate High views each measured under 0.01%. The black regions cover ground which the collision and raycast checks confirm is present. Build 108 is unsuitable for owner acceptance. Its pictures and frame times remain evidence of this first attempt. [Matched gallery](validation/milestone4/GALLERY.md) · [All frame times](validation/milestone4/FRAME_TIMES.md)

Across 5,760 steady intervals per preset and revision, the Medium p95 fell from 12.35 to 10.26 ms. Inside dangerous fog it rose from 8.53 to 11.34 ms. Medium cold selector-to-play time rose from 25.27 to 36.40 s, including an increase from 7.17 to 12.06 s for threaded resource loading. On this launch the fog preparation phase grew from 6.48 to 10.25 s. The largest High entry frame was 758.33 ms on the first Harlow platform frame after changing preset. The same measurement on the repeat was 229.05 ms, and on the reference repeat it was 599.47 ms. The measured pipe counters were unchanged across these intervals. No GPU timestamps were exposed by this adapter. [Player startup](validation/milestone4/launches.csv) · [Raw session evidence](validation/milestone4/raw-environment.zip)
