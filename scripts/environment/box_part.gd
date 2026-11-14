@tool
class_name BoxPart
extends CollisionShape3D
## Gray-box building block: a box collider that also renders itself.
##
## Add as a direct child of any CollisionObject3D (StaticBody3D, AnimatableBody3D).
## The mesh and the collision shape are generated from [member size], so a level
## is described by one node per block instead of a mesh + shape + two resources.

## Full extents of the box in metres.
@export var size := Vector3.ONE:
	set(value):
		size = value.max(Vector3(0.01, 0.01, 0.01))
		_rebuild()

@export var material: Material:
	set(value):
		material = value
		_rebuild()

## When false the box is purely visual (collision disabled).
@export var solid := true:
	set(value):
		solid = value
		disabled = not solid

## When false the box collides but is not drawn (invisible barrier).
@export var show_mesh := true:
	set(value):
		show_mesh = value
		_rebuild()

@export var cast_shadow := true:
	set(value):
		cast_shadow = value
		_rebuild()

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	# Every instance owns its shape so resizing one block never affects another.
	shape = BoxShape3D.new()
	disabled = not solid
	_rebuild()


## The generated visual, or null when [member show_mesh] is off.
func get_mesh_instance() -> MeshInstance3D:
	return _mesh_instance


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var box := shape as BoxShape3D
	if box != null:
		box.size = size
	if not show_mesh:
		if _mesh_instance != null:
			_mesh_instance.queue_free()
			_mesh_instance = null
		return
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance, false, Node.INTERNAL_MODE_BACK)
	_mesh_instance.mesh = FabricatedMesh.box(size, material)
	_mesh_instance.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if cast_shadow
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
