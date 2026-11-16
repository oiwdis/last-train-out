class_name RenderWarmup
extends RefCounted
## Prepare scene-authored views without advancing gameplay or presenting camera cuts.
## Godot's shader bake stores intermediate code; destination-GPU pipelines still
## need their first draw, especially for generated geometry/material overrides.

static func prepare(scene: Node3D) -> void:
	var viewport := scene.get_viewport()
	var original := viewport.get_camera_3d()
	if original == null or viewport.disable_3d:
		return
	var views: Array[Node3D] = []
	for node in scene.get_tree().get_nodes_in_group("render_warmup_view"):
		if node is Node3D and scene.is_ancestor_of(node):
			views.append(node)
	if views.is_empty():
		return
	var started := Time.get_ticks_msec()
	var camera := Camera3D.new()
	camera.fov = 78
	camera.near = original.near
	camera.far = original.far
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scene.add_child(camera)
	camera.make_current()
	for view in views:
		camera.global_transform = view.global_transform
		camera.force_update_transform()
		RenderingServer.force_sync()
		# No buffer swap or simulated time: these views never appear to the player.
		RenderingServer.force_draw(false, 0.0)
		RenderingServer.force_draw(false, 0.0)
	original.make_current()
	camera.free()
	print("[render-warmup] ", views.size(), " views / ", Time.get_ticks_msec()-started,
		" ms / draw pipelines=", Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW))
