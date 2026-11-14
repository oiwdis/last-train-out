# Architecture notes

How the Milestone 2.5 prototype is put together, and why. The short version is in
the README; this file records the decisions that are not obvious from the code.

## Coordinate system and layout rules

- **X** follows the railway, **Y** is up, **Z** is the second ground axis. Physical WASD
  is rotated by camera yaw, with equal X/Z speed and normalized diagonals. Scripted route
  input explicitly stays in world coordinates so existing physics tests remain reproducible.
- Track centre is `z = -3.5`, with 2.6 m wide cars. Original warehouses occupy
  `z = -1.15 ... 4.6`; the new hall, service walk and container yard extend toward +Z.
  Trackside paths run at -7, with the outer retaining wall near -25.
- Keep the train corridor and attached-player envelope clear. Roofs, gangways, cab/crew
  floors and all train doors are collision shapes on the original `TrainCar` bodies.
- There is no side-camera sight-line rule. Walls remain physical and opaque; camera
  collision retracts the over-shoulder view where required.

### Collision layers

| Layer | Name | Used by |
|---|---|---|
| 1 | world | static environment |
| 2 | player | the player body (mask: world + train) |
| 3 | train | train cars (kinematic) |
| 4 | interactable | ladder / railing / supply / door / cab areas, found by camera rays |
| 5 | trigger | reserved for trigger volumes |

Camera zones and cutaway triggers are areas that only *mask* the player layer.
World supplies have collision layer 0 and mask world + train: they settle against geometry
without blocking or pushing the player. Held objects disable their collision mask.

## The moving train

The train is three `AnimatableBody3D` cars moved by `Train` every physics tick
(`scripts/train/train.gd`). `sync_to_physics` stays on, which makes the physics
server derive each car's velocity from its motion. That is what Godot's
`CharacterBody3D` needs to carry a rider: `move_and_slide()` reads the floor
body's velocity and applies it before the character's own motion.

Consequences worth knowing:

- **`velocity` changes meaning with the floor.** On the ground it is relative
  to whatever the player stands on; in the air it is world space (Godot adds
  the platform velocity on take-off, `PLATFORM_ON_LEAVE_ADD_VELOCITY`).
  `Player._after_move()` converts back on landing and when the floor's velocity
  changes abruptly (stepping from the platform onto a moving deck), so world
  velocity stays continuous and the player "skids" by the speed difference.
- **Air control is measured against the frame the player jumped from.** A
  jump straight up on the roof lands on the same spot; momentum inherited from
  the train is not bled away.
- **Where to measure "is the rider sliding?"** Within a physics tick the car's
  node still shows last tick's transform (the body moves in the physics step
  that follows), while the player has already been carried. Sampled at the end
  of a frame - which is what gets rendered - the two agree exactly. The tests
  measure there, and also through `get_global_transform_interpolated()` with
  physics at 30 Hz and rendering at 60 Hz.
- **Speed profile.** `Train` keeps a normalised "profile time"; speed is
  `max_speed * mode.sample(time)`. `DepartureMode` uses smoothstep unless a
  `Curve` is assigned. Stop / restart / mode changes re-enter the profile at
  the current speed, so there is never a jump. `acceleration_modifier` is the
  hook for train weight later.
- **Resetting** teleports the cars. A kinematic body reports a huge velocity
  for the single step in which it is teleported, so `Game.reset_train()` moves
  a standing rider to where the car will be and suspends them for three ticks.
  A player holding a ladder simply follows the anchor.

## Player movement modes

`scripts/player/player.gd` has three modes:

1. **Locomotion** - `move_and_slide()` with acceleration, sprint, stamina,
   coyote time, jump buffering and variable jump height.
2. **Attached** - holding a `Ladder` or `GrabRail`. The player's feet are stored
   in the anchor's local space and re-projected every tick, so anchors mounted
   on the moving train need no special code. If the world blocks the player's
   body for two ticks while the anchor is moving, the player lets go.
3. **Scripted** - a short authored move (vault, mantle, grabbing on, topping
   out), also stored relative to a reference node that may be moving.

This is the "controlled climbing/boarding state" the brief allows: the player
is positioned relative to the train only while holding on to it, and is never
reparented.

`CharacterBody3D` remembers its floor between `move_and_slide()` calls. After
modes 2 and 3 that memory is stale and would apply the old platform's motion
once more, so `_clear_floor_state()` performs a zero-length move in floating
mode (where no floor exists) before control returns to locomotion.

## Interaction

- `Interactable` (an `Area3D` on the *interactable* layer) is the base class.
  `PlayerInteractor.find_interactable()` uses a reticle ray in immersive gameplay and
  asks the visible candidate `can_interact()`; its `interact()` does the rest. The movement
  sandbox retains its near-player shape query. New object types only need a subclass.
