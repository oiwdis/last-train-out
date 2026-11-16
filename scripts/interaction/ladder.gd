@tool
class_name Ladder
extends Interactable

## A climbable ladder. Works on static walls and on moving bodies alike.
##
## Local frame: the origin is the bottom of the ladder on the wall plane,
## +Y runs up the ladder and +Z points away from the wall (where the climber is).

## How far below the top the climber's feet stop (their hands are on the top rung).
const HAND_REACH := 0.9
const RUNG_SPACING := 0.33

@export var height := 3.0:
	set(value):
		height = maxf(value, 0.5)
		_rebuild()

@export var width := 0.55:
	set(value):
		width = maxf(value, 0.2)
		_rebuild()

## Climbing past the top steps onto the surface behind the ladder.
@export var top_exit := true
## How far behind the ladder plane the climber ends up after topping out.
@export var top_exit_depth := 0.6
## Distance from the ladder plane to the climber's centre line.
@export var climber_offset := 0.42
## How far below the bottom rung the ladder can still be grabbed (lets a player
## standing on lower ground reach a ladder that starts above them).
@export var reach_below := 1.2:
	set(value):
		reach_below = maxf(value, 0.0)
		_rebuild()

@export var material: Material:
	set(value):
		material = value
		_rebuild()

var _visual_root: Node3D
var _area_shape: CollisionShape3D


func requires_free_hands() -> bool:
	return true


func _ready() -> void:
	super()
	if prompt == "Interact":
		prompt = "Climb"
	_rebuild()


func can_interact(player: Player) -> bool:
	if not enabled:
		return false
	var p := to_local(player.global_position)
	if absf(p.x) > width * 0.5 + 0.55:
		return false
	if p.y > height - 0.4:
		# Standing on the surface the ladder leads to: allow climbing down.
		return top_exit and p.y < height + 0.6 and p.z > -1.0 and p.z < 0.95
	return p.z > -0.1 and p.z < 1.0 and p.y > -reach_below - 0.1


func interact(player: Player) -> bool:
	return player.begin_climb(self)


func get_interaction_distance(player: Player) -> float:
	var p := to_local(player.global_position)
	return Vector2(p.x, p.z - climber_offset).length()


func get_interaction_point(player: Player) -> Vector3:
	return to_global(get_attach_local(player.global_position))


## Highest feet position (local Y) reachable while holding the ladder.
func get_max_climb() -> float:
	return maxf(height - HAND_REACH, 0.0)


## Where the climber's feet attach (ladder space) for a player at [param world_feet].
func get_attach_local(world_feet: Vector3) -> Vector3:
	var p := to_local(world_feet)
	return Vector3(0.0, clampf(p.y, 0.0, get_max_climb()), climber_offset)


## Feet position (ladder space) after climbing off the top.
func get_top_exit_local() -> Vector3:
	return Vector3(0.0, height + 0.03, -top_exit_depth)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	# Interaction volume.
	if _area_shape == null:
		_area_shape = CollisionShape3D.new()
		_area_shape.shape = BoxShape3D.new()
		add_child(_area_shape, false, Node.INTERNAL_MODE_BACK)
	var top := height + 1.0
	var box := _area_shape.shape as BoxShape3D
	box.size = Vector3(width + 0.9, top + reach_below, 1.85)
	_area_shape.position = Vector3(0.0, (top - reach_below) * 0.5, 0.025)

	# Visual: two rails and evenly spaced rungs.
	if _visual_root != null:
		_visual_root.queue_free()
	_visual_root = Node3D.new()
	add_child(_visual_root, false, Node.INTERNAL_MODE_BACK)
	var steel := MeshInstance3D.new()
	steel.name = "ChannelStilesAndRoundRungs"
	steel.mesh = FabricatedMesh.ladder(width,height,material)
	_visual_root.add_child(steel)
