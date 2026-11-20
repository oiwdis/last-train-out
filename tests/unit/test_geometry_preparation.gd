extends TestSuite
## Geometry fingerprints captured from 7df2f5a's implementation before changing
## construction. Expand triangle indices so indexing improvements are allowed.
## Position and UV precision is 0.0001; normals have separate analytic checks.

func after_each() -> void:
	FabricatedMesh.clear_cache()

func test_cpu_construction_retains_reviewed_positions_uvs_and_winding() -> void:
	var material := load("res://resources/materials/platform_concrete.tres") as Material
	var shapes := [FabricatedMesh.box(Vector3(2,3,.25),null),
		FabricatedMesh.box(Vector3(2,3,.25),material),
		FabricatedMesh.steel_column(Vector3(.4,3,.4),material),
		FabricatedMesh.ladder(.6,2,material)]
	var expected := ["055b35a7c21b6265bb858482cd73ca1b96646b2548491e3678f05f8494283817",
		"08a0f44ad8c6ecbfd0ae7589e3df736abced94f0668b56d3da34bead37312cbd",
		"18c814336bc88c4bd5420440131168b02eae4abf1024b7f3bd3de3795917b87e",
		"4d35def751a698143acbe3be548494bbec442f48e42f1aa1e8c78ff860447cb4"]
	for index in shapes.size():
		var arrays: Array = shapes[index].surface_get_arrays(0)
		var data := PackedInt32Array()
		for vertex: int in arrays[Mesh.ARRAY_INDEX]:
			var p: Vector3 = arrays[Mesh.ARRAY_VERTEX][vertex]
			var uv: Vector2 = arrays[Mesh.ARRAY_TEX_UV][vertex]
			for value: float in [p.x,p.y,p.z,uv.x,uv.y]:
				data.append(roundi(value*10000))
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(data.to_byte_array())
		check_eq(hash.finish().hex_encode(),expected[index],"authored geometry "+str(index))

func test_scene_teardown_releases_cpu_and_gpu_construction_caches() -> void:
	var material := load("res://resources/materials/platform_concrete.tres") as Material
	var shape := FabricatedMesh.box(Vector3(2,3,.25),material)
	var lifetime: WeakRef = weakref(shape)
	check_eq(FabricatedMesh.box(Vector3(2,3,.25),material),shape,"repeat construction reuses mesh")
	shape = null
	FabricatedMesh.clear_cache()
	check(lifetime.get_ref() == null,"generated mesh has no hidden cache owner after teardown")
	var rebuilt := FabricatedMesh.box(Vector3(2,3,.25),material)
	check_eq(rebuilt.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size(),324,"next scene rebuilds complete bevels")
