# Milestone 2.6 — authored character and railway assets

This milestone delivers a substantial asset replacement, **not a completed photorealism claim**. The procedural humanoid is replaced with authored human anatomy, individual fingers, skin/clothing textures, a 52-bone skeleton and 21 animation clips. A licensed detailed steam locomotive and 14 licensed industrial props replace major blockout visuals. The cab, cars, doors, tracks, warehouse stairs and lighting receive additional geometry and material work.

The station architecture, distant buildings, supply-cache shells and several freight-yard structures still look like a prototype. Facial shading and animation polish also fall short of a finished realistic survival game. Those gaps are visible in the evidence and remain open.

## Branch and preserved systems

- Development branch: `feature/milestone-2-6-photorealism`.
- Base: `feature/milestone-2-5-full-3d`, PR #3, commit `8cde10cf78c1ea0cf7f7bafb5fc146d2e12514c2`.
- No PR is merged by this work.
- Train acceleration/integration, player collision/movement, stamina, inventory, scavenging and storage rules remain intact. Presentation listens to successful pickup/drop/control actions; it does not postpone ownership or train commands.
- Existing colliders, warehouse routes, carriage openings and all 13 caches remain. New equipment sits in wall recesses and loading areas; decorative models do not introduce mesh collision.

## Implementation

The worker uses MakeHuman/MPFB authored topology, Aksel skin, field jacket and trousers, leather boots, brows, eyes and cropped hair. A skeleton-mounted utility belt and licensed flashlight replace the floating hip lantern presentation. Quaternius clips provide walking, sprinting, jumping, landing and interaction; original breathing and carry/traversal adaptations are baked onto the same rig. Per-bone AnimationPlayer crossfades provide the state/blending system, with gait driven by player movement relative to the train. Full-body root motion never drives physics. Dedicated FP skin/sleeve meshes share the body’s UVs, materials and weights, with five camera-specific carry/action clips that keep shoulder roots below the eye. Hands appear during carrying and item/control actions; the face stays hidden in first person.

Roland Schuller's CC0 locomotive supplies detailed authored boiler, pipes, wheels, suspension and coupling geometry. Its inaccessible rear cab is adapted to the existing walk-through footprint. Wheels rotate with train speed. Original fitted cab and carriage assets add rounded window seals, glazing, rivets, timber interiors, roof seams, underframe springs, hinged doors and articulated control handles. The cab controls still issue the original commands immediately.

Poly Haven shelving, crates, drill presses, work carts, hand trucks, lamps, barrels, luggage and tools populate the platform, both warehouses and freight area. Repeated objects use spatial MultiMesh batches. Tracks have rail head/web/foot profiles, fastening plates and bolts; warehouse stairs use open treads/stringers while retaining the original smooth collision wedge. Scanned gravel replaces unsuitable ballast mapping. A photographic overcast HDR sky, warm industrial lamps and softer steam sprites support the scene.

## Evidence and validation

- [Matched before/after gallery](screenshots/milestone26/README.md), including close face/hands and gameplay views. Original PNGs and camera metadata are included.
- [Scripted gameplay recording](recording/milestone26_tour.mp4), with explicit tour cuts and real interaction/perspective inputs. [Capture settings and checks](recording/milestone26_tour.md): Low, 854×480, offline 24 FPS. This is not a performance recording.
- [Performance comparison](PERFORMANCE_MILESTONE26.md), including raw measurements and hardware limitations.
- [Asset credits and individual licenses](ASSET_CREDITS.md), [reproduction pipeline](ASSET_PIPELINE.md), and source manifests alongside the assets.
- Baseline: **168/168** tests passed before changes. Updated Linux suite: **182/182** tests passed, with no import/main-scene/runtime errors. The final full Linux suite passed in 97.4 seconds while graphical capture also ran (test wall time is not game FPS), and includes the final FP shoulder-placement, Low/Medium LOD and long-track batching assertions. A subsequent 12/12 character-suite run validates the final hidden-FP-pose transition fix. Raw results are under [validation/milestone26](validation/milestone26/).
- The 14 added tests cover rig/finger topology, required animation clips, movement and traversal states, train-relative gait, FP mesh visibility, two-hand cargo positioning and ownership, carry/drop, cab interaction, authored prop batching and all 13 caches, wheel movement, preset restoration, nonuniform mesh normals, and spatial/triangle budgets for long-track details. Existing tests cover physical collision, door clearance, moving interiors, inventory and accessibility.
- `tools/assets/check_assets.py` validates all 20 new GLBs and 115 explicitly compressed/mipmapped 3D textures for embedded image/buffer payloads, valid bounds, normals, materials, skin data and the complete character image set. This catches lost Blender texture paths before packaging.

