extends "res://tools/benchmark_milestone25.gd"
## Low-preset cost of this continuation against 86b2473, including the freight yard.
## Copy this exact script to the baseline checkout. No fixed FPS or Movie Maker.

func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(_game)
	_game.player.input.scripted = true
	_game.player.input.clear()
	_game.camera_rig.set_physics_process(false)
	_game.camera_rig.exploration.set_process(false)
	for trigger in _game.find_children("*","CutawayTrigger",true,false):
		trigger.set_deferred("monitoring",false)
	await _render_frames(8)
	_game.graphics.set_preset(0)
	for view in [
		["Platform",Vector3(13,1.05,.4),Vector3(26,2.6,.5),Vector3(23,2.1,-3.5)],
		["Warehouse B",Vector3(80.5,.05,1),Vector3(74,1.6,3),Vector3(83,1.6,2)],
		["Freight yard",Vector3(101,.05,6.6),Vector3(99,3.2,7.4),Vector3(114,2,9)],
	]:
		_game.player.teleport_to(view[1])
		var camera: Camera3D = _game.camera_rig.get_camera()
		camera.global_position = view[2]
		camera.look_at(view[3])
		camera.fov = 78
		await _render_frames(8)
		var samples: Array[float] = []
		var calls := 0.0
		var primitives := 0.0
		var last := Time.get_ticks_usec()
		for frame in _frames:
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			samples.append((now-last)/1000.0)
			last = now
			calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		var mean := 0.0
		for sample in samples:
			mean += sample/samples.size()
		samples.sort()
		var row := {"view":view[0],"case":"Low","samples":samples.size(),"mean_frame_ms":mean,"median_frame_ms":samples[samples.size()/2],"p95_frame_ms":samples[mini(ceili(samples.size()*.95)-1,samples.size()-1)],"fps_from_mean":1000/mean,"draw_calls":calls/_frames,"primitives":primitives/_frames,"render_scale":root.scaling_3d_scale}
		_results.append(row)
		print("[environment-benchmark] ",JSON.stringify(row))
	var report := {"godot":Engine.get_version_info()["string"],"os":OS.get_name(),"processor":OS.get_processor_name(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"vsync":"disabled","fixed_fps":false,"matched_camera":true,"results":_results}
	var file := FileAccess.open(_out,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("[environment-benchmark] wrote ",_out)
	RenderingServer.set_render_loop_enabled(false)
	_game.queue_free()
	await process_frame
	await process_frame
	FabricatedMesh.clear_cache()
	quit()
