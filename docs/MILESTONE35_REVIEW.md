# Milestone 3.5 integration review

Draft work in progress. Source PRs #4 and #5 remain unmodified and unmerged. This integration targets `claude/serene-turing-0vpdmt`, the actual default branch. See [provenance, plan and five conflict decisions](MILESTONE3_INTEGRATION.md).

## Implemented integration

- All authored character, first-person hands, locomotive, Harlow architecture and licensed assets are preserved alongside the continuous 4.26 km journey, fog, exposure, fuel, scavenging, storage, cargo, mission and save systems.
- Locomotive rods/wheels derive their phase from authoritative route distance, including restored journeys. Gauges remain speed, regulator and brake indications, not a simulated pressure system. Train physics are unchanged.
- Visible locomotive and carriage wheelsets now fit the shared 1.5 m rail spacing and 0.1 m railhead height at Harlow and on the route. The source locomotive's wheels sat inside the rails. Only wheel/axle/rod fittings and rendered route rails changed; vehicle bodies, route frames and ground collisions retain their dimensions. The inherited rod test retains its length/quartering assertions with the new rod-plane parameter.
- Save version 1 gains an optional validated camera block (perspective, yaw, pitch). Old M3 v1 saves remain accepted and retain the current camera preference. Held/loose cargo, containers, doors, fog RNG and mission ownership retain their M3 schema.
- The skinned pose solver ignores retired scene hierarchies during Continue/restart. This fixes a real transform-access error found through the Save/Continue buttons.
- Ashford and Blackwater retain their modular shells, collision clearances, shelters and cache IDs. They now reuse Harlow’s PBR materials, architectural trim and locally batched licensed props. They remain visibly simpler than Harlow; full photorealism is not claimed.
- Startup/preset preparation covers both new stations and the actual custom fog shader. The export-only shader inventory is rebuilt from the shipped mission, including custom shaders. Preparation preserves simulation and the ledger’s pause state.
- Preparation captures UI focus and blocks the ledger hotkey until it finishes, preventing a visible ledger from accidentally resuming the simulation. The location HUD names Ashford and Blackwater and recognizes their train stops.

## Validation status

Both unchanged Linux baselines passed: PR #4 196/196, PR #5 246/246. The merged baseline passed all 274 distinct tests. Seventeen new combined-system regressions cover rigs, damage/cadence, carrying/grips, curve/grade and wheel/rail alignment, fuel/gauges, all-station and moving saves, camera validation/backward compatibility, paused render preparation and input, station materials/collision ownership, HUD names/stops, all danger states/presets, death/fresh scene, results and scene detachment. CI checks individual source-test identities as well as the 291-test floor. The final Linux suite passed **291/291** in 141.2 seconds, with zero engine errors; the identity guard confirms all 274 source tests still pass. Asset validation checks 31 models and 137 compressed, mipmapped textures.

The continuous headless journey passed **166 controls/collision assertions**: all three stations, approaching fog at the workshop, heavy-item abandonment, refueling after returning to the train, real Save/Continue UI and escape at 4,260.006 m after 23:12.8 simulation time. It records **zero travel teleports**, with one separately counted legitimate save restoration. Fuel exhaustion/recovery passed 35 checks; natural fog death passed 24; a cold second-process moving save passed 17. The source-mode packaged self-test script also passed; that is not a substitute for testing the exported app.

Native build, complete recorded journey, native visual review and measured performance evidence are pending in this draft. Do not treat a clean merge or separate source results as combined acceptance. Results and artifact links will be added after actual execution.

## Hardware acceptance

A physical 2020 M1 Mac in fullscreen is unavailable here. Hosted Apple Silicon and Linux software rendering are separate test environments and do not establish the 30 FPS Low target on that hardware. The packaged `res://scripts/diagnostics/integration_benchmark.gd` provides a reproducible twelve-location, all-preset benchmark; [physical M1 procedure](M1_MILESTONE35.md) records frame distributions, resolution, renderer and startup preparation. Measured limitations will accompany the evidence.

## Merge path

Review and approve this integration PR, then use a normal merge into the actual default branch to retain both feature histories. Close the older source PRs as incorporated afterward; do not merge their stale bases separately. No PR is merged automatically and repository defaults are unchanged.