- Vaulting needs no setup: `find_vault()` casts a ray at the obstacle, finds
  its top and depth with further rays and checks that the capsule fits. Thin
  obstacles are vaulted over, deep ones climbed onto, and it works on the
  moving train because the move is stored relative to the body that was hit.
- `Player._choose_interaction()` uses the visible interactable first, otherwise a nearby
  obstacle in the viewed direction can be vaulted. The sandbox retains its original priority.
- An interact press is buffered for 0.18 s so a grab can be pressed slightly
  early; a released anchor cannot be re-grabbed for 0.35 s; a grab fails when
  the speed difference exceeds `max_grab_relative_speed` (10 m/s).

## Cameras and targeting

The main `CameraRig` owns an `ExplorationCamera`; the diagnostic movement sandbox retains
its original side camera and framing resources. The immersive camera follows the player's
interpolated transform at render time, with no delayed position chase that could introduce
train-relative drift. Yaw rotates freely, pitch is bounded to ±75 degrees, and a swept sphere
retracts the shoulder boom against world/train collision. Retraction is immediate for safety;
extension and perspective transitions are eased. FOV blends with the transition.

V changes presentation only. Position, velocity, stamina and inventory are untouched.
A switch during scripted mounting/vaulting is queued. First person hides the body and uses
camera-attached carry/arm anchors; third person uses an anchor on the animated body.
The actual held `WorldItem` is reparented, never copied. Local `camera.cfg` stores perspective,
sensitivity, first-person FOV, shoulder distance and smoothing. Open UI sources independently
release mouse capture so closing one menu cannot steal the pointer from another.

`PlayerInteractor` casts through the rendered reticle, checks player reach and a second
player-side visibility ray. Ladder grab volumes remain generous for moving-platform physics,
but ray targeting additionally checks a narrow visible ladder envelope. Obstructed or distant
objects cannot be used through walls. The old near-player shape query is retained only for
the legacy movement sandbox. Route tests now aim their cameras before pressing E.

## Building cutaways

The reusable `CutawayWall`/`CutawayTrigger` fade implementation remains for the diagnostic
side camera and its component regressions. Main gameplay marks triggers as immersive before
physics overlap processing, keeping all walls and their decoration opaque. Tests verify
both this immersive behavior and the retained component's fade/collision behavior.

## Train interiors and expanded district

`TrainInterior` builds hollow walls, windows, floors and gangways on the existing moving
bodies after scene setup. `WorldDoor` keeps its closed collider on the supporting body,
checks the doorway for a player before closing, and animates only the visual hinge.
`TrainConsole` calls the same start, stop and mode APIs as the debug menu. The integrator
in `train.gd` is unchanged. Station reset restores door states; train reset preserves riders
and loose cargo using the existing reset path.

`ExplorationDistrict` adds the waiting hall, platform approach, service/trackside paths,
crossings and container roofs around the original warehouse traversal and supply sites.
The new platform approach avoids existing crates and lamps. Simple collision is separate
from the original generated visual meshes.

## Atmosphere

Cool directional light comes from behind the track, with ambient illumination and
reflections from an overcast procedural sky. It enters the warehouses through real
back windows; warm practical lights mark interiors and routes. Scenery in the background does not cast
shadows, otherwise its long shadows would black out the station.

The blue-grey haze is decorative (`scripts/environment/atmosphere.gd`): depth
fog everywhere, plus volumetric fog where the renderer supports it (Forward+).
It is kept thin and cool so the dangerous fog of a later milestone can look
clearly different.

## Authored building blocks

- `BoxPart` - a box collider with a separately beveled shared visual mesh.
- `BoxVisual` - rectangular trim/background visuals without collision.
- `Stairs`, `ShelfRack`, `Track` - small `@tool` scripts that generate their
  geometry from a few exported values.

All scenes are ordinary `.tscn` files and can be edited in the Godot editor.

## Placeholder systems

`FogSystem` and `PassengerSystem` remain small placeholder nodes under `Main/Systems`,
reset by `Game.reset_station()`. `InventorySystem` now owns real backpack and train-storage
models. Its old inventory signal and coal adapter remain for compatibility with existing tests.
All systems are scene-owned rather than autoloads.

## Presentation

`StationArt` and `TrainArt` add visual children to the authored station and cars.
`DetailBuilder` batches boxes/braces/cylinders per material, parent and cutaway section; signs
are text meshes. The builders never create collision objects. The original walls
collect these meshes in their deferred initialization, so the retained diagnostic fade can still include trim/text. Immersive gameplay disables cutaways. Keep details on the correct wall parent.

`Game` creates `PresentationEffects` and binds the player. It animates visual-only limbs
and landing offsets on physics ticks, plus bounded CPU particles. Neither effects nor HUD
write movement or train state. `Hud.bind` accepts the player, train and station, refreshes
context at 10 Hz and eases visual values each frame. `RailTheme` shares the industrial
palette with the independently toggled developer console.

