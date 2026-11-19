class_name FabricatedMesh
extends RefCounted
## Shared original bevel geometry. Simple box colliders remain independent of art.

static var _unit: Mesh
static var _shapes: Dictionary = {}
static var _unit_arrays: Array = []
static var _cpu_shapes: Dictionary = {}
static var _unit_source: Mesh


static func clear_cache() -> void:
	_shapes.clear()
	_unit = null
	_unit_arrays.clear()
	_cpu_shapes.clear()
	_unit_source = null


static func unit_box() -> Mesh:
	if _unit == null:
		var scene := preload("res://assets/models/beveled_box.glb").instantiate()
		var instance := scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		_unit = instance.mesh
		scene.free()
	return _unit


static func unit_box_source() -> Mesh:
	if _unit_source == null:
		_unit_arrays = unit_box().surface_get_arrays(0)
		_unit_source = CpuMeshSource.new(_unit_arrays)
	return _unit_source


static func box(size: Vector3, material: Material) -> Mesh:
	var key := "%s/%s" % [size, material.get_instance_id() if material != null else 0]
	if not _shapes.has(key):
		var shape := ArrayMesh.new()
		shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _box_arrays(size,material))
		shape.surface_set_material(0, planar_material(material))
		_shapes[key] = shape
	return _shapes[key]


static func _box_arrays(size: Vector3, material: Material) -> Array:
	var key := "%s/%s" % [size, material.get_instance_id() if material != null else 0]
	if not _cpu_shapes.has(key):
		# ArrayMesh.surface_get_arrays() downloads GPU buffers on RenderingDevice.
		# Read the imported source once. Keep subsequent construction on the CPU:
		# uploading an intermediate box just to project/append it stalls the driver.
		if _unit_arrays.is_empty():
			unit_box_source()
		var arrays := _unit_arrays.duplicate(true)
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
		# Large flat walls/floors do not need three texture samples per pixel.
		# Bake metre-scaled planar UVs once, retaining all scanned PBR maps.
		if material is StandardMaterial3D and material.uv1_triplanar:
			arrays = _project_faces(arrays, material)
		_cpu_shapes[key] = arrays
	return _cpu_shapes[key]


static func _project_faces(source: Array, material: StandardMaterial3D) -> Array:
	var positions: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = source[Mesh.ARRAY_INDEX]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(planar_material(material))
	for triangle in range(0, indices.size(), 3):
		var a := positions[indices[triangle]]
		var b := positions[indices[triangle+1]]
		var c := positions[indices[triangle+2]]
		var face := (b-a).cross(c-a).normalized()
		var axis := face.abs().max_axis_index()
		for corner in 3:
			var index := indices[triangle+corner]
			var p := positions[index]*material.uv1_scale
			var uv := Vector2(p.x,-p.y)
			if axis == Vector3.AXIS_X:
				uv = Vector2(p.z,-p.y)
			elif axis == Vector3.AXIS_Y:
				uv = Vector2(p.x,p.z)
			surface.set_uv(uv)
			surface.set_normal(normals[index])
			surface.add_vertex(positions[index])
	surface.generate_tangents()
	surface.index()
	return surface.commit_to_arrays()


static func planar_material(material: Material) -> Material:
	if not material is StandardMaterial3D or not material.uv1_triplanar:
		return material
	var key := "planar/%d" % material.get_instance_id()
	if not _shapes.has(key):
		var projected := material.duplicate() as StandardMaterial3D
		projected.uv1_triplanar = false
		projected.uv1_scale = Vector3.ONE
		_shapes[key] = projected
	return _shapes[key]


static func ladder(width: float, height: float, material: Material) -> Mesh:
	var key := "ladder/%s/%s/%s" % [width,height,material.get_instance_id() if material != null else 0]
	if _shapes.has(key):
		return _shapes[key]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(planar_material(material))
	# Open steel channel stiles, flanges and wall stand-offs. The interaction
	# volume and original rung spacing stay in Ladder; this cache is art only.
	for sign in [-1.0,1.0]:
		var x: float = sign*width*.5
		_append_box(surface,Vector3(x,height*.5,.05),Vector3(.014,height,.075),material)
		for z in [.017,.083]:
			_append_box(surface,Vector3(x-sign*.018,height*.5,z),Vector3(.05,height,.012),material)
		for y in [.22,height-.22]:
			_append_box(surface,Vector3(x,y,-.025),Vector3(.05,.045,.15),material)
			_append_box(surface,Vector3(x,y,-.095),Vector3(.12,.12,.012),material)
	var rung := CylinderMesh.new()
	rung.top_radius = .022
	rung.bottom_radius = .022
	rung.height = width+.025
	rung.radial_segments = 12
	rung.rings = 1
	var rung_arrays := rung.get_mesh_arrays()
	var y := .22
	while y < height-.05:
		_append_arrays(surface,rung_arrays,Transform3D(Basis(Vector3.FORWARD,PI/2),Vector3(0,y,.05)))
		for sign in [-1.0,1.0]:
			_append_box(surface,Vector3(sign*width*.5,y,.05),Vector3(.025,.054,.056),material)
		y += .33
	_shapes[key] = surface.commit()
	return _shapes[key]


static func steel_column(size: Vector3, material: Material) -> Mesh:
	var key := "column/%s/%s" % [size,material.get_instance_id() if material != null else 0]
	if _shapes.has(key):
		return _shapes[key]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(planar_material(material))
	_append_box(surface,Vector3.ZERO,Vector3(size.x*.15,size.y,size.z),material)
	for sign in [-1.0,1.0]:
		_append_box(surface,Vector3(0,0,sign*size.z*.43),Vector3(size.x,size.y,size.z*.14),material)
		_append_box(surface,Vector3(0,sign*(size.y*.5-.018),0),Vector3(size.x*1.18,.036,size.z*1.18),material)
		for x in [-1.0,1.0]:
			for z in [-1.0,1.0]:
				_append_box(surface,Vector3(x*size.x*.35,sign*(size.y*.5-.005),z*size.z*.35),Vector3(.025,.025,.025),material)
	_shapes[key] = surface.commit()
	return _shapes[key]


static func _append_box(surface: SurfaceTool, at: Vector3, size: Vector3, material: Material) -> void:
	_append_arrays(surface,_box_arrays(size,material),Transform3D(Basis.IDENTITY,at))


static func _append_arrays(surface: SurfaceTool, arrays: Array, transform: Transform3D) -> void:
	surface.append_from(CpuMeshSource.new(arrays),0,transform)


static func gabled_roof(size: Vector2, rise: float, material: Material) -> Mesh:
	var x := size.x*.5
	var z := size.y*.5
	var points := [Vector3(-x,0,-z),Vector3(-x,0,z),Vector3(-x,rise,0),Vector3(x,0,-z),Vector3(x,0,z),Vector3(x,rise,0)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(planar_material(material))
	for triangle in [[0,3,5],[0,5,2],[2,5,4],[2,4,1],[0,2,1],[3,4,5]]:
		for index in triangle:
			var p: Vector3 = points[index]
			surface.set_uv(Vector2(p.x,p.z+p.y)*.5)
			surface.add_vertex(p)
	surface.generate_normals()
	surface.generate_tangents()
	surface.index()
	return surface.commit()
