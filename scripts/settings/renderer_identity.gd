extends Node
## Confirm the selected backend before loading the first mission or touching a save.
func _enter_tree() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var method := RenderingServer.get_current_rendering_method()
	var driver := RenderingServer.get_current_rendering_driver_name()
	print("[renderer] active ", method, "/", driver, " / ", RenderingServer.get_video_adapter_name(),
		" / API ", RenderingServer.get_video_adapter_api_version())
	var requested := OS.get_environment("LTO_REQUESTED_RENDERER")
	if not requested.is_empty() and (driver != requested or method != "forward_plus"):
		var reason := "Requested Forward+/%s. Godot initialized %s/%s. Quit and select a supported renderer." % [requested, method, driver]
		push_error(reason)
		if not "--script" in OS.get_cmdline_args(): OS.alert(reason, "Last Train Out")
		get_tree().quit(2)

var load_progress: Dictionary = {}
var _destination := ""
var _first_script_ms := 0

func _ready() -> void:
	_first_script_ms = Time.get_ticks_msec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lto-launch-report="):
			_destination = arg.trim_prefix("--lto-launch-report=")
	if not _destination.is_empty():
		get_tree().scene_changed.connect(_measure_mission)
		_measure_mission.call_deferred()

func _measure_mission() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != "res://scenes/missions/harlow_escape.tscn":
		return
	get_tree().scene_changed.disconnect(_measure_mission)
	var graphics: Node = scene.get("graphics")
	await graphics.call("wait_for_render_ready")
	while not scene.get("journey").get("ready_to_play") or get_tree().paused:
		await get_tree().process_frame
	for tick in 3: await get_tree().physics_frame
	var ticks := Time.get_ticks_msec()
	var launcher := OS.get_environment("LTO_LAUNCH_EPOCH_USEC")
	var elapsed := (Time.get_unix_time_from_system() * 1000000.0 - launcher.to_int()) / 1000.0 if launcher.is_valid_int() else float(ticks)
	var intervals := []
	var previous := Time.get_ticks_usec()
	for frame in 30:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		intervals.append((now - previous) / 1000.0)
		previous = now
	var report := {"launcher_ready_ms":elapsed,"engine_ready_ms":ticks,"first_script_ms":_first_script_ms,
		"load":load_progress,"phases":PerformanceTrace.events,"first_frames_ms":intervals,
		"method":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),
		"adapter":RenderingServer.get_video_adapter_name(),"preset":graphics.get("current_index"),
		"user_dir":OS.get_user_data_dir(),"ready":true}
	FileAccess.open(_destination,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	await DiagnosticSceneRetirement.release(scene)
	get_tree().quit()