See [VISUAL_DESIGN.md](VISUAL_DESIGN.md) for art direction, budgets and constraints.

## Scavenging and ownership (Milestone 2)

`ItemDefinition` Resources contain stable IDs, descriptions, categories, stack limits,
weights, icons, world scenes and inert future-use metadata. `ItemCatalog` restricts lookups
to the nine registered definitions. Resource data is shared and treated as immutable.

`InventoryModel` is a `RefCounted` object without scene or UI dependencies. It returns
slot snapshots, fills existing stacks before empty slots and returns the accepted amount.
Unaccepted items remain with their source. Transfers mutate both models before emitting
`changed`; both models reject reentrant mutation until all callbacks return. There are no
awaits inside a transaction. The six-slot backpack rejects heavy definitions; the configurable
48-slot hold accepts them, with one slot per heavy object.

`LootTable` contains weighted `LootEntry` Resources and a draw count. Each search location
seeds a private RNG with the run seed XOR the stable cache ID hash. Cancellation never
rerolls or consumes loot. `SearchContainer` owns a model large enough for its generated
contents. A successful search moves fitting small items to the backpack, retains overflow
and reveals heavy objects once. Search progress is temporary; all rewards remain available.

`SupplyInteractable` adds reach, vertical-distance and world/train line-of-sight checks to
the existing interaction base. `ScavengingSystem` coordinates searches and ownership changes,
using explicit player/inventory/station/train references. It emits progress, completion,
notices, storage-open and carrying signals. It runs physics only during an active search.
The UI never mutates model internals; every storage operation rechecks physical reach.

`WorldItem` is a `CharacterBody3D` using the same platform-velocity conventions as the
player. It is reparented to the player's visual node while held, with collisions disabled.
Dropping checks a capsule against world/train geometry, restores world parenting, and
inherits player world velocity. Released cargo settles on train decks and follows them.
A zero-length floating-mode move clears stale floor state while restoring transform and
zeroing inherited velocity; train resets then suspend cargo for three ticks. Static settled
items sleep, while train cargo continues its platform integration. Falls outside the station
recover to the last safe floor position. Cargo bodies do not collide with one another.

Only carrying adds a 2.5 m/s target-speed override and prevents sprint; the movement Resource
and all unladen equations are unchanged. Ladder/rail interactables declare that they require
free hands; vault and climb entry guards provide feedback too. Jump boarding remains allowed.
The held model and arm pose are visual children, independent of player collision.

`SupplyUI` builds the six-slot ledger, storage list, graphics selector, contextual progress
and compact field summary. Changes refresh through signals; range checks run at 10 Hz only
while the ledger is open. Opening it blocks movement input without pausing world physics.
Closing releases input; a departing hold closes automatically if it leaves reach.

`Game` owns lifecycle wiring. Player reset keeps backpack and held cargo with the player; train reset
moves loose cargo with its car and preserves storage; station reset cancels searches,
clears both models and physical items, then regenerates the same seeded caches. See
[SCAVENGING.md](SCAVENGING.md) for player-facing rules and tuning locations.

## Render settings and performance

`GraphicsPreset` Resources describe Low / Medium / High. `GraphicsSettings` duplicates the
scene Environment and caches authored lights/particles once, then changes rendering only.
Resolution budgeting uses the window's pixel size, since stretched UI dimensions can stay
1280×720 in a much larger full-screen window. UI rendering remains at window resolution.
Preset changes affect resolution, MSAA, shadows, light fade distances, bloom, particle counts
and supported volumetrics; they never change physics ticks, collisions, movement or train state.
Only the preset preference is persisted in `user://graphics.cfg`.

Existing batched scenery, opaque shared materials, transient cutaway fades and capability
guards remain. New supplies add no dynamic lights and no blocking level geometry. Benchmarks
use real-time `frame_post_draw` sampling, with hardware/settings recorded separately from
fixed-step tests and Movie Maker evidence. See [PERFORMANCE.md](PERFORMANCE.md).

## Original models and audio

`FabricatedMesh` caches beveled mesh geometry/material combinations for a live scene.
The GLB sources and reproduction commands are recorded in `ASSET_CREDITS.md`. The worker's
hips, knees, shoulders and elbows animate on physics ticks; the body collider does not scale.
PBR maps are shared, mipmapped and VRAM-compressed. High adds ambient occlusion; Low/Medium
retain their pixel budgets and avoid this extra pass.

`RailAudio` uses original synthesized WAV streams for ambience and spatial engine/footsteps.
Doors use a short latch. Playback is disabled in headless runs, which have no audio clock;
looping Dummy-driver playback otherwise retains instances during fast simulated tests.
