extends Node
## Self-test for exported builds.
##
## The GitHub Actions build launches the exported game with this scene to prove
## that the packaged app starts on its own (no Godot editor involved), finds its
## game data, and that the game actually runs:
##
##   "Last Train Out.app/Contents/MacOS/Last Train Out" \
##       res://scenes/main/self_test.tscn -- --selftest-report=/tmp/report.json
##
## It loads the real main scene, drives the player and the train for a few
## seconds through the same scripted-input hook the automated tests use, writes
## a JSON report and quits. Exit code 0 means every check passed.
##
## Normal play never loads this scene; nothing here changes the game.

const MAIN_SCENE_SETTING := "application/run/main_scene"
const REPORT_ARGUMENT := "--selftest-report="
const SCREENSHOT_ARGUMENT := "--selftest-screenshot="
const REPORT_ENVIRONMENT := "LASTTRAINOUT_SELFTEST"
## The whole run is abandoned after this many real seconds.
const WATCHDOG_SECONDS := 120.0
const THUMBNAIL_SIZE := Vector2i(480, 270)


## Counts engine and script errors raised while the self-test runs.
class ErrorCounter:
	extends Logger

	var _mutex := Mutex.new()
	var _messages: Array[String] = []

	func _log_error(
		_function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_messages.append("%s (%s:%d)" % [rationale if rationale != "" else code, file, line])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func get_messages() -> Array[String]:
		_mutex.lock()
		var copy := _messages.duplicate()
		_mutex.unlock()
		return copy


var _report_path := ""
var _screenshot_path := ""
var _checks: Dictionary = {}
var _details: Dictionary = {}
var _report: Dictionary = {}
var _errors := ErrorCounter.new()
var _finished := false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(REPORT_ARGUMENT):
			_report_path = argument.trim_prefix(REPORT_ARGUMENT)
		elif argument.begins_with(SCREENSHOT_ARGUMENT):
			_screenshot_path = argument.trim_prefix(SCREENSHOT_ARGUMENT)
	if _report_path == "":
		_report_path = OS.get_environment(REPORT_ENVIRONMENT)
	OS.add_logger(_errors)
	# Real-time watchdog: a hung self-test must still write its report and quit.
	get_tree().create_timer(WATCHDOG_SECONDS, true, false, true).timeout.connect(_on_watchdog)
	_run.call_deferred()


func _run() -> void:
	_describe_environment()
	await _check_game()
	if not _is_headless():
		await _check_rendering()
	var errors := _errors.get_messages()
	_check("no_engine_errors", errors.is_empty(), "; ".join(errors.slice(0, 5)))
	_finish("")


# --- Checks ------------------------------------------------------------------

func _describe_environment() -> void:
	_report["app"] = ProjectSettings.get_setting("application/config/name", "")
	_report["version"] = ProjectSettings.get_setting("application/config/version", "")
	_report["godot"] = Engine.get_version_info()["string"]
	_report["os"] = "%s %s" % [OS.get_name(), OS.get_version()]
	_report["architecture"] = Engine.get_architecture_name()
	_report["processor"] = OS.get_processor_name()
	_report["executable"] = OS.get_executable_path()
	_report["headless"] = _is_headless()
	_report["display_server"] = DisplayServer.get_name()
	_report["rendering_method"] = RenderingServer.get_current_rendering_method()
	_report["rendering_driver"] = RenderingServer.get_current_rendering_driver_name()
	_report["video_adapter"] = RenderingServer.get_video_adapter_name()
	_report["physics_engine"] = ProjectSettings.get_setting("physics/3d/physics_engine", "DEFAULT")
	# An exported game runs on an export template, never on the editor binary.
	_report["exported_build"] = OS.has_feature("template")
	_report["release_build"] = OS.has_feature("release")
	_report["editor_build"] = OS.has_feature("editor")


func _check_game() -> void:
	var main_scene: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING, "")
	var packed := load(main_scene) as PackedScene if main_scene != "" else null
	if not _check("main_scene_loads", packed != null, main_scene):
		return
	var game := packed.instantiate() as Game
	if not _check("main_scene_is_the_game", game != null):
		return
	add_child(game)
	await _physics_frames(45)

	var player := game.player
	var train := game.train
	var atmosphere := game.station.get_node_or_null(^"Atmosphere") as Atmosphere if game.station != null else null
	if atmosphere != null and atmosphere.get_environment() != null:
		# Informational: the haze is skipped on GPUs that cannot render it.
		_report["volumetric_fog"] = atmosphere.get_environment().volumetric_fog_enabled
	_check("station_is_harlow_junction", game.station != null and game.station.station_name == "Harlow Junction")
	_check("train_has_locomotive_and_two_cars", train != null and train.get_cars().size() == 3)
	_check("player_stands_on_the_platform",
		player != null and player.is_grounded() and absf(player.global_position.y - 1.0) < 0.1,
		str(player.global_position.snappedf(0.01)) if player != null else "")
	if player == null or train == null:
		return

	var missing_actions: Array[String] = []
	for action: StringName in [&"move_left", &"move_right", &"move_in", &"move_out", &"sprint", &"jump", &"interact", &"debug_toggle", &"inventory_toggle", &"drop_item", &"drop_cargo", &"graphics_cycle", &"perspective_toggle"]:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			missing_actions.append(String(action))
	_check("input_map_is_complete", missing_actions.is_empty(), ", ".join(missing_actions))

	# Walk and jump through the scripted-input hook.
	player.input.scripted = true
	player.input.clear()
	var start_x := player.global_position.x
	player.input.script_move(1.0)
	await _physics_frames(40)
	player.input.script_move(0.0)
	_check("player_walks", player.global_position.x - start_x > 1.0, "%.2f m" % (player.global_position.x - start_x))
	await _physics_frames(15)
	player.input.script_jump()
	await _physics_frames(8)
	_check("player_jumps", not player.is_grounded())
	for i in 120:
		await get_tree().physics_frame
		if player.is_grounded():
			break
	_check("player_lands", player.is_grounded())

	# Ride the departing train: the milestone's defining mechanic.
	var flat_car := train.get_node_or_null(^"FlatCar") as TrainCar
	if not _check("flat_car_exists", flat_car != null):
		return
	player.teleport_to(flat_car.to_global(Vector3(0.0, 1.05, 0.35)))
	await _physics_frames(30)
	await get_tree().process_frame
	var relative_start := flat_car.to_local(player.global_position)
	train.set_mode_index(0)
	train.start()
	var drift := 0.0
	var left_train := false
	# Sample at the end of rendered frames (what a player sees) for up to five
	# seconds of game time; rendering speed must not change the outcome.
	var first_tick := Engine.get_physics_frames()
	while Engine.get_physics_frames() - first_tick < 300:
		await get_tree().process_frame
		drift = maxf(drift, flat_car.to_local(player.global_position).distance_to(relative_start))
		if not player.is_on_train():
			left_train = true
		if train.speed > 5.0:
			break
	_check("train_departs", train.speed > 2.0 and train.distance > 1.0, "%.2f m/s after %.1f m" % [train.speed, train.distance])
	_check("player_rides_the_moving_train", not left_train and drift < 0.05, "drift %.4f m" % drift)

	# The debug menu reports live state.
	if game.debug_menu != null:
		game.debug_menu.set_open(true)
		await _physics_frames(20)
		_check("debug_menu_reports_live_state",
			game.debug_menu.get_diagnostic("On train") == "yes" and game.debug_menu.get_diagnostic("Train state") != "STOPPED",
			"On train: %s, train state: %s" % [game.debug_menu.get_diagnostic("On train"), game.debug_menu.get_diagnostic("Train state")])
	player.input.clear()
	await _check_immersive_train(game)
	await _check_scavenging(game)


