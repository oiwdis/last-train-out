extends SceneTree
## Reproducible real-time frame sampling, independent of the optional graphics controller.
## No --fixed-fps / Movie Maker. Run with --script and -- --suite=baseline or --suite=presets.

var _suite := "presets"
var _out := "/tmp/lto-render-benchmark.json"
var _frames := 120
var _warmup := 60
var _game: Node3D
var _lights: Array[Dictionary] = []
var _results: Array[Dictionary] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--suite="):
			_suite = arg.trim_prefix("--suite=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--warmup="):
			_warmup = maxi(int(arg.trim_prefix("--warmup=")), 8)
		elif arg.begins_with("--samples="):
			_frames = maxi(int(arg.trim_prefix("--samples=")), 12)
	_run.call_deferred()


func _run() -> void:
	_stage("loading scene")
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(_game)
	_stage("scene ready")
	_game.player.input.scripted = true
	_game.player.input.clear()
	_collect(_game)
	_game.camera_rig.set_physics_process(false)
	var immersive: Node = _game.camera_rig.get("exploration")
	if immersive != null:
		immersive.set_process(false)
	for trigger in _game.find_children("*", "CutawayTrigger", true, false):
		trigger.set_deferred("monitoring", false)
	await _render_frames(_warmup)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var cases: Array = ["Low", "Medium", "High"] if _suite in ["presets", "route"] else ["Milestone 1.5", "No volumetrics", "No shadows", "No local lights", "65% render scale"]
	for view in (["Warehouse entry pan"] if _suite == "route" else ["Platform", "Warehouse B"]):
		var warm_platform: bool = view != "Warehouse B"
		_game.player.teleport_to(Vector3(13, 1.05, 0.4) if warm_platform else Vector3(80.5, 0.05, 1))
		var eye: Camera3D = _game.camera_rig.get_camera()
		eye.global_position = Vector3(26, 2.6, 0.5) if warm_platform else Vector3(74, 1.6, 3)
		eye.look_at(Vector3(23, 2.1, -3.5) if warm_platform else Vector3(83, 1.6, 2))
		eye.fov = 78
		await _render_frames(_warmup)
		for index in cases.size():
			_stage(view+" / "+String(cases[index])+" / applying preset")
			_apply_case(index)
			if _suite == "route":
				# Warm up on the platform, so the first warehouse entry still
				# exposes its own newly encountered rendering work.
				eye.global_position = Vector3(26,2.6,.5)
				eye.look_at(Vector3(23,2.1,-3.5))
			await _render_frames(_warmup)
			_stage(view+" / "+String(cases[index])+" / sampling")
			var samples: Array[float] = []
			var calls := 0.0
			var primitives := 0.0
			var process_ms := 0.0
			var physics_ms := 0.0
			var cpu_ms := 0.0
			var gpu_ms := 0.0
			var texture_bytes := 0.0
			var last := Time.get_ticks_usec()
			for i in _frames:
				if _suite == "route":
					var fraction := float(i)/maxf(_frames-1,1)
					eye.global_position = Vector3(lerpf(69,80,fraction),1.6,3)
					eye.look_at(eye.global_position+Vector3(8,0,sin(fraction*TAU)*3))
				await RenderingServer.frame_post_draw
				var now := Time.get_ticks_usec()
				samples.append((now - last) / 1000.0)
				last = now
				calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
				process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000
				physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
				cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
				gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
				texture_bytes += Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
			var mean := 0.0
			for sample in samples:
				mean += sample / samples.size()
			samples.sort()
			var row := {"view": view, "case": cases[index], "samples": samples.size(),
				"mean_frame_ms": mean, "median_frame_ms": samples[samples.size() / 2],
				"p95_frame_ms": samples[mini(ceili(samples.size() * 0.95) - 1, samples.size() - 1)],
				"fps_from_mean": 1000.0 / mean, "draw_calls": calls / _frames,
				"primitives": primitives / _frames, "process_ms": process_ms / _frames,
				"physics_ms": physics_ms / _frames, "render_cpu_ms":cpu_ms/_frames, "render_gpu_ms":gpu_ms/_frames, "texture_bytes":texture_bytes/_frames, "max_frame_ms":samples[-1], "render_scale": root.scaling_3d_scale}
			row["pipeline_compilations"] = _pipeline_counts()
			_results.append(row)
			print("[benchmark] ", JSON.stringify(row))
	var report := {"suite": _suite, "godot": Engine.get_version_info()["string"],
		"os": OS.get_name(), "processor": OS.get_processor_name(),
		"processor_count": OS.get_processor_count(),
		"low_priority_thread_ratio": ProjectSettings.get_setting("threading/worker_pool/low_priority_thread_ratio"),
		"renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": str(root.size),
		"vsync": "disabled", "fixed_fps": false, "matched_camera": true, "warmup_frames":_warmup, "window_mode":DisplayServer.window_get_mode(), "results": _results}
	var file := FileAccess.open(_out, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write benchmark report: "+_out)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("[benchmark] wrote ", _out)
	# Let scene teardown restore shared material state while rendering is alive,
	# consistently with the ablation diagnostic, and record shutdown progress.
	_game.queue_free()
	await process_frame
	_stage("scene released")
	await process_frame
	_stage("material updates drained")
	var geometry_path := "res://scripts/presentation/fabricated_mesh.gd"
	if ResourceLoader.exists(geometry_path):
		load(geometry_path).clear_cache()
	_stage("quitting")
	quit()

func _pipeline_counts() -> Dictionary:
	var counts := {}
	var labels := ["canvas","mesh","surface","draw","specialization"]
	var monitors := [Performance.PIPELINE_COMPILATIONS_CANVAS,Performance.PIPELINE_COMPILATIONS_MESH,Performance.PIPELINE_COMPILATIONS_SURFACE,Performance.PIPELINE_COMPILATIONS_DRAW,Performance.PIPELINE_COMPILATIONS_SPECIALIZATION]
	for index in labels.size():
		counts[labels[index]] = Performance.get_monitor(monitors[index])
	return counts

func _stage(label: String) -> void:
	print("[benchmark-stage] ",Time.get_ticks_msec()," ms / ",label," / ",JSON.stringify(_pipeline_counts()))


func _collect(node: Node) -> void:
	if node is Light3D:
		_lights.append({"light": node, "shadow": node.shadow_enabled})
	for child in node.get_children(true):
		_collect(child)


func _apply_case(index: int) -> void:
	if _suite in ["presets", "route"]:
		_game.get("graphics").set_preset(index)
		return
	var atmosphere: Node = _game.station.get_node("Atmosphere")
	var environment: Environment = atmosphere.get_environment()
	environment.volumetric_fog_enabled = index != 1 and atmosphere._volumetric_fog_is_supported()
	for entry in _lights:
		var light := entry.light as Light3D
		light.shadow_enabled = bool(entry.shadow) and index != 2
		light.visible = index != 3 or light is DirectionalLight3D
	root.scaling_3d_scale = 0.65 if index == 4 else 1.0


func _render_frames(count: int) -> void:
	var graphics: Node = _game.get("graphics")
	if graphics != null and graphics.has_method("wait_for_render_ready"):
		await graphics.call("wait_for_render_ready")
	for i in count:
		await RenderingServer.frame_post_draw
