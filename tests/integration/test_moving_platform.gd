extends TestSuite
## The milestone's critical mechanic: riding, boarding and leaving a moving train.

const SANDBOX := "res://scenes/main/movement_sandbox.tscn"
## Middle of the flat car's open deck, in the car's local space.
const DECK_SPOT := Vector3(0.0, 1.05, 0.35)

var game: Game
var player: Player
var train: Train
var flat_car: TrainCar


func before_each() -> void:
	game = await spawn_scene(SANDBOX) as Game
	player = game.player
	train = game.train
	flat_car = train.get_node("FlatCar") as TrainCar
	player.input.scripted = true
	player.input.clear()


func after_each() -> void:
	await free_spawned()


func _board_flat_car() -> void:
	player.teleport_to(flat_car.to_global(DECK_SPOT))
	await physics_frames(20)


func _relative() -> Vector3:
	return flat_car.to_local(player.global_position)


func test_player_stands_on_stationary_train() -> void:
	await _board_flat_car()
	check(player.is_grounded(), "player is grounded on the parked flat car")
	check(player.is_on_train(), "player reports standing on the train")
	check_near(player.global_position.y, 1.0, 0.03, "feet rest on the deck")
	check_near(player.get_horizontal_speed(), 0.0, 0.01, "player is at rest")


func test_player_rides_accelerating_train_without_sliding() -> void:
	await _board_flat_car()
	var start := _relative()
	train.set_mode_index(0)  # Emergency Steam: the harshest acceleration.
	train.start()
	var worst_drift := 0.0
	var worst_step := 0.0
	var previous := start
	var left_floor_ticks := 0
	await render_frame()
	start = _relative()
	previous = start
	for i in 480:  # 8 seconds: through the whole acceleration and into cruise.
		await render_frame()
		var now := _relative()
		worst_drift = maxf(worst_drift, Vector2(now.x - start.x, now.z - start.z).length())
		worst_step = maxf(worst_step, Vector2(now.x - previous.x, now.z - previous.z).length())
		previous = now
		if not player.is_grounded():
			left_floor_ticks += 1
	note("train speed %.2f m/s, max drift %.4f m, max per-tick jitter %.5f m" % [train.speed, worst_drift, worst_step])
	check_near(train.speed, train.max_speed, 0.01, "train reached full speed")
	check_less(worst_drift, 0.03, "player stays put relative to the car")
	check_less(worst_step, 0.005, "no per-tick jitter relative to the car")
	check_eq(left_floor_ticks, 0, "player never left the deck")
	check(player.is_on_train(), "player still on the train")
	check_near(player.get_world_velocity().x, train.speed, 0.05, "world velocity matches the train")
	check_near(player.global_position.y, 1.0, 0.03, "player did not sink into or float above the deck")


func test_player_walks_on_moving_train() -> void:
	await _board_flat_car()
	train.set_mode_index(0)
	train.start()
	await seconds(7.0)
	await render_frame()
	var start := _relative()
	player.input.script_move(1.0)
	await seconds(0.5)
	check_near(player.get_horizontal_speed(), player.config.walk_speed, 0.05, "walk speed is relative to the deck")
	check_near(player.get_world_velocity().x, train.speed + player.config.walk_speed, 0.1, "world speed is train + walk")
	player.input.script_move(0.0)
	await seconds(0.4)
	await render_frame()
	var moved := _relative().x - start.x
	note("walked %.2f m along the deck in 0.5 s of input" % moved)
	check_greater(moved, 1.1, "player advanced along the deck")
	check_less(moved, 1.9, "player advanced a sensible distance")
	check(player.is_on_train(), "player still on the train")


func test_jump_on_train_keeps_platform_momentum() -> void:
	await _board_flat_car()
	train.set_mode_index(0)
	train.start()
	await seconds(7.0)  # Cruising at constant speed.
	await render_frame()
	var start := _relative()
	player.input.script_jump()
	await physics_frames(3)
	check(not player.is_grounded(), "player is airborne after jumping")
	check_near(player.get_world_velocity().x, train.speed, 0.15, "jump inherited the train's velocity")
	var peak := 0.0
	for i in 90:
		await render_frame()
		peak = maxf(peak, _relative().y)
		if player.is_grounded():
			break
	await physics_frames(10)
	await render_frame()
	var landed := _relative()
	note("jump apex %.2f m above the deck, landed %.3f m from take-off spot" % [peak - start.y, absf(landed.x - start.x)])
	check(player.is_on_train(), "player landed back on the train")
	check_less(absf(landed.x - start.x), 0.1, "player landed where they took off")
	check_near(peak - start.y, player.config.jump_height, 0.12, "jump height is unaffected by the train")


