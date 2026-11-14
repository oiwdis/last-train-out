@tool
class_name Track
extends Node3D
## Visual-only straight railway track: two rails, sleepers and a ballast strip.
##
## Local frame: the track starts at the origin and runs toward +X, with the
## top of the rails at y = [member rail_height]. There is no collision - the
## train is moved by script, and the player simply walks on the ground.

@export var length := 100.0:
	set(value):
		length = maxf(value, 1.0)
		_rebuild()

## Distance between the rail centres.
@export var gauge := 1.5:
	set(value):
		gauge = maxf(value, 0.3)
		_rebuild()

@export var rail_height := 0.1:
	set(value):
		rail_height = maxf(value, 0.02)
		_rebuild()

@export var sleeper_spacing := 0.7:
	set(value):
		sleeper_spacing = maxf(value, 0.2)
		_rebuild()

@export var ballast_width := 2.9:
	set(value):
		ballast_width = maxf(value, 0.0)
		_rebuild()

@export var rail_material: Material:
	set(value):
		rail_material = value
		_rebuild()

@export var sleeper_material: Material:
	set(value):
		sleeper_material = value
		_rebuild()

@export var ballast_material: Material:
	set(value):
		ballast_material = value
		_rebuild()

var _visual_root: Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _visual_root != null:
		_visual_root.queue_free()
	_visual_root = Node3D.new()
	add_child(_visual_root, false, Node.INTERNAL_MODE_BACK)

	if ballast_width > 0.0:
		var ballast := MeshInstance3D.new()
		var ballast_mesh := BoxMesh.new()
		ballast_mesh.size = Vector3(length, 0.02, ballast_width)
		ballast_mesh.material = ballast_material
		ballast.mesh = ballast_mesh
		ballast.position = Vector3(length * 0.5, 0.01, 0.0)
		ballast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual_root.add_child(ballast)

	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(length, rail_height - 0.04, 0.08)
	rail_mesh.material = rail_material
	for side: float in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.position = Vector3(length * 0.5, 0.04 + (rail_height - 0.04) * 0.5, side * gauge * 0.5)
		rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual_root.add_child(rail)

	# Sleepers share one draw call through a MultiMesh.
	var count := int(length / sleeper_spacing)
	if count <= 0:
		return
	var sleeper_mesh := BoxMesh.new()
	sleeper_mesh.size = Vector3(0.24, 0.05, gauge + 0.8)
	sleeper_mesh.material = sleeper_material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = sleeper_mesh
	multimesh.instance_count = count
	for i in count:
		var x := sleeper_spacing * (float(i) + 0.5)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, 0.035, 0.0)))
	var sleepers := MultiMeshInstance3D.new()
	sleepers.multimesh = multimesh
	sleepers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_root.add_child(sleepers)
