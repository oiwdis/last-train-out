extends SceneTree
## Reproducible real-time frame sampling, independent of the optional graphics controller.
## No --fixed-fps / Movie Maker. Run with --script and -- --suite=baseline or --suite=presets.

var _suite := "presets"
var _fog_state := "distant"
var _out := "/tmp/lto-render-benchmark.json"
var _frames := 24
var _game: Node3D
var _lights: Array[Dictionary] = []
var _results: Array[Dictionary] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fog-state="):
			_fog_state = arg.trim_prefix("--fog-state=")
		elif arg.begins_with("--suite="):
			_suite = arg.trim_prefix("--suite=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--samples="):
			_frames = maxi(int(arg.trim_prefix("--samples=")), 12)
	_run.call_deferred()


func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(_game)
	_game.player.input.scripted = true
	_game.player.input.clear()
	_collect(_game)
	_game.camera_rig.set_physics_process(false)
	var immersive: Node = _game.camera_rig.get("exploration")
	if immersive != null:
		immersive.set_process(false)
	for trigger in _game.find_children("*", "CutawayTrigger", true, false):
		trigger.set_deferred("monitoring", false)
	await _render_frames(8)
	_game.fog_system.set_physics_process(false)
	var cases: Array = ["Low", "Medium", "High"] if _suite == "presets" else ["Milestone 1.5", "No volumetrics", "No shadows", "No local lights", "65% render scale"]
	for view in ["Platform", "Warehouse B"]:
		_game.player.teleport_to(Vector3(13, 1.05, 0.4) if view == "Platform" else Vector3(80.5, 0.05, 1))
		var eye: Camera3D = _game.camera_rig.get_camera()
		eye.global_position = Vector3(26, 2.6, 0.5) if view == "Platform" else Vector3(74, 1.6, 3)
		eye.look_at(Vector3(23, 2.1, -3.5) if view == "Platform" else Vector3(83, 1.6, 2))
		eye.fov = 78
		var fog: FogSystem = _game.fog_system
		var progress := fog.route.project(_game.player.global_position)
		fog.simulation.front = progress - (210 if _fog_state == "distant" else 8)
		fog._update_players(0)
		await _render_frames(8)
		for index in cases.size():
			_apply_case(index)
			await _render_frames(8)
			var samples: Array[float] = []
			var calls := 0.0
			var primitives := 0.0
			var process_ms := 0.0
			var physics_ms := 0.0
			var last := Time.get_ticks_usec()
			for i in _frames:
				await RenderingServer.frame_post_draw
				var now := Time.get_ticks_usec()
				samples.append((now - last) / 1000.0)
				last = now
				calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
				process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000
				physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
			var mean := 0.0
			for sample in samples:
				mean += sample / samples.size()
			samples.sort()
			var row := {"view": view, "case": cases[index], "samples": samples.size(),
				"mean_frame_ms": mean, "median_frame_ms": samples[samples.size() / 2],
				"p95_frame_ms": samples[mini(ceili(samples.size() * 0.95) - 1, samples.size() - 1)],
				"fps_from_mean": 1000.0 / mean, "draw_calls": calls / _frames,
				"primitives": primitives / _frames, "process_ms": process_ms / _frames,
				"physics_ms": physics_ms / _frames, "render_scale": root.scaling_3d_scale}
			_results.append(row)
			print("[benchmark] ", JSON.stringify(row))
	var report := {"suite": _suite, "fog_state": _fog_state, "godot": Engine.get_version_info()["string"],
		"os": OS.get_name(), "processor": OS.get_processor_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": str(root.size),
		"vsync": "disabled", "fixed_fps": false, "matched_camera": true, "results": _results}
	var file := FileAccess.open(_out, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("[benchmark] wrote ", _out)
	quit()


func _collect(node: Node) -> void:
	if node is Light3D:
		_lights.append({"light": node, "shadow": node.shadow_enabled})
	for child in node.get_children(true):
		_collect(child)


func _apply_case(index: int) -> void:
	if _suite == "presets":
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
	for i in count:
		await RenderingServer.frame_post_draw
