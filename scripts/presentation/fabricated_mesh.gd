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
		var arrays := unit_box().surface_get_arrays(0).duplicate(true)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		for index in vertices.size():
			vertices[index] *= size
			# Nonuniform scaling needs inverse-transpose normals. Scaling normals like
			# positions tilted the ground's normal sideways and stretched triplanar maps.
			normals[index] = (normals[index] / size).normalized()
			if tangents.size() >= (index + 1) * 4:
				var tangent := Vector3(tangents[index*4], tangents[index*4+1], tangents[index*4+2]) * size
				tangent = (tangent - normals[index] * tangent.dot(normals[index])).normalized()
				tangents[index*4] = tangent.x
				tangents[index*4+1] = tangent.y
				tangents[index*4+2] = tangent.z
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = tangents
		var shape := ArrayMesh.new()
		shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		shape.surface_set_material(0, material)
		_shapes[key] = shape
	return _shapes[key]