func _check_immersive_train(game: Game) -> void:
	game.debug_menu.set_open(false)
	game.reset_station()
	await _physics_frames(5)
	var view := game.camera_rig.exploration
	_check("immersive_camera_present", view != null and game.player.input.camera_relative)
	var crew := game.train.get_node("CrewCar") as TrainCar
	game.player.teleport_to(crew.to_global(Vector3(-2, 1.05, 0)))
	view.request_perspective(0)
	await _physics_frames(60)
	_check("first_person_eye_in_export", view.camera.global_position.distance_to(game.player.global_position + Vector3.UP * 1.6) < 0.1 and not game.player.visual.visible)
	game.train.start()
	game.player.input.script_move(1)
	await _physics_frames(60)
	game.player.input.clear()
	await get_tree().process_frame
	_check("walk_inside_moving_car_in_export", game.player.is_on_train() and crew.to_local(game.player.global_position).x > 0.5)
	var velocity := game.player.velocity
	view.request_perspective(1)
	_check("perspective_switch_preserves_motion_in_export", game.player.velocity == velocity)
	await _physics_frames(60)
	_check("third_person_camera_in_export", view.perspective == 1 and view._boom > 2)
	game.reset_station()
	await _physics_frames(5)
	var locomotive := game.train.get_node("Locomotive") as TrainCar
	game.player.teleport_to(locomotive.to_global(Vector3(-2.7, 1.05, 0)))
	view.request_perspective(0)
	await _physics_frames(60)
	view.aim_at(locomotive.interior.controls[0].global_position)
	game.player.input.script_interact()
	await _physics_frames(10)
	_check("physical_cab_control_in_export", game.train.state == Train.State.ACCELERATING)


