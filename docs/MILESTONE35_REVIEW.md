# Milestone 3.5 integration review

Draft work in progress. Source PRs #4 and #5 remain unmodified and unmerged. This integration targets `claude/serene-turing-0vpdmt`, the actual default branch. See [provenance, plan and five conflict decisions](MILESTONE3_INTEGRATION.md).

## Implemented integration

- All authored character, first-person hands, locomotive, Harlow architecture and licensed assets are preserved alongside the continuous 4.26 km journey, fog, exposure, fuel, scavenging, storage, cargo, mission and save systems.
- Locomotive rods/wheels derive their phase from authoritative route distance, including restored journeys. Gauges remain speed, regulator and brake indications, not a simulated pressure system. Train physics are unchanged.
- Save version 1 gains an optional validated camera block (perspective, yaw, pitch). Old M3 v1 saves remain accepted and retain the current camera preference. Held/loose cargo, containers, doors, fog RNG and mission ownership retain their M3 schema.
- The skinned pose solver ignores retired scene hierarchies during Continue/restart. This fixes a real transform-access error found through the Save/Continue buttons.
- Ashford and Blackwater retain their modular shells, collision clearances, shelters and cache IDs. They now reuse Harlow’s PBR materials, architectural trim and locally batched licensed props. They remain visibly simpler than Harlow; full photorealism is not claimed.
- Startup/preset preparation covers both new stations and the actual custom fog shader. The export-only shader inventory is rebuilt from the shipped mission, including custom shaders. Preparation preserves simulation and the ledger’s pause state.

## Validation status

Both unchanged Linux baselines passed: PR #4 196/196, PR #5 246/246. The merged baseline passed all 274 distinct tests. Fourteen new combined-system regressions cover rigs, damage/cadence, carrying/grips, curve/grade alignment, fuel/gauges, all-station and moving saves, camera validation/backward compatibility, paused render preparation, station materials/collision ownership, all danger states/presets, death/fresh scene, results and scene detachment. The identity guard checks that every source test is still present and passing, beyond the 288-test CI floor.

Native build, complete recorded journey, visual review and measured performance evidence are pending in this draft. Do not treat a clean merge or separate source results as combined acceptance. Results and artifact links will be added after actual execution.

## Hardware acceptance

A physical 2020 M1 Mac in fullscreen is unavailable here. Hosted Apple Silicon and Linux software rendering are separate test environments and do not establish the 30 FPS Low target on that hardware. The packaged `res://scripts/diagnostics/integration_benchmark.gd` provides a reproducible twelve-location, all-preset benchmark; final instructions and measured limitations will accompany the evidence.

## Merge path

Review and approve this integration PR, then use a normal merge into the actual default branch to retain both feature histories. Close the older source PRs as incorporated afterward; do not merge their stale bases separately. No PR is merged automatically and repository defaults are unchanged.
