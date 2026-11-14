@tool
class_name Interactable
extends Area3D
## Base class for anything the player can use with the interact button.
##
## The player's interactor finds Interactables with a shape query on the
## "interactable" physics layer, asks [method can_interact], then calls
## [method interact]. New kinds of object (doors, levers, loot...) only need a
## subclass; the player script does not change.

const INTERACTABLE_LAYER := 1 << 3

## Short verb shown in the HUD prompt, e.g. "Climb".
@export var prompt := "Interact"
@export var enabled := true

var _velocity := Vector3.ZERO
var _previous_position := Vector3.ZERO


func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	_previous_position = global_position
	# Only objects riding on something that moves need to track a velocity.
	set_physics_process(_has_moving_ancestor())


func _physics_process(delta: float) -> void:
	var now := global_position
	if delta > 0.0:
		_velocity = (now - _previous_position) / delta
	_previous_position = now


## Whether [param player] is positioned so that interacting makes sense.
func can_interact(_player: Player) -> bool:
	return enabled


## Performs the interaction. Returns true when something actually started.
func interact(_player: Player) -> bool:
	return false


## Used to pick the best candidate when several are in range (lower wins).
func get_interaction_distance(player: Player) -> float:
	return global_position.distance_to(player.global_position)


## World position the player would end up at when interacting.
func get_interaction_point(_player: Player) -> Vector3:
	return global_position


## World-space velocity of this object (non-zero when mounted on a moving body).
func get_velocity() -> Vector3:
	return _velocity


## The physics body this interactable is mounted on, if any.
func get_mount_body() -> CollisionObject3D:
	var node := get_parent()
	while node != null:
		if node is CollisionObject3D:
			return node
		node = node.get_parent()
	return null


func _has_moving_ancestor() -> bool:
	var node := get_parent()
	while node != null:
		if node is AnimatableBody3D or node is RigidBody3D or node is CharacterBody3D:
			return true
		node = node.get_parent()
	return false
