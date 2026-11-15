# Milestone 2.6 — environment continuation

This pass replaces prominent blockout structures while keeping the existing movement,
train, inventory and scavenging rules. It continues draft PR #4 on
`feature/milestone-2-6-photorealism`; no PR is merged by this work.

## Asset changes

- Poly Haven's CC0 Modular Factory Facade supplies modeled masonry, recessed steel
  windows, sills, loading bays, plinths and cornices. It replaces the station-house
  shell and warehouse fronts, and fits the existing warehouse/hall window spans.
  Selected panes are removed in Warehouse B. Modules keep source UVs and 2K PBR maps.
- Original pitched roof meshes add pressed sheet profiles, gutters, closed gables,
  fascia and open trusses to the hall and station house. Six licensed weathered
  benches replace the hall's block seating. Existing bench/roof collision remains.
- Three fitted freight containers have corrugated sheet geometry, door seals,
  locking bars, clasps, hinges, lifting pockets, roof stiffeners and identification.
  Both parked box vans have timber siding, sliding-door gear, steel straps, flanged
  dished wheels, axleboxes, leaf springs, brake pipes/reservoir and buffers/couplings.
- All thirteen caches use imported crate/luggage meshes or original modeled
  lockers, medical cabinets and toolboxes. Labels, state strips, IDs, loot tables,
  interaction targets and search/collection rules are retained. Hall identification
  and evacuation signs now face the actual approach/interior.
- Sparse CC0 weeds and original broken pallet clusters sit along closed wall and
  container edges. This is a limited deterioration pass, not a complete abandoned
  landscape or bespoke damaged warehouse.

Sources, creators, licenses and modifications are in [ASSET_CREDITS.md](ASSET_CREDITS.md).
[ASSET_PIPELINE.md](ASSET_PIPELINE.md) documents the pinned downloads and Blender build.

## Rendering and gameplay safeguards

Factory parts are grouped into MultiMeshes per wall and module/material. This keeps
the imported mesh LODs and reduces repeated facade draws while allowing each
building's cutaway to operate independently. CutawayWall now supports these batches
and skips intentionally hidden/replaced visuals. Single-material source pieces
retain their individual materials during fading.

Original railway meshes share existing GPU texture sets through `EnvironmentArt`;
their GLBs carry geometry/UVs/material names rather than duplicate image payloads.
The parked van has 33,186 source triangles, reduced from an intermediate 71,458 by
using continuous leaf-spring strips. Containers have 13,427 triangles; Godot generates
further LODs. Source geometry metrics are in `assets/environment/original_mesh_metrics.json`.
Vegetation uses 20 m spatial batches, 35 m visibility range, alpha scissor and no
shadows. Low/Medium/High retain their existing resolution and effects budgets.

Decoration adds no collision bodies. Container volumes stay 6×2.7×2.5 m and freight
roof tops remain 3.8 m. Existing ladders, doors, wall segments and platform routes
stay authoritative. Repeated district nodes now have readable unique names, so all
three containers and all six benches receive their replacement art.

## Evidence

- [Eight matched before/after views](screenshots/milestone26/environment/README.md),
  including raw camera metadata and PNG checksums. High, Forward+, 1280×720.
- Baseline **182/182** and updated **187/187** automated tests. The full updated
  import, 600-frame smoke run and suite pass without engine errors.
  [Logs and JSON](validation/milestone26/environment/). The shared-host suite emitted
  one Jolt job-pool saturation warning; it completed with zero failed tests.
- Asset integrity checks cover 31 GLBs and 137 compressed/mipmapped texture imports.
- [Gameplay tour](recording/environment_tour.mp4): actual search, perspective switch and
  container climb, with explicit location cuts. [Capture method](recording/environment_tour.md).
- [Matched environment rendering comparison](PERFORMANCE_ENVIRONMENT.md): fewer draw
  calls in Warehouse B and the freight yard on the tested Low views; software rendering
  remains too slow for play and does not predict physical M1 performance.
- Build-specific native performance, exported-app startup, ZIP validation and the
  standalone universal Mac download are reported in PR #4 and its Actions run.

## Remaining gaps

Full photorealism is still incomplete. The distant skyline, some platform/yard
furniture, the gantry, generic doors/ladders and structural columns are simplified.
The foreground models need more varied weathering and environmental clutter;
Warehouse B needs a stronger bespoke damage pass. Character shading, grips and
foot planting, locomotive rod animation and cab instrumentation remain as documented
in [MILESTONE_2_6.md](MILESTONE_2_6.md). Physical 2020 M1 full-screen performance is
unverified; cloud software rendering and a hosted virtual Mac cannot establish it.
