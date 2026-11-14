class_name CutawayTrigger
extends Area3D
## Cuts away the listed [CutawayWall]s while the player is inside this volume.

signal player_entered
signal player_exited

const PLAYER_LAYER := 1 << 1

## Walls to cut away while the volume is occupied.
@export var walls: Array[NodePath] = []

var _occupants := 0
var _walls: Array[CutawayWall] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitoring = true
	monitorable = false
	for path in walls:
		var wall := get_node_or_null(path) as CutawayWall
		if wall != null:
			_walls.append(wall)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	for wall in _walls:
		if is_instance_valid(wall):
			wall.release_cut(self)


func is_occupied() -> bool:
	return _occupants > 0


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	_occupants += 1
	if _occupants == 1:
		for wall in _walls:
			wall.request_cut(self)
		player_entered.emit()


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	_occupants = maxi(_occupants - 1, 0)
	if _occupants == 0:
		for wall in _walls:
			wall.release_cut(self)
		player_exited.emit()
