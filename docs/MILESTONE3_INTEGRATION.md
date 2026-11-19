# Milestone 3.5 integration provenance and plan

## Verified starting points

- PR #4: `a8f58ec57c218c3944d038a9d1640e78597042be`, 196/196 Linux tests (82.9 s); latest native CI run 35 passed.
- PR #5: `9c4f0de49e104ca95ccb57c88cf535ab96202dac`, 246/246 Linux tests (119.2 s); latest native CI run 40 passed.
- Common ancestor: `8cde10cf78c1ea0cf7f7bafb5fc146d2e12514c2` (M2.5).
- Actual default: `claude/serene-turing-0vpdmt`, head `e523c8a9017259040e36034ac0cf25d73b53d6a3`. Its tree equals the common ancestor; intervening commits record earlier PR merges.
- Integration branch: `integration/milestone-3-5-photoreal-survival`, started at PR #5, normal merge of PR #4. Both source histories remain intact. New draft PR targets the actual default. No repository settings change or automatic merge.

## Plan and conflict decisions

1. Fetch/inspect both PRs, notes and history; run both unchanged baseline suites before edits. Completed. The union has 274 distinct tests (manifest and baseline reports under `docs/validation/milestone35/baselines`).
2. Resolve five textual conflicts individually: Game runs journey setup then Harlow art before graphics collection; project launches Harlow Escape with M2.6 Forward+/Vulkan, worker ratio and export settings; workflow keeps the art cache/baker/native checks plus survival validation; README describes combined scope; this document preserves both source notes below.
3. Review automatic merges of Player (survival multiplier plus rig adapters), Scavenging (serial ownership/collection plus art actions), and self-test (shipped mission plus legacy mechanics). Run the unchanged test union.
4. Add focused integration fixes and regression coverage: camera save state, route-distance locomotive phase, fog/material preparation, reusable station dressing. Preserve physics, collision paths and cache IDs.
5. Validate continuous real-control travel, scarcity/death, camera/cargo and process resume. Record uninterrupted primary journey plus clearly labelled cold-resume clip if needed.
6. Profile twelve locations in all presets with source comparisons and separate fog/animation ablations. Capture native visuals, export a universal app and verify fresh download on both architectures. Physical 2020 M1 fullscreen testing remains a separately documented hardware acceptance requirement.
7. Publish evidence and limitations on the draft PR. Recommend reviewing this combined PR and merging it normally into the default only after approval; then close source PRs as incorporated, without merging their stale bases separately.

## Original PR #5 notes (historical)

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

## Original PR #4 notes (historical)

# Milestone 2.6 → Milestone 3 integration

PR #4 stays on `feature/milestone-2-6-photorealism`. No Milestone 3 branch is modified,
fetched into this branch, merged or rebased by this work. Integrate the two reviewed
PRs deliberately; the following are the likely conflict points.

| File / system | Contract to preserve |
|---|---|
| `scripts/player/player.gd` | Existing movement, traversal, inventory and train-facing APIs/signals remain. New optional `present_action(action, seconds, world_focus, reference)` emits the existing `presentation_action` signal and stores a visual target. `get_presentation_focus()` follows a moving reference; `get_traversal_anchor()` exposes the current anchor read-only. Neither changes movement or transactions. The rig supplies its own lean, so the legacy extra whole-body lean is suppressed only when `RailWorker` exists. |
| `scripts/settings/graphics_preset.gd`, `graphics_settings.gd`, `resources/graphics/*.tres` | Quality fields now explicitly cover normal/roughness maps, skin scattering (disabled in shipped presets), SSAO, LOD and light fading. Keep `set_preset(index, persist)` and `changed(index)`. Gameplay fog must not depend on the preset index: quality may change how danger is rendered, never danger simulation. |
| `scripts/presentation/render_warmup.gd`, `GraphicsSettings`, `scenes/station/harlow_junction.tscn` / `RenderWarmupViews` | Scene-authored marker views prepare destination-GPU pipelines at startup/preset changes on normal frames behind a loading panel, pausing/restoring the game. `wait_for_render_ready()` lets diagnostics wait for preparation. Keep the marker group and active-camera restoration when adding stations. Danger systems must respect the normal scene pause and must not interpret loading/compilation wall time as danger progression. This does not control visibility or fog; new fog shader features may need their own load-time preparation. |
| `scripts/environment/atmosphere.gd` | Existing decorative fog initializes on ready. M3 should own its danger-fog parameters after initialization and reapply rendering choices after `GraphicsSettings.changed`. Preserve the atomic-storage capability guard; Apple Paravirtual GPU cannot render volumetrics. Provide a depth-fog/material fallback for that hardware. This PR adds no fog gameplay. |
| `scripts/presentation/environment_art.gd`, `fabricated_mesh.gd` | Art is built from the existing scene nodes. New close steelwork and damage have no physics bodies. Opaque PBR surfaces use standard Godot materials, which receive environment fog. Cached planar UV materials keep normal/roughness toggles and do not encode visibility or danger. |
| `scripts/presentation/worker_animator.gd`, `worker_pose.gd`, `scenes/player/player.tscn` | Animation/contact correction is visual only and skipped for hidden rigs. Cadence is capped for natural movement; the legacy holstered-light energy is reduced for the overcast setting. Feet retain support-local contacts on moving cars. Gameplay health/fear/damage states should request actions without changing ownership or feeding animation displacement back into Player. |
| `scripts/presentation/train_art.gd`, `train_mechanics.gd` | Reads train speed/state; existing train integrator is untouched. Needles represent speed and regulator/brake command states, not simulated pressure. Keep `Train.reset_finished` so wheel phase resets coherently. |
| `scripts/interaction/world_door.gd`, `scripts/train/train_console.gd`, `scripts/scavenging/scavenging_system.gd` | Successful existing operations provide an optional hand target. Transactions remain immediate. Preserve those operations and their return values when adding danger reactions. |
| `project.godot`, `resources/graphics/runtime_material_library.tscn`, `tools/assets/bake_runtime_materials.gd` | Preserve the tested 0.9 worker-pool background ratio and explicit macOS Vulkan driver (Forward+ through bundled MoltenVK). Refresh the deterministic export-only material inventory after adding material features; the library is not instantiated in gameplay. Keep export cache namespaces separate across driver changes. Fog capability checks must use the actual RenderingDevice, not a presumed Metal backend. |
| `.github/workflows/macos-app.yml`, tests | Keep all existing and new regression suites. Native benchmark diagnostics use detached M2.5 and `dfbfdf8` source snapshots; they do not exercise an M3 branch. |

Do not globally disable fog on imported materials to solve transparency sorting.
Hair/eyelashes/vegetation use alpha scissor; windows, wall cutaways and particles
still need an actual combined-build visual review inside dense fog. Visibility
ranges for small foliage/details are rendering budgets only, not gameplay
visibility decisions. All 13 cache IDs, ladder volumes and train controls remain
at their existing scene paths.

After combining reviewed work, run the complete suite and packaged self-tests,
then inspect both perspectives, a carrying player, a moving train, warehouse
entry and cutaways with danger fog active on Low/Medium/High. These combined
checks are pending until M3 is available; PR #4 does not claim them as completed.