func test_jump_off_train_preserves_momentum() -> void:
	await _board_flat_car()
	train.set_mode_index(0)
	train.start()
	await seconds(7.0)
	var train_speed := train.speed
	# Jump toward the camera, off the open side of the deck.
	player.input.script_move(0.0, 1.0)
	player.input.script_jump()
	await physics_frames(12)
	check(not player.is_on_train(), "player left the train")
	check_near(player.get_world_velocity().x, train_speed, 0.4, "horizontal momentum carried over")
	var x_before := player.global_position.x
	await physics_frames(6)
	check_greater(player.global_position.x - x_before, train_speed * 6.0 * tick_delta() * 0.85, "player keeps travelling with the train's speed")
	# Keep steering away from the train until touching down on the platform.
	for i in 120:
		await physics_frames(1)
		if player.is_grounded():
			break
	player.input.script_move(0.0)
	for i in 180:
		await physics_frames(1)
		if player.is_grounded() and player.get_horizontal_speed() < 0.1:
			break
	check(player.is_grounded(), "player landed on the ground")
	check(not player.is_on_train(), "player is on solid ground, not the train")
	check_near(player.get_world_velocity().x, 0.0, 0.2, "player comes to rest after landing")


func test_train_stops_smoothly_with_rider() -> void:
	await _board_flat_car()
	var start := _relative()
	train.set_mode_index(0)
	train.start()
	await seconds(7.0)
	await render_frame()
	start = _relative()
	train.stop()
	var worst_drift := 0.0
	for i in 480:
		await render_frame()
		var now := _relative()
		worst_drift = maxf(worst_drift, Vector2(now.x - start.x, now.z - start.z).length())
		if train.state == Train.State.STOPPED:
			break
	await physics_frames(10)
	note("max drift while braking %.4f m" % worst_drift)
	check_eq(train.state, Train.State.STOPPED, "train came to a stop")
	check_near(train.speed, 0.0, 0.001, "train speed is zero")
	check_less(worst_drift, 0.03, "rider did not slide while braking")
	check(player.is_on_train(), "rider still aboard")


func test_reset_with_player_aboard() -> void:
	await _board_flat_car()
	train.set_mode_index(0)
	train.start()
	await seconds(7.0)
	await render_frame()
	var before := _relative()
	check_greater(train.distance, 30.0, "train travelled away from the station")
	game.reset_train()
	await physics_frames(30)
	await render_frame()
	var after := _relative()
	check_near(train.distance, 0.0, 0.001, "train distance reset")
	check_near(train.speed, 0.0, 0.001, "train speed reset")
	check_near(flat_car.global_position.x, train.get_rest_transform(flat_car).origin.x, 0.001, "car is back at the platform")
	check(player.is_grounded(), "player is grounded after the reset")
	check(player.is_on_train(), "player is still aboard after the reset")
	check_less(Vector2(after.x - before.x, after.z - before.z).length(), 0.05, "player kept their place on the car")
	check_near(player.global_position.y, 1.0, 0.03, "player rests on the deck")
	check_less(player.get_world_velocity().length(), 0.05, "player has no stray velocity")
	# The train must be usable again straight away.
	train.start()
	await seconds(2.0)
	check_greater(train.speed, 0.5, "train departs again after a reset")
	check(player.is_on_train(), "player rides the train after the reset")


func test_reset_does_not_disturb_player_on_platform() -> void:
	train.set_mode_index(0)
	train.start()
	await seconds(6.0)
	var before := player.global_position
	game.reset_train()
	await physics_frames(20)
	check_less(player.global_position.distance_to(before), 0.02, "player on the platform is unaffected")
	check(player.is_grounded(), "player still grounded")
	check_near(flat_car.global_position.x, train.get_rest_transform(flat_car).origin.x, 0.001, "car is back at the platform")
