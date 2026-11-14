@tool
class_name GrabRail
extends Interactable
## A railing the player can grab and cling to, then climb over.
##
## Local frame: the origin is the middle of the rail, +X runs along it and +Z
## points to the outside (where the player clings). The inside (-Z) is the
## surface the player lands on after climbing over.

@export var length := 2.0:
	set(value):
		length = maxf(value, 0.4)
		_rebuild()

## The clinging player's feet rest this far below the rail.
@export var foot_drop := 1.0:
	set(value):
		foot_drop = maxf(value, 0.0)
		_rebuild()

## Distance from the rail to the clinging player's centre line.
@export var cling_offset := 0.42
## Whether pushing toward the rail climbs over it.
@export var climb_over := true
## How far inside the rail the player lands after climbing over.
@export var climb_over_depth := 0.6
## Keeps the player away from the very ends of the rail.
@export var end_margin := 0.3

@export var show_rail := true:
	set(value):
		show_rail = value
		_rebuild()

@export var show_posts := true:
	set(value):
		show_posts = value
		_rebuild()

@export var material: Material:
	set(value):
		material = value
		_rebuild()

var _visual_root: Node3D
var _area_shape: CollisionShape3D


func _ready() -> void:
	super()
	if prompt == "Interact":
		prompt = "Grab"
	_rebuild()


func can_interact(player: Player) -> bool:
	if not enabled:
		return false
	var p := to_local(player.global_position)
	if absf(p.x) > length * 0.5 + 0.5:
		return false
	if p.z < -0.15 or p.z > 1.1:
		return false
	# Feet may be well below the cling height (grabbing from the ground) or a
	# little above it (grabbing at the top of a jump).
	return p.y > -(foot_drop + 1.35) and p.y < -foot_drop + 0.9


func interact(player: Player) -> bool:
	return player.begin_hang(self)


func get_interaction_distance(player: Player) -> float:
	var p := to_local(player.global_position)
	var along := maxf(absf(p.x) - length * 0.5, 0.0)
	return Vector2(along, p.z - cling_offset).length()


func get_shimmy_limit() -> float:
	return maxf(length * 0.5 - end_margin, 0.0)


## Where the player's feet attach (rail space) for a player at [param world_feet].
func get_attach_local(world_feet: Vector3) -> Vector3:
	var p := to_local(world_feet)
	var limit := get_shimmy_limit()
	return Vector3(clampf(p.x, -limit, limit), -foot_drop, cling_offset)


## Feet position (rail space) after climbing over at [param along] metres along the rail.
func get_exit_local(along: float) -> Vector3:
	return Vector3(along, -foot_drop + 0.03, -climb_over_depth)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _area_shape == null:
		_area_shape = CollisionShape3D.new()
		_area_shape.shape = BoxShape3D.new()
		add_child(_area_shape, false, Node.INTERNAL_MODE_BACK)
	var bottom := -(foot_drop + 1.35)
	var top := 0.5
	var box := _area_shape.shape as BoxShape3D
	box.size = Vector3(length + 0.8, top - bottom, 1.3)
	_area_shape.position = Vector3(0.0, (top + bottom) * 0.5, 0.45)

	if _visual_root != null:
		_visual_root.queue_free()
		_visual_root = null
	if not show_rail:
		return
	_visual_root = Node3D.new()
	add_child(_visual_root, false, Node.INTERNAL_MODE_BACK)
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(length, 0.07, 0.07)
	bar_mesh.material = material
	bar.mesh = bar_mesh
	_visual_root.add_child(bar)
	if show_posts and foot_drop > 0.1:
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.06, foot_drop, 0.06)
		post_mesh.material = material
		var count := maxi(int(ceilf(length / 1.5)) + 1, 2)
		for i in count:
			var post := MeshInstance3D.new()
			post.mesh = post_mesh
			var x := lerpf(-length * 0.5 + 0.03, length * 0.5 - 0.03, float(i) / float(count - 1))
			post.position = Vector3(x, -foot_drop * 0.5, 0.0)
			_visual_root.add_child(post)
