class_name FabricatedMesh
extends RefCounted
## Shared original bevel geometry. Simple box colliders remain independent of art.

static var _unit: Mesh
static var _shapes: Dictionary = {}


static func clear_cache() -> void:
	_shapes.clear()
	_unit = null


static func unit_box() -> Mesh:
	if _unit == null:
		var scene := preload("res://assets/models/beveled_box.glb").instantiate()
		var instance := scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		_unit = instance.mesh
		scene.free()
	return _unit


static func box(size: Vector3, material: Material) -> Mesh:
	var key := "%s/%s" % [size, material.get_instance_id() if material != null else 0]
	if not _shapes.has(key):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.append_from(unit_box(), 0, Transform3D(Basis.IDENTITY.scaled(size), Vector3.ZERO))
		var shape := surface.commit()
		shape.surface_set_material(0, material)
		_shapes[key] = shape
	return _shapes[key]
