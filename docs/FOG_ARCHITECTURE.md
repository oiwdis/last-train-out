# Advancing fog architecture

Milestone 3 starts at M2.5 commit `8cde10cf78c1ea0cf7f7bafb5fc146d2e12514c2` (PR #3). It contains no M2.6 commits. The target branch is `feature/milestone-2-5-full-3d`; no merge is requested.

## Authority and route coordinates

`FogSimulation` is a node-free, fixed 100 ms simulation. `advance(delta)` retains fractional ticks; the live `FogSystem` adapter uses the same `step()` and ticks exposure once per simulation step. Speed escalation and seeded event scheduling depend on simulation time, never wall-clock, camera, frame rate, quality, or player distance. The front is not tethered to the train. Negative route metres place it behind the starting station.

`FogRoute` is an ordered itinerary of `FogRouteSegment` resources containing baked Curve3D geometry, stable segment IDs and outgoing IDs. It converts route metres to world points/tangents and projects world positions back onto the route. Segment hints disambiguate crossings. Segments must be connected, nonzero-length, and ordered in travel direction. Route sample points are world coordinates. A future branch authority chooses the itinerary; propagating several simultaneous branch fronts is **not implemented**. Extension before the first/after the last segment prevents clamping players to safe endpoints.

The shipped Harlow route follows the actual M2.5 track from `(15, 0, -3.5)` in +X. `FogSystem` is the only adapter aware that the existing train uses a straight route and `Train.distance`. Curved sampling/projection and segment crossing are tested independently; the train itself does **not** gain curved-track physics.

`enter_station(id)` selects an authored station marker without resetting time, front, RNG, warnings, or doses. The baseline contains only Harlow Junction and about 480 m of train travel. No second station, route streaming, or endless-world content was invented. Station transitions are API/integration tested, not a playable second stop.

## Player dose and failure

A registry maps stable player IDs to Player + FogExposure components and an optional segment hint. Each player receives independent dose, health, shelter and route position. Presentation currently follows the local player, while authority has no one-player limit. `unregister_player` handles removal.

Exposure grows with time, depth (capped at 3x), difficulty and unprotected fraction. Damage starts after 15 dose units; it is progressive rather than instant. Safe air recovers exposure, not health. Remaining exposure slows stamina recovery; only extreme exposure reduces movement speed, by at most 18%, after the existing heavy-cargo cap. Combat and healing items are outside scope.

Explicit `FogShelter` bounds follow train cars/building transforms. Closed cab, closed crew car, leaking buildings/open doors and open platforms have different protection. Roofs lie outside bounds; unknown interiors are outdoors. No shelter provides immunity. Dead players release cargo through the existing ownership API, cancel searches and lose control. R starts a new run. Train/player debug teleports do not reset the fog; the explicit whole-station/new-run reset does.

## Train and fuel

`FogFuel` consumes boiler reserve while the train is moving, brakes through `Train.stop()` on exhaustion, and gates `Train.start()` through one optional Callable. The motion integration, braking curve, collision and moving-platform code are unchanged. E at the cab bunker burns one **stored** coal sack if all 45 fuel units fit. No automatic withdrawal steals stored items. Existing storage, carrying, stack limits and searches remain intact.

## Events and presentation

Surge, calm, dense-front and disturbance events are seeded. All get a 10-second announcement; no event stacks or overwrites another. Only surge/calm affect speed. A surge can never teleport the front. Warnings apply to the less safe of the train and local player so a deep-warehouse search cannot hide that the return route is already dangerous.

`FogPresentation`, `FogHUD` and `FogAudio` read state. Two/four/six transparent boundary sheets on Low/Medium/High follow the route tangent. Ordinary distance fog blends in only near the observer; High does not add an expensive volumetric pass. The existing optional station volumetrics and graphics fallbacks remain intact. No full-screen blur or camera shake is used. Sheet motion provides subtle distortion; there are no enemies or humanoid silhouettes.

Audio layers are original deterministic synthesis: low rumble, filtered wind, breathing and metallic cues. A temporary local world-audio bus gradually low-pass filters existing ambience near the front; it is removed on teardown. Gameplay RNG is never used for audio/visual noise. `tools/generate_fog_audio.py` reproduces every new WAV using Python's standard library; no external samples/licenses are required.

F3 toggles exact front/train/player/segment/speed/seed/time/shelter diagnostics. Ordinary HUD shows rounded clearance, danger, relevant dose/health, event warnings and low/aboard fuel information. Inventory screens do not pause danger. Graphics settings never enter simulation/exposure calculations.

## Persistence and future synchronization

`FogSimulation.snapshot()/restore()` covers version, route fingerprint, tuning, time/front/subtick, station, event/warning timing and RNG state. Large RNG integers are decimal strings for JSON safety. Restoration validates before mutation and rejects incompatible routes/configuration. Float roundtrips are verified to numerical tolerance. `FogSystem.snapshot()/restore()` additionally saves registered doses, fuel and authority subtick.

These are survival-state APIs, **not a complete save-game feature**: callers must save train/player transforms, inventory and world ownership separately, and register the same player IDs before restoring. No disk-save menu or network dependencies are added. Future server: own `step`, station changes and exposure; replicate snapshots/ticks to clients; render from authoritative state. This is practical same-build determinism, not a promise of cross-platform bitwise lockstep.

## M2.6 integration notes

All character, train, station, animation, material and environment assets are untouched. New logic lives in `scripts/fog`, `resources/fog`, and the existing placeholder `systems/fog_system.gd`.

Shared-file changes that may need manual merging:

- `scripts/main/game.gd`: deferred fog binding after interiors/graphics, reset ordering, real surge message and fuel failure feedback.
- `scripts/player/player.gd`: one survival multiplier after the existing heavy-carry speed cap.
- `scripts/player/player_stamina.gd`: one regeneration multiplier.
- `scripts/train/train.gd`: optional departure gate only; no integrator edits.
- `scripts/main/self_test.gd`: six exported-fog checks.
- `.github/workflows/macos-app.yml`: M2.5 PR target and minimum test count only; retain M2.6's asset-validation/cache/benchmark additions when integrating.
- Existing placeholder assertions in `test_station_systems.gd` now expect real danger/warnings.

Cab/crew shelter bounds and bunker interaction currently match the M2.5 collision interiors, and read `TrainInterior.doors`. If M2.6 changes collision layout, adjust those explicit bounds in `_build_shelters`, not the art. `FogPresentation` obtains the current per-scene Environment **after** GraphicsSettings duplicates it; keep that ordering. Route curves must be authored in world space or transformed by a future route adapter. Always rerun the combined test suite and graphical smoke after integration.
