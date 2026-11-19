class_name RenderWarmup
extends RefCounted
## Prepare scene-authored views on normal rendered frames behind a loading panel.
## Shader baking stores intermediate code; destination-GPU pipelines still need
## their first draw. Pause/restore gameplay while those draws are prepared.

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
	var tree := scene.get_tree()
	var was_paused := tree.paused
	var state := {"active": true}
	var restore_on_exit := func() -> void:
		if state.active:
			tree.paused = was_paused
			state.active = false
	scene.tree_exiting.connect(restore_on_exit, CONNECT_ONE_SHOT)
	tree.paused = true
	var cover := CanvasLayer.new()
	cover.layer = 128
	cover.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.add_child(cover)
	var background := ColorRect.new()
	background.color = Color("101a1e")
	cover.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = "Preparing scene…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	background.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var camera := Camera3D.new()
	camera.fov = 78
	camera.near = original.near
	camera.far = original.far
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scene.add_child(camera)
	camera.make_current()
	for source in tree.get_nodes_in_group("render_warmup_material"):
		if source is MeshInstance3D and scene.is_ancestor_of(source):
			var proxy := MeshInstance3D.new()
			var quad := QuadMesh.new()
			quad.size = Vector2(4,4)
			quad.material = source.get_active_material(0)
			proxy.mesh = quad
			proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			camera.add_child(proxy)
			proxy.position = Vector3(0,0,-4)
			await _frame(tree)
			if not state.active:
				return
			proxy.free()
	for view in views:
		camera.global_transform = view.global_transform
		for frame in 2:
			await _frame(tree)
			if not state.active:
				return
	original.make_current()
	camera.free()
	# Consume the last preparation frame's delta while the game is still paused.
	# Only then restore play, so slow compilation cannot advance the next frame's
	# player/train/danger simulation by the loading interval.
	await _frame(tree)
	if not state.active:
		return
	cover.free()
	scene.tree_exiting.disconnect(restore_on_exit)
	tree.paused = was_paused
	state.active = false
	print("[render-warmup] ", views.size(), " views / ", Time.get_ticks_msec()-started,
		" ms / draw pipelines=", Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW))

static func _frame(tree: SceneTree) -> void:
	if DisplayServer.get_name() == "headless":
		await tree.process_frame
	else:
		await RenderingServer.frame_post_draw