func _check_scavenging(game: Game) -> void:
	game.debug_menu.set_open(false)
	game.reset_station()
	await _physics_frames(5)
	var service := game.scavenging
	if not _check("scavenging_system_present", service != null and service.containers.size() == 13):
		return
	var cache := service.containers[0]
	game.player.teleport_to(cache.global_position + Vector3(0, 0.05, -0.8), Vector3.BACK)
	await _physics_frames(20)
	game.camera_rig.exploration.aim_at(cache.global_position + Vector3.UP * 0.65)
	var contents_before := cache.contents.totals()
	game.player.input.script_interact()
	await _physics_frames(ceili(cache.search_seconds * 60) + 12)
	_check("search_completes_in_export", cache.is_searched and game.inventory_system.backpack.used_slots() > 0)
	game.player.teleport_to(service.storage_point.global_position + Vector3(0, 0.05, 0.75), Vector3.FORWARD)
	await _physics_frames(20)
	var deposited := service.deposit_all()
	_check("supplies_deposit_in_export", deposited > 0 and game.inventory_system.backpack.used_slots() == 0)
	_check("exported_loot_is_conserved", game.inventory_system.storage.totals() == contents_before)
	_check("supplies_withdraw_in_export", service.withdraw_slot(0) > 0)
	var cargo := service.spawn_world(ItemCatalog.find(&"coal_sack"), 1, game.player.global_position + Vector3(0.4, 0.15, 0))
	await _physics_frames(15)
	service.pick_up(game.player, cargo)
	_check("physical_cargo_is_carried_in_export", service.carried == cargo and game.player.carrying_heavy)
	for perspective in [1, 0]:
		game.camera_rig.exploration.request_perspective(perspective)
		await _physics_frames(5)
		_check("cargo_anchor_perspective_%d_in_export" % perspective, cargo.get_parent() == game.player.carry_anchor and service.carried == cargo)
	service.drop_heavy()
	_check("physical_cargo_is_released_in_export", cargo.available and not game.player.carrying_heavy)
	for i in 3:
		game.graphics.set_preset(i)
		await _physics_frames(2)
	_check("graphics_presets_work_in_export", game.graphics.current_index == 2)
	game.graphics.set_preset(1)
	game.supply_ui.open()
	_check("inventory_ui_opens_in_export", game.supply_ui.is_open())


func _check_rendering() -> void:
	# Let the renderer run for a moment, then look at what it drew.
	var started := Time.get_ticks_usec()
	var frames := 0
	while Time.get_ticks_usec() - started < 2_000_000:
		await get_tree().process_frame
		frames += 1
	var elapsed := float(Time.get_ticks_usec() - started) / 1_000_000.0
	_report["frames_in_sample"] = frames
	_report["average_fps"] = snappedf(float(frames) / maxf(elapsed, 0.001), 0.1)
	_report["window_size"] = "%dx%d" % [get_window().size.x, get_window().size.y]
	_check("frames_are_produced", frames > 5, "%d frames in %.1f s" % [frames, elapsed])

	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if not _check("frame_can_be_captured", image != null and not image.is_empty()):
		return
	if _screenshot_path != "":
		image.save_png(_screenshot_path)
	# A rendered scene has many different colours; a blank window has one.
	var probe := image.duplicate() as Image
	probe.resize(64, 36, Image.INTERPOLATE_BILINEAR)
	var colours: Dictionary = {}
	for y in probe.get_height():
		for x in probe.get_width():
			var c := probe.get_pixel(x, y)
			colours[Vector3i(int(c.r * 15.0), int(c.g * 15.0), int(c.b * 15.0))] = true
	_check("frame_is_not_blank", colours.size() >= 8, "%d distinct colours" % colours.size())
	var thumbnail := image.duplicate() as Image
	thumbnail.resize(THUMBNAIL_SIZE.x, THUMBNAIL_SIZE.y, Image.INTERPOLATE_LANCZOS)
	thumbnail.convert(Image.FORMAT_RGB8)
	_report["thumbnail"] = "data:image/jpeg;base64," + Marshalls.raw_to_base64(thumbnail.save_jpg_to_buffer(0.75))


# --- Plumbing ----------------------------------------------------------------

func _check(check_name: String, passed: bool, detail: String = "") -> bool:
	_checks[check_name] = passed
	if detail != "":
		_details[check_name] = detail
	print("[self-test] %s  %s%s [%d ms]" % ["ok  " if passed else "FAIL", check_name, ("  (%s)" % detail) if detail != "" else "", Time.get_ticks_msec()])
	return passed


func _physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func _on_watchdog() -> void:
	_finish("timed out after %d seconds" % int(WATCHDOG_SECONDS))


func _finish(fatal: String) -> void:
	if _finished:
		return
	_finished = true
	var passed := fatal == "" and not _checks.is_empty() and not _checks.values().has(false)
	_report["checks"] = _checks
	_report["details"] = _details
	_report["fatal"] = fatal
	_report["passed"] = passed
	if _report_path != "":
		var file := FileAccess.open(_report_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(_report, "  "))
			file.close()
		else:
			push_warning("Self-test could not write its report to %s" % _report_path)
	print("[self-test] %s" % ("PASSED" if passed else "FAILED" + ((": " + fatal) if fatal != "" else "")))
	get_tree().quit(0 if passed else (2 if fatal != "" else 1))
