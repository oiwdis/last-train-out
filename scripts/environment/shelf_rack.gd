@tool
class_name ShelfRack
extends StaticBody3D
## Open industrial shelving for gray-boxing: uprights, shelves and a few boxes.
##
## Local frame: the origin is the bottom-centre; the rack runs along X.
## Collision is one solid box, so racks act as walls that shape the aisles.

@export var length := 4.0:
	set(value):
		length = maxf(value, 0.5)
		_rebuild()

@export var height := 2.2:
	set(value):
		height = maxf(value, 0.4)
		_rebuild()

@export var depth := 0.6:
	set(value):
		depth = maxf(value, 0.2)
		_rebuild()

@export_range(1, 6) var shelf_count := 3:
	set(value):
		shelf_count = clampi(value, 1, 6)
		_rebuild()

## Changes which shelves carry boxes.
@export var clutter_seed := 1:
	set(value):
		clutter_seed = value
		_rebuild()

@export var frame_material: Material:
	set(value):
		frame_material = value
		_rebuild()

@export var cargo_material: Material:
	set(value):
		cargo_material = value
		_rebuild()

var _shape_node: CollisionShape3D
var _visual_root: Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape_node == null:
		_shape_node = CollisionShape3D.new()
		_shape_node.shape = BoxShape3D.new()
		add_child(_shape_node, false, Node.INTERNAL_MODE_BACK)
	(_shape_node.shape as BoxShape3D).size = Vector3(length, height, depth)
	_shape_node.position = Vector3(0.0, height * 0.5, 0.0)

	if _visual_root != null:
		_visual_root.queue_free()
	_visual_root = Node3D.new()
	add_child(_visual_root, false, Node.INTERNAL_MODE_BACK)

	# Uprights at regular intervals, on both faces of the rack.
	var bays := maxi(int(roundf(length / 1.6)), 1)
	var upright_mesh := BoxMesh.new()
	upright_mesh.size = Vector3(0.07, height, 0.07)
	upright_mesh.material = frame_material
	for i in bays + 1:
		var x := lerpf(-length * 0.5 + 0.035, length * 0.5 - 0.035, float(i) / float(bays))
		for side: float in [-1.0, 1.0]:
			_add_mesh(upright_mesh, Vector3(x, height * 0.5, side * (depth * 0.5 - 0.035)))

	# Shelves, evenly spaced with the top one near the top of the rack.
	var shelf_mesh := BoxMesh.new()
	shelf_mesh.size = Vector3(length, 0.05, depth)
	shelf_mesh.material = frame_material
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(clutter_seed)
	var spacing := (height - 0.1) / float(shelf_count)
	for level in shelf_count:
		var shelf_y := 0.2 + spacing * float(level)
		_add_mesh(shelf_mesh, Vector3(0.0, shelf_y, 0.0))
		# Scatter a few boxes on this shelf.
		var room := spacing - 0.12
		if room < 0.2:
			continue
		var x := -length * 0.5 + 0.25
		while x < length * 0.5 - 0.5:
			var box_length := rng.randf_range(0.35, 0.8)
			if rng.randf() < 0.62 and x + box_length < length * 0.5 - 0.1:
				var cargo := BoxMesh.new()
				var box_height := minf(rng.randf_range(0.22, 0.55), room)
				cargo.size = Vector3(box_length, box_height, depth * rng.randf_range(0.6, 0.85))
				cargo.material = cargo_material
				_add_mesh(cargo, Vector3(x + box_length * 0.5, shelf_y + 0.025 + box_height * 0.5, 0.0))
			x += box_length + rng.randf_range(0.08, 0.45)


func _add_mesh(mesh: Mesh, at: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	_visual_root.add_child(instance)
