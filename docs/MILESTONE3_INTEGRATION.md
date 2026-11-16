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
