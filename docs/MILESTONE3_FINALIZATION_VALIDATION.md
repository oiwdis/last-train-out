# Milestone 3 finalization validation

The Harlow Escape is a playable 4.26 km journey through Harlow Junction, Ashford Industrial Depot and Blackwater Crossing. The train follows connected curves and grades, stops at each platform, consumes fuel and carries the same player, cargo and inventories throughout. The existing advancing fog never resets at arrival. Mission objectives lead to an escape/failure ledger; J exposes the versioned manual Save / Continue / New / Restart interface.

This work continues [draft PR #5](https://github.com/oiwdis/last-train-out/pull/5). PR #4 and its checkout were not modified, merged or rebased. No integration branch was created.

## Play and review

- [Route, station content, controls, mission and save format](MILESTONE3_JOURNEY.md)
- [Continuous gameplay video](validation/milestone3-finalization/harlow-escape-continuous.mp4)
- [Recording provenance and media properties](validation/milestone3-finalization/recording.json)
- [Measured performance against `ebfa2689`](PERFORMANCE_MILESTONE3_FINALIZATION.md)
- [PR #4 integration plan](MILESTONE3_INTEGRATION.md)
- [Current build and native check links on PR #5](https://github.com/oiwdis/last-train-out/pull/5)

## Automated and gameplay evidence

Godot **4.5.1**, Jolt, 60 physics ticks per second. The original **214/214** tests passed before implementation. The expanded suite has **246/246** passing on Linux and macOS. No tests were disabled. Two old startup-scene assertions now name the inherited Harlow Escape scene. The original sandbox remains available to legacy fixtures.

The 32 added tests cover connected route arcs/projection/grades, arrivals and departures, persistent fog/events, fuel shortage and refueling, station IDs/content/collision, mission completion/failure, full save validation and ownership, repeated loads, alternate seeds, held/loose cargo, moving riders, curve traversal/boarding, scene restart and graphics independence. The pause/results panel is also checked to fit the viewport with visible actions. The standard runner includes resource import, missing-asset/error detection and a 600-frame main-scene smoke test. Native exports independently validate the shipped main scene before running their legacy mechanics checks.

Evidence: [baseline tests](validation/milestone3-finalization/baseline-tests.json), [Linux tests](validation/milestone3-finalization/linux-tests.json), [Linux log](validation/milestone3-finalization/linux-tests.log), [macOS tests](validation/milestone3-finalization/macos-tests.json), and [all 214 baseline test names preserved](validation/milestone3-finalization/test-preservation.json). The isolated journey integration suite also passes all 21 tests. Its cold-load check exposed a GDScript resource-order issue; deferring the default route load until script classes finish loading fixes it without changing fog simulation.

| Requested scenario | Executed evidence |
|---|---|
| A — Complete journey | Actual movement, aimed E interactions, storage R and train controls from Harlow to escape. All three stations visited, every objective completed, zero teleports. [Fast Linux run](validation/milestone3-finalization/continuous-journey-fast.json), [macOS run](validation/milestone3-finalization/macos-continuous-journey.json), and the full recorded late-escape run below. |
| B — Fuel shortage | Collect Harlow coal into storage, depart without stoking, burn the initial boiler dry at about 1,359 m, stop between stations, attempt the empty regulator, stoke the collected sack using E and continue to Ashford. **35 checks**, zero teleports; no fuel/inventory injection. [Report](validation/milestone3-finalization/fuel-shortage-gameplay.json). |
| C — Fog escape | Wait in Ashford's distant workshop for the naturally advancing front, carry the heavy spares back, abandon them with G, sprint through the yard and board. The first recorded run reached the cab with roughly 80 m train clearance and escaped. Fog time/front are never edited. [Recorded run report](validation/milestone3-finalization/continuous-journey.json). |
| D — Fog catches train | Stay in the stationary cab at Harlow while the front advances from its normal initial position. Dose rises, health falls and the mission fails at about 433 seconds. **24 checks**, zero teleports, no exposure/front injection. [Report](validation/milestone3-finalization/stranded-gameplay.json). |
| E — Save and resume | One process creates and writes a moving-world save; a separate cold process loads it and continues riding. **13 checks** cover train/fog/RNG, health, storage/backpack, held cargo, depleted cache and mission note. [Report](validation/milestone3-finalization/process-resume.json). The initial mid-route setup is explicitly a fixture, not part of the continuous video. |
| F — Heavy cargo | Physically carry and deposit three coal sacks across Harlow/Ashford. Search the distant Ashford workshop, pick up a machine component, wait for danger, carry it back through the doorway and drop it to escape. Included in the continuous video and its **142 checks**. |
| G — Camera/traversal | Continuous video switches first/third person and walks through all three cars. Integration tests additionally aim/E-board a ladder during curved departure, climb onto the roof, switch perspective, and walk all three cars on a live curve. These tests use labelled initial-position fixtures; they are not presented as footage. |

The validator controls the real PlayerInput and camera reticle; it does not call loot completion, refuel, objective completion, teleport, train-position or fog-front setters in scenarios A–D/F. Its script is [validate_journey.gd](../tools/validate_journey.gd). A failed interaction fails the run. Direct simulation setup is confined to unit/integration and process-resume fixtures.

## Recording and station screenshots

The full MP4 preserves the continuous journey at normal simulation time, including the deliberate Ashford wait. Godot Movie Maker captures **1280 × 720 at 8 FPS**, Low preset, Compatibility renderer on the cloud software GPU. Audio is included. This capture cadence is not measured game frame rate. The file is encoded from one uninterrupted AVI; no location cuts or accelerated sections substitute for travel. Exact duration, source commit, frame count and SHA-256 are in [recording.json](validation/milestone3-finalization/recording.json).

The refreshed video is **23:15.25**, including a four-second paused results hold. Movie Maker logged one `ObjectDB instances leaked at exit` warning after completing the AVI and all 142 checks; it is retained in the [capture log](validation/milestone3-finalization/continuous-journey.log). The full automated suite, normal game smoke and native exported-app checks pass without engine errors. This capture-process cleanup warning is not presented as a clean shutdown.

The fast bot completes the objectives in about **12:21**. The late-escape recording lasts about **23 minutes**, including a deliberate wait for the front. Neither establishes a novice's 20–40-minute first-play duration. That remains an acceptance playtest; route, speed, fog, fuel and cache quantities are configurable.

| View | Screenshot |
|---|---|
| Harlow departure | [Player view](validation/milestone3-finalization/01_harlow_departure.png) |
| Ashford industrial yard | [Overview](validation/milestone3-finalization/ashford-overview.png) · [Arrival](validation/milestone3-finalization/02_ashford_arrival.png) |
| Distant workshop / urgent return | [Workshop](validation/milestone3-finalization/ashford-workshop.png) · [Heavy return](validation/milestone3-finalization/04_ashford_heavy_return.png) · [Cab at departure](validation/milestone3-finalization/04_ashford_late_escape.png) |
| Blackwater settlement | [Overview](validation/milestone3-finalization/blackwater-overview.png) · [Arrival](validation/milestone3-finalization/05_blackwater_arrival.png) · [Evacuation log](validation/milestone3-finalization/06_blackwater_evacuation.png) |
| Menu and completed mission | [Save menu](validation/milestone3-finalization/route-save-menu.png) · [Results](validation/milestone3-finalization/07_results.png) |

Numbered images come from the continuous run. Overview/interior stills are explicitly separate camera/profiling fixtures. New stations use reusable functional building shells and existing materials; they are **not photorealistic**.

## Native application

GitHub Actions produces `LastTrainOut-macos-universal.zip`, containing `Last Train Out.app` with the runtime and project data. Export excludes tests, tools and evidence/video files. The pipeline runs the complete suite plus continuous journey, natural fuel/fog scenarios and two-process resume, verifies the universal bundle and ZIP, and launches the exported app on native macOS runners. Apple Silicon has headless and windowed checks, repeated after artifact download. Intel validates fresh-download headless startup; its runner has no usable GPU for windowed testing.

The current download/run links and final head commit are in the PR description. Retained [CI metadata](validation/milestone3-finalization/macos-ci-f506d45.json) and exported-app JSON reports document the captured gameplay source. Native macOS also passes the [fuel-shortage](validation/milestone3-finalization/macos-fuel-shortage-gameplay.json), [stationary fog catch](validation/milestone3-finalization/macos-stranded-gameplay.json) and [cold resume](validation/milestone3-finalization/macos-process-resume.json) checks. GitHub pull-request workflows check out a synthetic merge revision: the artifact's PR head and the checkout revision in a gameplay report can differ. This is normal CI provenance, not a gameplay reset.

This is an **ad-hoc signed development build**, not a notarized release. Existing optional Developer ID/notarization support remains available and was not invoked. GitHub artifact downloads require repository access and expire under the workflow retention policy. See [macOS launch instructions](../README.md#play-on-macos-no-godot-needed).

## Remaining acceptance work and merge recommendation

- A physical **2020 M1 in fullscreen** has not been tested. Virtual Apple Silicon launch checks and Linux llvmpipe measurements do not prove its sustained frame rate. High is expensive on the software renderer. The new resident world adds about **18.8 MiB** of engine-managed static allocation in the matched Harlow view.
- The requested 20–40-minute novice pacing, visual readability and final difficulty still need an unassisted human playthrough. Automated input validates mechanics and continuity.
- The new station art is modular and functional. PR #4's photorealistic assets, renderer choices and performance work remain separate; combined regression/performance testing has not happened.
- This is a three-station resident world. Future 10–15-station streaming/branch choice is an extension point, not implemented. Current save UI has one manual slot, requires grounded/settled actions and stores one local controllable player; no autosave, multiplayer transport, hub, rescue NPCs, coins or rewards were added.

**Keep PR #5 draft for acceptance and PR #4 integration review.** The implemented journey and native development build are ready for review/playtesting; physical-device performance, novice pacing and combined art integration are not yet established. Do not merge automatically.
