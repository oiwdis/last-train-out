extends "res://tools/benchmark_milestone25.gd"
## Controlled Warehouse B ablations. Diagnostic omissions are never saved as presets.

func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(_game)
	_game.player.input.scripted = true
	_game.player.input.clear()
	_game.camera_rig.set_physics_process(false)
	_game.camera_rig.exploration.set_process(false)
	for trigger in _game.find_children("*", "CutawayTrigger", true, false):
		trigger.set_deferred("monitoring", false)
	await _render_frames(_warmup)
	_game.player.teleport_to(Vector3(80.5,.05,1))
	var camera: Camera3D = _game.camera_rig.get_camera()
	camera.global_position = Vector3(74,1.6,3)
	camera.look_at(Vector3(83,1.6,2))
	camera.fov = 78
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var environment: Environment = _game.station.get_node("Atmosphere").get_environment()
	# Apple Paravirtual CI does not support volumetrics. Keep them off for the
	# main ablation series on every machine, and report that capability explicitly.
	# The normal game presets and their physical-GPU fog path are unchanged.
	_game.station.get_node("Atmosphere").use_volumetric_fog = false
	var cases := ["High", "No local shadows", "No directional shadows", "No shadows", "No local lights", "No SSAO", "No MSAA", "No normal or roughness maps", "LOD 2.5", "65% pixels", "No animation", "High repeat"]
	for label in cases:
		_game.graphics.set_preset(2)
		for entry in _game.graphics._lights:
			var light: Light3D = entry.light
			light.visible = label != "No local lights" or light is DirectionalLight3D
			if label == "No shadows" or (label == "No local shadows" and not light is DirectionalLight3D) or (label == "No directional shadows" and light is DirectionalLight3D):
				light.shadow_enabled = false
		if label == "No SSAO": environment.ssao_enabled = false
		if label == "No MSAA": root.msaa_3d = Viewport.MSAA_DISABLED
		for rig in _game.find_children("*", "WorkerAnimator", true, false):
			rig.set_physics_process(label != "No animation")
			rig.animation.active = label != "No animation"
			var correction: SkeletonModifier3D = rig.get("pose_correction")
			if correction != null:
				correction.active = label != "No animation"
		if label == "No normal or roughness maps":
			for material: StandardMaterial3D in _game.graphics._materials:
				material.normal_enabled = false
				material.roughness_texture = null
		if label == "LOD 2.5": root.mesh_lod_threshold = 2.5
		if label == "65% pixels": root.scaling_3d_scale = .65
		await _render_frames(_warmup)
		var intervals: Array[float] = []
		var totals := {"draw_calls":0.0,"primitives":0.0,"render_cpu_ms":0.0,"render_gpu_ms":0.0,"texture_bytes":0.0}
		var last := Time.get_ticks_usec()
		for frame in _frames:
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			intervals.append((now-last)/1000.0)
			last = now
			totals.draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)/_frames
			totals.primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)/_frames
			totals.render_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())/_frames
			totals.render_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())/_frames
			totals.texture_bytes += Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/_frames
		intervals.sort()
		totals.merge({"case":label,"median_ms":intervals[intervals.size()/2],"p95_ms":intervals[mini(ceili(intervals.size()*.95)-1,intervals.size()-1)],"samples":_frames,"volumetric_fog":environment.volumetric_fog_enabled,"render_scale":root.scaling_3d_scale})
		_results.append(totals)
		print("[profile] ", JSON.stringify(totals))
	var report := {"godot":Engine.get_version_info()["string"],"processor":OS.get_processor_name(),"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":str(root.size),"vsync":"disabled","fixed_fps":false,"view":"Warehouse B","volumetric_policy":"disabled for the ablation series to match Apple Paravirtual CI capability","results":_results}
	var file := FileAccess.open(_out,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	_game.queue_free()
	await process_frame
	await process_frame
	FabricatedMesh.clear_cache()
	quit()
