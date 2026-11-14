class_name CameraProfile
extends Resource
## One camera framing (outdoor, indoor, train departure...). The rig blends
## smoothly between profiles; it never cuts.

## Distance from the focus point in metres. Larger values zoom out.
@export var distance := 20.0
## Vertical field of view in degrees.
@export_range(10.0, 90.0, 0.5) var fov := 38.0
## Camera pitch in degrees; negative looks down at the scene.
@export_range(-45.0, 15.0, 0.5) var pitch_degrees := -7.0
## Height of the focus point above the target's feet.
@export var focus_height := 1.4
## How far (m) the framing leads the target's horizontal movement.
@export var look_ahead := 2.5
## Fraction of the target's depth (Z) movement the camera follows.
@export_range(0.0, 1.0, 0.05) var depth_follow := 0.5
