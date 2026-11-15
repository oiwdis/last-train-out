extends TestSuite

var game: Game
var player: Player
var crew: TrainCar
var locomotive: TrainCar


func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn", 8) as Game
	player = game.player
	player.input.scripted = true
	crew = game.train.get_node("CrewCar")
	locomotive = game.train.get_node("Locomotive")


func after_each() -> void:
	await free_spawned()


func test_walk_inside_crew_car_during_departure_and_braking() -> void:
	player.teleport_to(crew.to_global(Vector3(-2, 1.05, 0)))
	await seconds(0.4)
	check(player.is_on_train(), "interior floor supports player")
	game.train.start()
	await seconds(2)
	var start := crew.to_local(player.global_position)
	player.input.script_move(1)
	await seconds(1)
	player.input.clear()
	check_greater(crew.to_local(player.global_position).x, start.x + 2.5, "walk through actual interior while accelerating")
	game.train.stop()
	await seconds(2)
	check(player.is_on_train(), "braking retains interior passenger")
	check_near(crew.to_local(player.global_position).y, 1, 0.03, "floor remains stable")


func test_walk_between_all_three_cars_while_moving() -> void:
	var flat := game.train.get_node("FlatCar") as TrainCar
	player.teleport_to(flat.to_global(Vector3(2.8, 1.05, 0)))
	await seconds(0.4)
	game.train.start()
	await seconds(1)
	player.input.script_move(1)
	var fell := false
	for tick in 310:
		await physics_frames(1)
		if player.global_position.y < 0.8:
			fell = true
		if locomotive.to_local(player.global_position).x > -2.8:
			break
	player.input.clear()
	await seconds(0.3)
	check(not fell, "gangways bridge both couplings without a drop")
	check_eq(player.get_ride_body(), locomotive, "walked from flatcar through crew car into cab")
	check_greater(locomotive.to_local(player.global_position).x, -3.5, "player is inside cab")


func test_cab_controls_start_brake_and_select_all_departure_modes_by_looking() -> void:
	player.teleport_to(locomotive.to_global(Vector3(-2.7, 1.05, 0)))
	game.camera_rig.exploration.request_perspective(0)
	await seconds(0.8)
	for command in [2, 2, 2, 0, 1]:
		var control := locomotive.interior.controls[command]
		game.camera_rig.exploration.aim_at(control.global_position)
		await physics_frames(2)
		check_eq(player.interactor.find_interactable(), control, "look ray selects physical cab control")
		var mode := game.train.get_mode_index()
		player.input.script_interact()
		await physics_frames(3)
		if command == 2:
			check_eq(game.train.get_mode_index(), (mode + 1) % 3, "selector cycles departure modes")
		elif command == 0:
			check_eq(game.train.state, Train.State.ACCELERATING, "regulator starts departure")
			await seconds(1)
		else:
			check_eq(game.train.state, Train.State.BRAKING, "brake stops train")


func test_closed_door_blocks_walk_and_refuses_to_close_through_player() -> void:
	var door := crew.interior.doors[0]
	player.teleport_to(crew.to_global(Vector3(-2.6, 1.05, 0)))
	await seconds(0.3)
	game.camera_rig.exploration.request_perspective(0)
	await seconds(0.5)
	game.camera_rig.exploration.aim_at(door._panel.to_global(Vector3(door.width / 2, door.height / 2, 0)))
	check_eq(player.interactor.find_interactable(), door, "reticle targets the visible swung-open panel")
	player.input.script_interact()
	await seconds(0.4)
	player.input.script_move(-1)
	await seconds(0.7)
	player.input.clear()
	check_greater(crew.to_local(player.global_position).x, -3.2, "closed collider blocks doorway")
	game.camera_rig.exploration.aim_at(door._panel.to_global(Vector3(door.width / 2, door.height / 2, 0)))
	check_eq(player.interactor.find_interactable(), door, "reticle targets the closed panel")
	player.input.script_interact()
	await seconds(0.3)
	player.teleport_to(crew.to_global(Vector3(-3.4, 1.05, 0)))
	await seconds(0.3)
	check(not door.interact(player), "door refuses to close through occupied opening")
	check(door.is_open, "occupied doorway remains safe")


func test_interior_jump_switch_and_reset_keep_platform_motion() -> void:
	player.teleport_to(crew.to_global(Vector3(0, 1.05, 0)))
	await seconds(0.4)
	game.train.start()
	await seconds(12)
	player.input.script_jump()
	await physics_frames(5)
	game.camera_rig.exploration.request_perspective(0)
	check_greater(player.get_world_velocity().x, 4, "jump inherits moving car velocity")
	await seconds(1)
	await render_frame()
	check(player.is_on_train(), "jump lands back inside car")
	check_less(absf(crew.to_local(player.global_position).x), 0.15, "interior ceiling contact does not lose platform momentum")
	game.reset_train()
	await seconds(0.4)
	check(player.is_on_train(), "reset keeps rider in car")
	check_less(player.get_world_velocity().length(), 0.1, "reset leaves no stray velocity")
