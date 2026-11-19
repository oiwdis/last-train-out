# PR #5 / PR #4 integration plan

PR #5 remains based on `feature/milestone-2-5-full-3d`. PR #4's branch and assets were not changed, merged or rebased. No integration branch was created.

Compared with PR #4 at `a8f58ec57c218c3944d038a9d1640e78597042be`, the directly shared changed files are:

| File | Reconcile |
|---|---|
| `.github/workflows/macos-app.yml` | Retain PR #4's improved export/startup checks and this PR's 246-test floor and continuous-journey step. Combined suite count must be determined by discovery, not copied from either branch. |
| `project.godot` | Preserve PR #4's renderer decision, shader warmup/loading configuration and title/version conventions; launch the inherited Harlow Escape mission. |
| `scripts/main/game.gd` | Run journey setup early enough to install the route/config before fog binding; let PR #4's startup warmup cover the added station materials and hold simulation consistently. Reconcile reset/restart routing explicitly. |
| `scripts/main/self_test.gd` | Keep both branches' checks. Load the shipped mission first, then run legacy mechanics fixtures without invoking a mission reload under the self-test scene. |
| `scripts/player/player.gd` | PR #5's original fog work adds a survival speed multiplier after the heavy-cargo limit; the journey increment does not alter it. Retain that behavior alongside PR #4's character, foot-contact and animation adapters. Recheck incapacitation, carrying, ladders and moving-platform velocity after resolving the file. |
| `scripts/scavenging/scavenging_system.gd` | Preserve PR #4's placement/art-related corrections and this PR's collected signal, station registration and serial supply IDs. Recheck all Harlow cache approaches after art integration. |
| `README.md`, `docs/MILESTONE3_INTEGRATION.md` | Combine the independently authored gameplay/art evidence and integration findings; do not overwrite either branch's limitations or native-build provenance. |

This PR also changes Train, FogSystem, FogFuel, the HUD/supply header and WorldItem. Train retains the proven motion integrator and adds per-car curve transforms. This finalization adds no further player-controller or animation changes beyond the existing fog adapter. PR #4's character, carrying anchor and animation changes must be tested on moving curves, grade transitions, ladders, gangways, saved riders and saved heavy cargo. The default legacy fog route now loads after script classes finish resolving, avoiding a cold-load resource cycle; keep that fix alongside the train-progress adapter.

New station scenes depend on the existing BoxPart/FabricatedMesh/DetailBuilder, common materials, item catalog and SearchContainer. Their material paths deliberately stay compatible with the M2.5 base. Replace modular building visuals with PR #4's licensed environment kit without changing doorway clearances, collision surfaces, cache IDs, note reach or boarding/ramp paths. Do not replace entire station nodes or erase state when applying art.

Fog presentation remains the existing lightweight route-aligned sheets plus observer haze. It must be checked alongside PR #4's tone mapping, PBR roughness/normal maps, exposure, lights and reflection setup. PR #4's Vulkan/Metal startup findings and fullscreen resolution budgets remain relevant; this PR does not override graphics presets or select a new renderer. New resident stations add CPU/mesh memory even while culled, so repeat matched rendering, peak memory and fullscreen tests after combining the asset sets.

Recommended order: finish the independent gameplay/native-build validation of PR #5 and the physical-device/art acceptance of PR #4. Once approved, start an isolated integration branch from the accepted PR #4 asset/renderer foundation, then bring in PR #5's fog and journey changes, resolving the shared files deliberately. This lets the journey adapters target the final player/train presentation. Run the combined discovered test suite, repeat the continuous journey and process-resume validation, and export a new universal app before proposing the integration for merge. Do not infer compatibility from each PR passing alone. Obtain a physical 2020 M1 fullscreen run before claiming that target's performance. Keep both PRs unmerged until their remaining acceptance work and the combined regression pass are complete.