The macOS workflow also attempts matched windowed before/after benchmarks on its hosted Apple Silicon runner; raw reports are uploaded with test logs, and a measurement failure is reported separately without discarding the app. These are not full-screen measurements on the user’s physical M1. The workflow retains universal export, Apple Silicon headless/window launch, Intel headless launch, bundle and ZIP checks, fresh-download launches and optional signing/notarization. Build-specific results, the exact commit and the downloadable ZIP are linked from the pull request and its Actions run.

## Acceptance status

| Requirement group | Status |
|---|---|
| Replace primitive worker; human anatomy, face/fingers, clothing, functional rig | Implemented with licensed authored assets; facial/material polish remains below the requested final quality |
| Body movement and traversal animations | Implemented and tested; natural motion/foot planting still needs polish |
| Dedicated first-person hands, actions and carrying | Implemented and tested; grips remain approximate for different cargo shapes |
| Locomotive exterior | Substantially replaced; connecting-rod animation remains incomplete |
| Cab and train cars | Improved with fitted assets; professional-quality instrumentation/interior finish remains incomplete |
| Station, warehouses and freight yard | Authored equipment and infrastructure added; the complete environment rebuild remains incomplete |
| PBR materials, overcast/warm lighting, asset licenses | Implemented and documented |
| Existing gameplay, 13 caches and graphics presets | Regression suite passes; collision and train movement rules preserved |
| 2020 M1 full-screen playability / 60 FPS target | Unverified; requires the actual device and full-screen resolution |
| Screenshots, gameplay recording, tests and universal Mac build | Evidence linked above and in the PR; build-specific checks and download are reported there |

## Remaining limitations

- **Full photorealism is incomplete.** The character is an authored, realistically proportioned rigged human, but face/eye/hair shading and clothing presentation need further art direction. Some animation transitions, finger grips and limb poses need hand polishing; there is no runtime foot-placement IK, facial animation or cloth simulation.
- Station architecture, far skyline, supply-cache shells, freight containers and parked freight cars retain substantial procedural construction. Warehouse B has better authored equipment and shelving but lacks the requested full bespoke damage/debris pass. Rail switches and overgrowth are not comprehensively rebuilt.
- The locomotive's connecting rods are detailed static source geometry; only the wheel assemblies rotate. Gauges are decorative, not simulated pressure instruments. The adapted cab/carriage joinery remains visibly simpler than a professional photorealistic interior.
- The original coal sack and other physical supply-item models remain; the sack receives scanned fabric but is not a new scanned model. Generic carrying poses fit these item classes approximately, without per-item finger IK.
- No physical 2020 M1 Mac or full-screen macOS performance test was available. Cloud software rendering and hosted Apple Silicon launch checks cannot establish M1 frame rate. Intel graphical rendering is not validated by the headless CI runner.
- Development ZIPs are ad-hoc signed, not Developer ID signed/notarized. Optional signing support is preserved and requires the configured credentials.

Single-view offline Vulkan captures occasionally stalled during renderer shutdown after saving the PNG and camera metadata; those capture processes were terminated. Full-scene captures and the headless suite completed. This cloud-driver observation is separate from the macOS exported-app exit checks.
