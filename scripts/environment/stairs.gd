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
	if rise > 2.0:
		_build_industrial_flight(tread, riser)
		return
	for i in step_count:
		var step := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var length := run - tread * float(i)
		mesh.size = Vector3(length, riser, width)
		mesh.material = material
		step.mesh = mesh
		step.position = Vector3(tread * float(i) + length * 0.5, riser * (float(i) + 0.5), 0.0)
		_visual_root.add_child(step)


func _build_industrial_flight(tread: float, riser: float) -> void:
	var steel := preload("res://resources/materials/metal_dark.tres")
	var surfaces := SurfaceTool.new()
	surfaces.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Open treads and structural stringers replace the solid staircase silhouette.
	for i in step_count:
		var y := riser * (i + 1)
		for bar in 6:
			var at := Vector3(tread * (i + (bar + 0.5) / 6.0), y - 0.025, 0)
			surfaces.append_from(FabricatedMesh.box(Vector3(tread / 8, 0.05, width), steel), 0, Transform3D(Basis.IDENTITY, at))
	for side in [-1.0, 1.0]:
		var a := Vector3(0, 0.03, side * (width / 2 - 0.035))
		var b := Vector3(run, rise, a.z)
		var direction := b-a
		var basis := Basis.looking_at(direction.normalized(), Vector3.UP)
		surfaces.append_from(FabricatedMesh.box(Vector3(0.08, 0.18, direction.length()), steel), 0, Transform3D(basis, (a+b)/2))
		for i in range(0, step_count, 3):
			var at := Vector3(tread*(i+0.5), riser*(i+1)+0.45, a.z)
			surfaces.append_from(FabricatedMesh.box(Vector3(0.035, 0.9, 0.035), steel), 0, Transform3D(Basis.IDENTITY, at))
		surfaces.append_from(FabricatedMesh.box(Vector3(0.045, 0.045, direction.length()), steel), 0, Transform3D(basis, (a+b)/2+Vector3.UP*0.95))
	var mesh := surfaces.commit()
	mesh.surface_set_material(0, steel)
	var flight := MeshInstance3D.new()
	flight.mesh = mesh
	_visual_root.add_child(flight)
