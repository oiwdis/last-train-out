extends Node
## Developer tool: renders the milestone's evidence screenshots.
##
## Needs a real renderer (not --headless). Example:
##   godot --path . --fixed-fps 60 tools/capture_screenshots.tscn -- --out=docs/screenshots
## The player is driven through its scripted-input hook, so every shot shows
## the real game state rather than a staged mock-up.

const MAIN_SCENE := "res://scenes/main/main.tscn"

var _out_dir := "res://docs/screenshots"
var _only := ""
var _game: Game
var _player: Player
var _train: Train
var _camera: CameraRig


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out_dir = argument.trim_prefix("--out=")
		elif argument.begins_with("--only="):
			_only = argument.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	_run.call_deferred()


func _run() -> void:
	var shots: Array[Callable] = [
		_shot_overview, _shot_platform, _shot_warehouse_a, _shot_warehouse_a_upper, _shot_warehouse_b,
		_shot_back_room, _shot_freight_yard, _shot_ladder, _shot_riding, _shot_debug_menu,
	]
	for shot in shots:
		if _only != "" and not String(shot.get_method()).contains(_only):
			continue
		await _load_game()
		await shot.call()
		_game.queue_free()
		await _frames(3)
	print("[capture] done")
	get_tree().quit()


func _load_game() -> void:
	_game = (load(MAIN_SCENE) as PackedScene).instantiate() as Game
	add_child(_game)
	_player = _game.player
	_train = _game.train
	_camera = _game.camera_rig
	_player.input.scripted = true
	_player.input.clear()
	await _frames(10)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _seconds(duration: float) -> void:
	await _frames(maxi(roundi(duration * Engine.physics_ticks_per_second), 1))


func _place(position: Vector3, facing: Vector3 = Vector3.RIGHT, settle: float = 2.5) -> void:
	_player.teleport_to(position, facing)
	await _seconds(settle)


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(file_name)
	var error := image.save_png(path)
	print("[capture] %s -> %s (%s)" % [file_name, path, error_string(error)])


# --- Shots -------------------------------------------------------------------

func _shot_overview() -> void:
	# A detached wide camera showing the whole station from the platform to the
	# freight yard. The decorative haze is thinned for this one shot only, so
	# the far end of the 120 m station stays legible from this distance.
	var atmosphere := _game.station.get_node("Atmosphere") as Atmosphere
	var environment := atmosphere.get_environment()
	var fog_density := environment.fog_density
	var volumetric := environment.volumetric_fog_enabled
	environment.fog_density = 0.0025
	environment.volumetric_fog_enabled = false
	var camera := Camera3D.new()
	camera.fov = 48.0
	camera.far = 800.0
	add_child(camera)
	camera.global_transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-17.0)), Vector3(60.0, 30.0, 80.0))
	camera.current = true
	await _seconds(1.0)
	await _save("01_harlow_junction_overview.png")
	camera.queue_free()
	environment.fog_density = fog_density
	environment.volumetric_fog_enabled = volumetric
	_camera.get_camera().current = true


func _shot_platform() -> void:
	await _place(Vector3(13.0, 1.05, 0.4))
	await _save("02_train_and_platform.png")


func _shot_warehouse_a() -> void:
	await _place(Vector3(44.5, 0.05, 1.2))
	await _save("03_warehouse_a_ground_floor.png")


func _shot_warehouse_a_upper() -> void:
	await _place(Vector3(51.0, 3.65, 1.2))
	await _save("04_warehouse_a_upper_floor.png")


func _shot_warehouse_b() -> void:
	await _place(Vector3(80.5, 0.05, 1.0))
	await _save("05_warehouse_b_main_hall.png")


func _shot_back_room() -> void:
	await _place(Vector3(86.5, 0.05, -0.1))
	await _save("06_warehouse_b_back_room.png")


func _shot_freight_yard() -> void:
	await _place(Vector3(106.6, 3.85, 0.2), Vector3.RIGHT)
	await _save("07_freight_yard.png")


func _shot_ladder() -> void:
	# Grab the crew car's ladder while the train pulls away, mid-climb.
	var ladder := _train.get_node("CrewCar/RoofLadder") as Ladder
	_train.max_speed = 4.0
	_train.set_mode_index(0)
	_train.start()
	await _seconds(3.0)
	_player.teleport_to(Vector3(ladder.global_position.x + 4.0, 1.05, -1.55), Vector3.FORWARD)
	for i in 600:
		await _frames(1)
		if absf(ladder.global_position.x - _player.global_position.x) < 0.5:
			_player.input.script_interact()
			break
	await _seconds(0.3)
	_player.input.script_move(0.0, -1.0)
	await _seconds(0.45)
	_player.input.script_move(0.0)
	await _seconds(1.2)
	await _save("08_grabbing_moving_ladder.png")


func _shot_riding() -> void:
	var crew_car := _train.get_node("CrewCar") as TrainCar
	_player.teleport_to(crew_car.to_global(Vector3(0.5, 3.7, 0.2)))
	await _seconds(0.5)
	_train.set_mode_index(1)
	_train.start()
	await _seconds(7.5)
	await _save("09_riding_the_moving_train.png")


func _shot_debug_menu() -> void:
	await _place(Vector3(20.0, 1.05, 0.4), Vector3.RIGHT, 1.0)
	_game.debug_menu.set_open(true)
	_train.start()
	_player.input.script_move(1.0, 0.0, true)
	await _seconds(1.6)
	await _save("10_debug_menu.png")
	_player.input.script_move(0.0)
