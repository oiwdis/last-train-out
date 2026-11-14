# Architecture notes

How the Milestone 1.5 prototype is put together, and why. The short version is in
the README; this file records the decisions that are not obvious from the code.

## Coordinate system and layout rules

- **X** runs along the station (the train departs toward +X), **Y** is up,
  **Z** is depth. The camera sits on the +Z side and looks along -Z, so
  "into the scene" (W) is -Z.
- The track centre line is at `z = -3.5`. Train cars are 2.6 m wide, so their
  camera-facing side is at `z = -2.2`.
- The outdoor walking lane spans roughly `z = -2 ... +2.9`; warehouses widen it
  to `z = -1.15 ... +4.6`.
- **Train clearance envelope:** nothing solid may exist at `z < -1.4` above
  platform height (y = 1.0). A player clinging to a ladder on the side of the
  train occupies space out to `z = -1.48`, and a player on the roof reaches
  about y = 6.7 when jumping. Building back walls sit at `z = -1.4` for this
  reason. If something does intrude, the climber is knocked off rather than
  dragged through it (see "Attached" below).
- **Sight-line rule:** nothing tall stands between the camera and a walking
  lane. Lane dividers are below about 1.2 m; tall racks stand against back
  walls or end-on to the camera.

### Collision layers

| Layer | Name | Used by |
|---|---|---|
| 1 | world | static environment |
| 2 | player | the player body (mask: world + train) |
| 3 | train | train cars (kinematic) |
| 4 | interactable | ladder / railing areas, found by shape queries |
| 5 | trigger | reserved for trigger volumes |

Camera zones and cutaway triggers are areas that only *mask* the player layer.

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
  `PlayerInteractor.find_interactable()` runs a shape query and asks each
  candidate `can_interact()`; the winner's `interact()` does the rest. New
  object types only need a subclass.
- Vaulting needs no setup: `find_vault()` casts a ray at the obstacle, finds
  its top and depth with further rays and checks that the capsule fits. Thin
  obstacles are vaulted over, deep ones climbed onto, and it works on the
  moving train because the move is stored relative to the body that was hit.
- `Player._choose_interaction()` decides between the two: an obstacle the
  player is heading for beats an interactable behind them.
- An interact press is buffered for 0.18 s so a grab can be pressed slightly
  early; a released anchor cannot be re-grabbed for 0.35 s; a grab fails when
  the speed difference exceeds `max_grab_relative_speed` (10 m/s).

## Camera

`CameraRig` follows a target on the physics tick, so camera, player and train
are all interpolated between the same two physics states. It blends
`CameraProfile` resources (distance, FOV, pitch, look-ahead) with a critically
damped spring. Profiles are requested with a priority:

- `CameraZone` volumes (indoor framing) - priority 10;
- the train departure profile, pushed by `Game` while the train moves -
  priority 5.

While the train moves, `Game` also registers it as the rig's *interest
source*. The rig leans toward and widens for the nearest part of the train, but
only within fixed limits and only while it is within range, so it never leaves
the player to chase the train.

## Building cutaways

`CutawayWall` is a wall that fades when asked; `CutawayTrigger` is a volume
that asks while the player is inside. A wall can serve several triggers:

- *inside the building* cuts the front wall;
- *behind the building* (the track lane) cuts the front **and** back walls, so
  a player riding or chasing the train there stays visible;
- Warehouse B's back room has its own wall and trigger.

The fade uses a temporary alpha-blended copy of the material and ends with the
mesh simply hidden, so no transparency is drawn at rest. A shadow-only twin
keeps the wall's shadow, and collision is never touched.

## Atmosphere

Moonlight comes from behind the track at a low angle: long shadows fall toward
the camera, buildings read as silhouettes with warm windows, and moonlight
enters the warehouses through real back windows (the train's shadow sweeps
across the floor as it passes). Scenery in the background does not cast
shadows, otherwise its long shadows would black out the station.

The blue-grey haze is decorative (`scripts/environment/atmosphere.gd`): depth
fog everywhere, plus volumetric fog where the renderer supports it (Forward+).
It is kept thin and cool so the dangerous fog of a later milestone can look
clearly different.

## Gray-box building blocks

- `BoxPart` - a `CollisionShape3D` that also draws itself: one node per block.
- `BoxVisual` - the same without collision.
- `Stairs`, `ShelfRack`, `Track` - small `@tool` scripts that generate their
  geometry from a few exported values.

All scenes are ordinary `.tscn` files and can be edited in the Godot editor.

## Placeholder systems

`FogSystem`, `PassengerSystem` and `InventorySystem` are small nodes under
`Main/Systems`. They define the signals later milestones will use, hold the
minimum state to make those signals meaningful, and are reset by
`Game.reset_station()`. They are scene-owned rather than autoloads because
nothing needs global access to them yet.

## Presentation (Milestone 1.5)

`StationArt` and `TrainArt` add visual children to the authored station and cars.
`DetailBuilder` batches boxes/braces per material, parent and cutaway section; signs
are text meshes. The builders never create collision objects. The original walls
collect these meshes in their deferred initialization, so new trim/text participates
in their existing fade and train-pass cutaways. Keep details on the correct wall parent.

`Game` creates `PresentationEffects` and binds the player. It animates visual-only limbs
and landing offsets on physics ticks, plus bounded CPU particles. Neither effects nor HUD
write movement or train state. `Hud.bind` accepts the player, train and station, refreshes
context at 10 Hz and eases visual values each frame. `RailTheme` shares the industrial
palette with the independently toggled developer console.

See [VISUAL_DESIGN.md](VISUAL_DESIGN.md) for art direction, budgets and constraints.
