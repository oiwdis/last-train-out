extends TestSuite

func test_long_tracks_cull_small_fittings_in_local_sections() -> void:
	var track := Track.new()
	track.length = 1000.0
	add_child(track)
	var batches := 0
	for visual in track._visual_root.get_children():
		if visual is MultiMeshInstance3D:
			batches += 1
			check_less(visual.multimesh.instance_count, 64, "one visible section cannot submit a kilometre of sleepers/bolts")
			var arrays: Array = visual.multimesh.mesh.surface_get_arrays(0)
			check_less(arrays[Mesh.ARRAY_INDEX].size() / 3, 100, "tiny repeated fittings have a bounded triangle budget")
			check(visual.visibility_range_end > 0 and visual.visibility_range_end <= 100, "distant micro-details are culled")
	check_greater(batches, 50, "track instances have local spatial bounds")
	track.queue_free()
	await get_tree().process_frame

func after_each() -> void:
	FabricatedMesh.clear_cache()

func test_large_ground_surface_keeps_upward_normals_and_orthogonal_tangents() -> void:
	var mesh := FabricatedMesh.box(Vector3(720,1,52), null)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	var top_vertices := 0
	for index in range(0, indices.size(), 3):
		var a := indices[index]
		var b := indices[index+1]
		var c := indices[index+2]
		if absf(vertices[a].y-0.5) < 0.001 and absf(vertices[b].y-0.5) < 0.001 and absf(vertices[c].y-0.5) < 0.001:
			for corner in [a,b,c]:
				top_vertices += 1
				check_greater(normals[corner].y, 0.99, "ground's shading normal stays upward after a 720:1 scale")
				if tangents.size() > corner*4+2:
					var tangent := Vector3(tangents[corner*4], tangents[corner*4+1], tangents[corner*4+2])
					check_near(tangent.dot(normals[corner]), 0, 0.001, "normal-map tangent stays perpendicular")
	check_greater(top_vertices, 0, "test inspected actual horizontal top faces")
