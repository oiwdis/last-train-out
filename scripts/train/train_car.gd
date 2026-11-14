class_name TrainCar
extends AnimatableBody3D
## One vehicle of the train (locomotive or car).
##
## A kinematic body moved by [Train] every physics tick. `sync_to_physics`
## stays enabled so the physics server derives the body's velocity from that
## motion - which is what lets a CharacterBody3D standing on it inherit the
## platform velocity without sliding.

const TRAIN_LAYER := 1 << 2

## Length over buffers in metres (used for layout and camera framing).
@export var car_length := 9.0
## Placeholder for later milestones (weight will slow acceleration).
@export var mass_tonnes := 30.0
@export var wheel_radius := 0.45

var _wheels: Array[Node3D] = []
var interior: TrainInterior


func _ready() -> void:
	add_to_group(&"train")
	collision_layer = TRAIN_LAYER
	collision_mask = 0
	sync_to_physics = true
	var wheel_root := get_node_or_null(^"Wheels")
	if wheel_root != null:
		for child in wheel_root.get_children():
			if child is Node3D:
				_wheels.append(child)
	# Build after the scene has finished entering the tree (children add collision).
	_build_interior.call_deferred()


func _build_interior() -> void:
	interior = TrainInterior.new()
	interior.name = "Interior"
	add_child(interior)
	interior.build(self)


## Spins the wheels to match [param distance_delta] metres travelled.
func roll_wheels(distance_delta: float) -> void:
	if _wheels.is_empty() or wheel_radius <= 0.0:
		return
	var angle := distance_delta / wheel_radius
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.FORWARD, angle)
