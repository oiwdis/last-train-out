# PR #5 / PR #4 integration plan

PR #5 remains based on `feature/milestone-2-5-full-3d`. PR #4's branch and assets were not changed, merged or rebased. No integration branch was created.

Compared with PR #4 at `a8f58ec57c218c3944d038a9d1640e78597042be`, the directly shared changed files are:

| File | Reconcile |
|---|---|
| `.github/workflows/macos-app.yml` | Retain PR #4's improved export/startup checks and this PR's 246-test floor and continuous-journey step. Combined suite count must be determined by discovery, not copied from either branch. |
| `project.godot` | Preserve PR #4's renderer decision, shader warmup/loading configuration and title/version conventions; launch the inherited Harlow Escape mission. |
| `scripts/main/game.gd` | Run journey setup early enough to install the route/config before fog binding; let PR #4's startup warmup cover the added station materials and hold simulation consistently. Reconcile reset/restart routing explicitly. |
| `scripts/main/self_test.gd` | Keep both branches' checks. Load the shipped mission first, then run legacy mechanics fixtures without invoking a mission reload under the self-test scene. |
| `scripts/scavenging/scavenging_system.gd` | Preserve PR #4's placement/art-related corrections and this PR's collected signal, station registration and serial supply IDs. Recheck all Harlow cache approaches after art integration. |

This PR also changes Train, FogSystem, FogFuel, the HUD/supply header and WorldItem. Train retains the proven motion integrator and adds per-car curve transforms. The player controller and animations are unchanged here. PR #4's character, carrying anchor and animation changes must be tested on moving curves, grade transitions, ladders, gangways, saved riders and saved heavy cargo.

New station scenes depend on the existing BoxPart/FabricatedMesh/DetailBuilder, common materials, item catalog and SearchContainer. Their material paths deliberately stay compatible with the M2.5 base. Replace modular building visuals with PR #4's licensed environment kit without changing doorway clearances, collision surfaces, cache IDs, note reach or boarding/ramp paths. Do not replace entire station nodes or erase state when applying art.

Fog presentation remains the existing lightweight route-aligned sheets plus observer haze. It must be checked alongside PR #4's tone mapping, PBR roughness/normal maps, exposure, lights and reflection setup. PR #4's Vulkan/Metal startup findings and fullscreen resolution budgets remain relevant; this PR does not override graphics presets or select a new renderer. New resident stations add CPU/mesh memory even while culled, so repeat matched rendering, peak memory and fullscreen tests after combining the asset sets.

Recommended order: finish the independent gameplay/native-build validation of PR #5 and the physical-device/art acceptance of PR #4; then use a separately approved integration branch, reconcile shared files deliberately, run the combined discovered test suite, repeat the continuous journey and process-resume validation, and export a new universal app. Do not infer compatibility from each PR passing alone. Obtain a physical 2020 M1 fullscreen run before claiming that target's performance. Keep both PRs unmerged until their remaining acceptance work and the combined regression pass are complete.
