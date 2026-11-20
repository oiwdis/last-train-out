# Milestone 3.5 integration review

The integrated three-station game completes the full recorded survival journey, including Save/Continue. [Draft PR #6](https://github.com/oiwdis/last-train-out/pull/6) is ready for integration review; performance and visual acceptance remain open. Source PRs #4 and #5 remain unmodified and unmerged. This integration targets `claude/serene-turing-0vpdmt`, the actual default branch. See [provenance, plan and five conflict decisions](MILESTONE3_INTEGRATION.md).

[Download the universal macOS app](https://github.com/oiwdis/last-train-out/actions/runs/44460966340/artifacts/14501384087) · [23:24 full gameplay recording](recording/milestone35-full-journey.mp4) · [screenshot gallery](MILESTONE35_GALLERY.md) · [performance comparison](PERFORMANCE_MILESTONE35.md) · [physical M1 instructions](M1_MILESTONE35.md).

The app and native evidence use source `45c3b338a694f587b5290af0e8ce19208d0a702e` (CI merge checkout `d09ebfc90352ff840b5ab8ea66e34806bd3da158`). Subsequent evidence/documentation commits do not change the game. The ZIP is 292,523,782 bytes, contains `Last Train Out.app` with its own Godot runtime, and has SHA-256 `69b0ca231a9508b039015901218514d4cc305b07aa769d3e1149f1d7c65d47d3`. GitHub sign-in is required; Actions retains this download for 30 days. It is ad-hoc signed, not notarized.

## Implemented integration

- All authored character, first-person hands, locomotive, Harlow architecture and licensed assets are preserved alongside the continuous 4.26 km journey, fog, exposure, fuel, scavenging, storage, cargo, mission and save systems.
- Locomotive rods/wheels derive their phase from authoritative route distance, including restored journeys. Gauges remain speed, regulator and brake indications, not a simulated pressure system. Train physics are unchanged.
- Visible locomotive and carriage wheelsets now fit the shared 1.5 m rail spacing and 0.1 m railhead height at Harlow and on the route. The source locomotive's wheels sat inside the rails. Only wheel/axle/rod fittings and rendered route rails changed; vehicle bodies, route frames and ground collisions retain their dimensions. The inherited rod test retains its length/quartering assertions with the new rod-plane parameter.
- Save version 1 gains an optional validated camera block (perspective, yaw, pitch). Old M3 v1 saves remain accepted and retain the current camera preference. Held/loose cargo, containers, doors, fog RNG and mission ownership retain their M3 schema.
- The skinned pose solver ignores retired scene hierarchies during Continue/restart. This fixes a real transform-access error found through the Save/Continue buttons.
- Save loading waits for render preparation to release physics before resolving car-local rider/cargo transforms. The first native recording exposed a real race: physics-frame signals still emitted while the physics server was paused, putting saved riders and cargo back at Harlow. A regression reproduces both displacements before the fix and verifies them afterward. The validator now compares the complete saved snapshot, expected station and player world position. The journey is marked ready only after restoration.
- Ashford and Blackwater retain their modular shells, collision clearances, shelters and cache IDs. They now reuse Harlow’s PBR materials, architectural trim and locally batched licensed props. They remain visibly simpler than Harlow; full photorealism is not claimed.
- Startup/preset preparation covers both new stations and the actual custom fog shader. The export-only shader inventory is rebuilt from the shipped mission, including custom shaders. Preparation preserves simulation and the ledger’s pause state.
- Preparation captures UI focus and blocks the ledger hotkey until it finishes, preventing a visible ledger from accidentally resuming the simulation. The location HUD names Ashford and Blackwater and recognizes their train stops.

## Validation status

Both unchanged Linux baselines passed: PR #4 196/196, PR #5 246/246. The merged baseline passed all 274 distinct tests. Eighteen new combined-system regressions cover rigs, damage/cadence, carrying/grips, curve/grade and wheel/rail alignment, fuel/gauges, all-station and moving saves, camera validation/backward compatibility, paused render preparation and input, station materials/collision ownership, HUD names/stops, all danger states/presets, death/fresh scene, results and scene detachment. CI checks individual source-test identities as well as the 292-test floor. The final Linux suite passed **292/292** in 144.6 seconds, with zero engine errors; the identity guard confirms all 274 source tests still pass. Asset validation checks 31 models and 137 compressed, mipmapped textures.

The continuous headless journey passed **167 controls/collision assertions**: all three stations, approaching fog at the workshop, heavy-item abandonment, refueling after returning to the train, real Save/Continue UI and escape at 4,260.006 m after 23:12.8 simulation time. It records **zero travel teleports**, with one separately counted legitimate save restoration. Fuel exhaustion/recovery passed 35 checks; natural fog death passed 24; a cold second-process moving save passed 17. The source-mode packaged self-test script also passed; that is not a substitute for testing the exported app.

The final runtime cohort, [run 46](https://github.com/oiwdis/last-train-out/actions/runs/44460966340), passed **292/292 native automated tests in 120.7 seconds**, the full headless journey and all additional scenarios, the complete performance matrix/source comparisons, and the uninterrupted native recording. The recording passes **167 checks**, including actual Blackwater restoration and escape, with **zero travel teleports and one legitimate save restoration**. Its 23:24 duration includes 23:13.6 simulation time, scene loading and the final results. This is a controls-driven automated journey using real collision, train and fog updates. The engine records Medium at 960×540 and 12 FPS; capture rate is not measured game performance. The full MP4 was decoded without errors and sampled frames were visually inspected. [Raw reports, logs, media metadata and provenance](validation/milestone35/native-final/README.md) are retained in the repository.

| Check | Result |
|---|---:|
| Unchanged source baselines | PR #4 196/196; PR #5 246/246 |
| Distinct source-test identities retained | 274/274 |
| Integrated Linux / native macOS suite | 292/292 / 292/292 |
| Full journey, headless / recorded native | 167/167 / 167/167 |
| Fuel exhaustion and recovery / natural fog death | 35/35 / 24/24 |
| Cold second-process moving save | 17/17 |
| Rendered Blackwater save regression, Linux | 9/9 |
| Exported ARM app, headless / windowed | 46/46 / 49/49 |
| Fresh download ARM app, headless / windowed | 46/46 / 49/49 |
| Fresh download Intel app, headless | 46/46 |

Fresh-download ARM gameplay checks passed, but the separate packaged diagnostic in attempt 1 lost its Vulkan device during High-preset preparation. Retrying the **identical ZIP** on a fresh hosted runner passed the 46 headless and 49 windowed checks and all **81 packaged diagnostic cases** (6 preset, 3 route, 72 entry/steady matrix rows). The short matrix still logs one resource in use at shutdown, despite emitting all rows and exiting zero; this diagnostic cleanup issue remains open. Run 46 attempt 2 is green; [both attempts are retained](validation/milestone35/native-final/README.md). The device-loss cause remains unresolved; the retry does not establish a rendering fix or physical-device performance.

The first native cohort, [run 44](https://github.com/oiwdis/last-train-out/actions/runs/44454434954), completed the full performance matrix and universal export/fresh-download checks, but its recording failed at the load race. Its data and failed recording log are preserved under [native-run44](validation/milestone35/native-run44/). The corrected runtime is `140ce820c087d8a28734b7bab3ed14135d7cc527`; its rendered Blackwater regression passes. [Run 45](https://github.com/oiwdis/last-train-out/actions/runs/44459211814) passed 292/292 but exceeded the old exported-self-test timer during graphics preparation; its [failed reports](validation/milestone35/native-run45/) remain available. Commit `45c3b338a694f587b5290af0e8ce19208d0a702e` increases that test budget to 240 seconds while preserving every assertion and the 300-second launcher limit. This is a test-budget correction, not faster startup. The CI finalization check now fails if required performance/recording steps fail, after retaining their artifacts.

## Current limitations

- The [measured performance report](PERFORMANCE_MILESTONE35.md) retains both cohorts, every entry/steady distribution and source comparison. The final cohort has a **2.51 s High entry stall**, a **0.94 s High near-fog steady outlier**, and **78.60 s exported mission readiness**. Warehouse B means are 1–9% slower than PR #4 in this cohort; High cab/passenger views also regress. Severe stutter and long startup remain unresolved despite good averages and zero steady pipeline-counter deltas.
- The fresh ARM packaged benchmark lost its Vulkan device during High preparation in run 46 attempt 1. The same app passed its windowed gameplay checks; the device-loss cause is not established and is not attributed to physical M1 hardware.
- Ashford and Blackwater use reusable PBR finishes and props on simple modular shells. Surrounding terrain is broad and sparse; close character detail, repeated surfaces, bright track surfaces and distant cutaway edges remain below a photorealistic reference. Interaction labels become oversized at close range. Low is visibly coarse at its internal render scale. No missing-texture error appeared in the native runtime logs, but that does not establish visual perfection.
- Hosted Apple Silicon uses a paravirtual GPU with no usable GPU-time counter. Intel checks are headless. Neither establishes physical-device graphics performance.
- The development app is ad-hoc signed, not notarized. Optional Developer ID signing/notarization remains available in the existing workflow.

## Hardware acceptance

A physical 2020 M1 Mac in fullscreen is unavailable here. Hosted Apple Silicon and Linux software rendering are separate test environments and do not establish the 30 FPS Low target on that hardware. The packaged `res://scripts/diagnostics/integration_benchmark.gd` provides a reproducible twelve-location, all-preset benchmark; [physical M1 procedure](M1_MILESTONE35.md) records frame distributions, resolution, renderer and startup preparation. The measured limitations accompany the raw evidence and comparison tables.

## Merge path

Keep this PR in draft while reviewing the documented performance, visual and hardware gaps. After those are resolved or explicitly accepted, use a normal merge into the actual default branch to retain both feature histories. Close the older source PRs as incorporated afterward; do not merge their stale bases separately. No PR is merged automatically and repository defaults are unchanged.
