@tool
class_name Stairs
extends StaticBody3D
## A straight flight of stairs for gray-boxing.
##
## Local frame: the origin is the bottom-centre of the flight and the stairs
## rise toward +X. Collision is a single smooth wedge running through the
## front edge of every step (so a capsule walks up it without snagging); the
## steps themselves are visual only.

@export var run := 4.0:
	set(value):
		run = maxf(value, 0.2)
		_rebuild()

@export var rise := 2.0:
	set(value):
		rise = maxf(value, 0.1)
		_rebuild()

@export var width := 1.4:
	set(value):
		width = maxf(value, 0.3)
		_rebuild()

@export_range(2, 40) var step_count := 10:
	set(value):
		step_count = clampi(value, 2, 40)
		_rebuild()

@export var material: Material:
	set(value):
		material = value
		_rebuild()

var _shape_node: CollisionShape3D
var _visual_root: Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var tread := run / float(step_count)
	var riser := rise / float(step_count)
	var half := width * 0.5

	if _shape_node == null:
		_shape_node = CollisionShape3D.new()
		add_child(_shape_node, false, Node.INTERNAL_MODE_BACK)
	var wedge := ConvexPolygonShape3D.new()
	# The slope starts one tread early so it passes through each step's nosing.
	wedge.points = PackedVector3Array([
		Vector3(-tread, 0.0, -half), Vector3(-tread, 0.0, half),
		Vector3(run - tread, rise, -half), Vector3(run - tread, rise, half),
		Vector3(run, rise, -half), Vector3(run, rise, half),
		Vector3(run, 0.0, -half), Vector3(run, 0.0, half),
	])
	_shape_node.shape = wedge

	if _visual_root != null:
		_visual_root.queue_free()
	_visual_root = Node3D.new()
	add_child(_visual_root, false, Node.INTERNAL_MODE_BACK)
	for i in step_count:
		var step := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var length := run - tread * float(i)
		mesh.size = Vector3(length, riser, width)
		mesh.material = material
		step.mesh = mesh
		step.position = Vector3(tread * float(i) + length * 0.5, riser * (float(i) + 0.5), 0.0)
		_visual_root.add_child(step)
