extends TestSuite
## What the player actually sees: positions after physics interpolation.
##
## Physics runs at 30 Hz here while frames are produced at 60 Hz, so every other
## rendered frame falls between two physics ticks and is interpolated. A rider
## must not shimmer against the car in those in-between frames either.

const SANDBOX := "res://scenes/main/movement_sandbox.tscn"

var _saved_ticks := 60


func before_each() -> void:
	_saved_ticks = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 30


func after_each() -> void:
	await free_spawned()
	Engine.physics_ticks_per_second = _saved_ticks
	await physics_frames(2)


func test_interpolated_rider_does_not_jitter() -> void:
	check(ProjectSettings.get_setting("physics/common/physics_interpolation", false), "physics interpolation is enabled for the project")
	var game := await spawn_scene(SANDBOX) as Game
	var player := game.player
	var train := game.train
	var car := train.get_node("FlatCar") as TrainCar
	player.input.scripted = true
	player.teleport_to(car.to_global(Vector3(0.0, 1.05, 0.35)))
	await physics_frames(15)
	train.set_mode_index(0)
	train.start()
	await physics_frames(30)
	var start := Vector3.ZERO
	var worst_drift := 0.0
	var worst_step := 0.0
	var previous := Vector3.ZERO
	var samples := 0
	var between_ticks := 0
	var last_tick := Engine.get_physics_frames()
	for i in 600:
		await get_tree().process_frame
		if Engine.get_physics_frames() == last_tick:
			between_ticks += 1
		last_tick = Engine.get_physics_frames()
		var car_shown := car.get_global_transform_interpolated()
		var player_shown := player.get_global_transform_interpolated()
		var relative := car_shown.affine_inverse() * player_shown.origin
		if samples == 0:
			start = relative
		else:
			worst_drift = maxf(worst_drift, relative.distance_to(start))
			worst_step = maxf(worst_step, relative.distance_to(previous))
		previous = relative
		samples += 1
	note("%d rendered frames (%d between physics ticks), train %.1f m/s, drift %.5f m, frame-to-frame jitter %.5f m" % [
		samples, between_ticks, train.speed, worst_drift, worst_step])
	check_greater(float(between_ticks), 100.0, "frames were rendered between physics ticks")
	check_greater(train.speed, 10.0, "the train got up to speed")
	check(player.is_on_train(), "the rider stayed aboard at 30 physics ticks per second")
	check_less(worst_drift, 0.02, "the rendered rider does not drift against the rendered car")
	check_less(worst_step, 0.005, "the rendered rider does not jitter against the rendered car")


func test_interpolated_ladder_climber_does_not_jitter() -> void:
	var game := await spawn_scene(SANDBOX) as Game
	var player := game.player
	var train := game.train
	var car := train.get_node("CrewCar") as TrainCar
	var ladder := car.get_node("RoofLadder") as Ladder
	player.input.scripted = true
	player.teleport_to(Vector3(ladder.global_position.x, 1.05, -1.6), Vector3.FORWARD)
	await physics_frames(8)
	player.input.script_interact()
	await physics_frames(20)
	check_eq(player.state, Player.State.CLIMB, "player holds the ladder")
	train.set_mode_index(0)
	train.start()
	await physics_frames(30)
	var start := Vector3.ZERO
	var worst_drift := 0.0
	var samples := 0
	for i in 500:
		await get_tree().process_frame
		var relative := car.get_global_transform_interpolated().affine_inverse() * player.get_global_transform_interpolated().origin
		if samples == 0:
			start = relative
		else:
			worst_drift = maxf(worst_drift, relative.distance_to(start))
		samples += 1
	note("climber drift against the rendered car: %.5f m at %.1f m/s" % [worst_drift, train.speed])
	check_eq(player.state, Player.State.CLIMB, "player is still on the ladder")
	check_less(worst_drift, 0.02, "the rendered climber stays glued to the rendered ladder")
