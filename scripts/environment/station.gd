class_name Station
extends Node3D
## A station environment. Owns its geometry, lighting and trigger volumes and
## tells the Game where things start; it knows nothing about the player or train.

@export var station_name := "Harlow Junction"
## Where the player starts / is reset to.
@export var player_spawn: Marker3D
## Where the train's origin sits when parked (informational for now).
@export var train_stop: Marker3D


func get_player_spawn_position() -> Vector3:
	return player_spawn.global_position if player_spawn != null else global_position


## Puts every resettable piece of the environment back to its initial state.
func reset_state() -> void:
	for node in get_tree().get_nodes_in_group(&"station_resettable"):
		if is_ancestor_of(node) and node.has_method(&"reset_state"):
			node.call(&"reset_state")
