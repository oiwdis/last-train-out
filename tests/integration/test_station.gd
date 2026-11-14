extends TestSuite
## Harlow Junction as a whole: the main scene, traversal of every zone,
## camera behaviour, building cutaways, the debug menu and the system stubs.

const MAIN := "res://scenes/main/main.tscn"

var game: Game
var player: Player
var train: Train
var camera: CameraRig
var station: Station
var warehouse_a: Node3D
var warehouse_b: Node3D


func before_each() -> void:
	game = await spawn_scene(MAIN, 6) as Game
	player = game.player
	train = game.train
	camera = game.camera_rig
	station = game.station
	warehouse_a = station.get_node("WarehouseA")
	warehouse_b = station.get_node("WarehouseB")
	player.input.scripted = true
	player.input.clear()


func after_each() -> void:
	await free_spawned()


func _v(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(x, y, z)


## Route from the platform through both warehouses to the freight yard.
func _route_platform_to_freight_yard() -> Array:
	return [
		{"to": _v(29.4, 1.0)},
		{"to": _v(33.6, 1.0)},                      # Down the platform steps.
		{"to": _v(35.8, 1.1)},                      # Warehouse A, left door.
		{"to": _v(46.6, 1.1)},                      # Middle lane.
		{"to": _v(47.3, 3.3)},                      # Around the blocking stack via the front lane.
		{"to": _v(49.7, 3.0)},
		{"to": _v(50.6, 1.2)},                      # Back to the middle lane.
		{"to": _v(53.0, 1.1), "then": "interact"},  # Vault the low crate.
		{"to": _v(58.6, 1.1)},
		{"to": _v(60.6, 1.1)},                      # Out of Warehouse A.
		{"to": _v(63.5, 1.5), "then": "interact"},  # Vault the pallet stack in the yard.
		{"to": _v(69.4, 1.1)},
		{"to": _v(70.9, 1.1)},                      # Warehouse B, left door.
		{"to": _v(71.3, 2.6)},                      # Around the entry crate.
		{"to": _v(74.3, 3.3)},                      # Past rack M1 (front gap).
		{"to": _v(76.1, 0.75)},
		{"to": _v(78.6, 0.75)},                     # Past rack M2 (back gap).
		{"to": _v(78.9, 2.2)},
		{"to": _v(81.6, 2.2)},                      # Past rack M3.
		{"to": _v(83.0, 1.6)},
		{"to": _v(83.0, -0.1)},                     # Into the back room (door 1).
		{"to": _v(86.5, 0.2)},
		{"to": _v(87.4, -0.75)},                    # Behind the corridor crate.
		{"to": _v(88.3, 0.1)},
		{"to": _v(91.7, 0.1)},
		{"to": _v(91.7, 1.5)},                      # Out of the back room (door 2): past the blockage.
		{"to": _v(94.8, 0.7)},                      # Behind rack F1.
		{"to": _v(96.4, 1.7)},
		{"to": _v(100.8, 1.7)},                     # Out into the freight yard.
	]


func _route_far_point_to_train() -> Array:
	return [
		{"to": _v(94.9, 0.6)},
		{"to": _v(93.4, 1.5)},
		{"to": _v(91.7, 1.5)},
		{"to": _v(91.7, 0.0)},                      # Into the back room (door 2).
		{"to": _v(88.3, 0.1)},
		{"to": _v(87.4, -0.75)},
		{"to": _v(86.5, 0.2)},
		{"to": _v(83.0, -0.1)},
		{"to": _v(83.0, 1.6)},                      # Out through door 1.
		{"to": _v(81.6, 2.2)},
		{"to": _v(78.9, 2.2)},
		{"to": _v(78.6, 0.75)},
		{"to": _v(76.1, 0.75)},
		{"to": _v(74.3, 3.3)},
		{"to": _v(71.3, 2.6)},
		{"to": _v(70.6, 1.1)},
		{"to": _v(69.4, 1.1)},                      # Yard B.
		{"to": _v(65.7, 1.5), "then": "interact"},  # Vault the pallet stack.
		{"to": _v(60.6, 1.1)},
		{"to": _v(58.6, 1.1)},                      # Warehouse A.
		{"to": _v(54.8, 1.1), "then": "interact"},  # Vault the low crate.
		{"to": _v(50.6, 1.2)},
		{"to": _v(49.7, 3.0)},
		{"to": _v(47.3, 3.3)},
		{"to": _v(46.6, 1.1)},
		{"to": _v(35.8, 1.1)},
		{"to": _v(33.9, 1.0)},                      # Yard A.
		{"to": _v(29.6, 1.0)},                      # Up the platform steps.
		{"to": _v(20.6, -1.5), "then": "interact"}, # Locomotive cab ladder.
	]


# --- Scene sanity ---------------------------------------------------------------

func test_main_scene_starts_at_harlow_junction() -> void:
	check(game != null, "main scene instantiates")
	check_eq(station.station_name, "Harlow Junction", "the station is Harlow Junction")
	await physics_frames(30)
	check(player.is_grounded(), "player starts standing")
	check_near(player.global_position.y, 1.0, 0.05, "player starts on the platform")
	check(not player.is_on_train(), "player starts on the platform, not the train")
	check_eq(train.state, Train.State.STOPPED, "train starts parked")
	check_eq(train.get_cars().size(), 3, "train is a locomotive plus two cars")
	check(train.get_cars()[2].name == "Locomotive", "the locomotive leads")
	check_near(train.global_position.x, station.train_stop.global_position.x, 0.01, "train sits at the station stop")
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), MAIN, "project launches straight into the station")


func test_station_dimensions() -> void:
	var far_point := warehouse_b.get_node("FarPoint") as Marker3D
	check_near(warehouse_a.global_position.x, 35.0, 0.01, "Warehouse A starts at 35 m")
	check_near(warehouse_b.global_position.x, 70.0, 0.01, "Warehouse B starts at 70 m")
	check_greater(far_point.global_position.x, 95.0, "the far point is deep inside Warehouse B")
	var freight_b := station.get_node("FreightCarB") as Node3D
	check_greater(freight_b.global_position.x, 100.0, "freight yard lies beyond 100 m")
	check_less(freight_b.global_position.x, 120.0, "freight yard ends by 120 m")


# --- Traversal ---------------------------------------------------------------------

func test_traverse_station_end_to_end() -> void:
	var bot := RouteBot.new(player)
	var ok := await bot.run(_route_platform_to_freight_yard())
	check(ok, "walked from the platform to the freight yard: %s" % bot.failure)
	note("platform -> freight yard in %.1f s" % bot.get_seconds())
	check_greater(player.global_position.x, 100.0, "player reached the freight yard")
	check(player.is_grounded(), "player is standing in the freight yard")


func test_warehouse_a_stairs_and_upper_floor() -> void:
	player.teleport_to(_v(36.2, 1.1, 0.05))
	await physics_frames(10)
	var bot := RouteBot.new(player)
	var ok := await bot.run([
		{"to": _v(40.4, -0.4)},                     # Foot of the stairs.
		{"to": _v(47.8, -0.4), "timeout": 8.0},     # Up the flight.
	])
	check(ok, "climbed the stairs: %s" % bot.failure)
	check_near(player.global_position.y, 3.6, 0.06, "player stands on the upper floor")
	check(player.is_grounded(), "player is grounded upstairs")
	ok = await bot.run([
		{"to": _v(48.6, 1.75)},
		{"to": _v(57.4, 1.75)},
		{"to": _v(58.6, 1.1)},
		{"to": _v(61.2, 1.1)},                      # Through the upper door onto the balcony.
	])
	check(ok, "crossed the upper floor to the balcony: %s" % bot.failure)
	check_near(player.global_position.y, 3.6, 0.06, "balcony is at upper-floor height")
	# Climb down the balcony ladder into the yard.
	ok = await bot.run([{"to": _v(61.9, 1.1), "then": "interact"}])
	check(ok, "grabbed the balcony ladder from the top: %s" % bot.failure)
	check_eq(player.state, Player.State.CLIMB, "player is on the ladder")
	player.input.script_move(0.0, 1.0)
	for i in 400:
		await physics_frames(1)
		if player.is_grounded():
			break
	player.input.script_move(0.0)
	check(player.is_grounded(), "player reached the yard")
	check_near(player.global_position.y, 0.0, 0.05, "player is at ground level")
	check_greater(player.global_position.x, 62.5, "player came down outside the balcony")
	# And back down the stairs works too.
	player.teleport_to(_v(48.0, -0.4, 3.65))
	await physics_frames(10)
	ok = await bot.run([{"to": _v(40.0, -0.4), "timeout": 8.0}])
	check(ok, "walked back down the stairs: %s" % bot.failure)
	check_near(player.global_position.y, 0.0, 0.06, "player is back on the ground floor")


func test_warehouse_b_doorway_is_blocked_but_back_room_gets_around() -> void:
	# Walking straight at the partition doorway gets nowhere.
	player.teleport_to(_v(84.5, 2.4, 0.05))
	await physics_frames(10)
	player.input.script_move(1.0, 0.0, true)
	await seconds(3.0)
	player.input.script_move(0.0)
	check_less(player.global_position.x, 87.4, "the direct doorway is blocked")
	# The blockage cannot be vaulted either.
	player.input.script_move(1.0)
	player.input.script_interact()
	await seconds(1.5)
	player.input.script_move(0.0)
	await seconds(0.5)
	check_less(player.global_position.x, 87.4, "the blockage cannot be climbed through")
	# The back room leads around it.
	var bot := RouteBot.new(player)
	var ok := await bot.run([
		{"to": _v(83.0, 1.6)},
		{"to": _v(83.0, -0.1)},
		{"to": _v(86.5, 0.2)},
		{"to": _v(87.4, -0.75)},
		{"to": _v(88.3, 0.1)},
		{"to": _v(91.7, 0.1)},
		{"to": _v(91.7, 1.6)},
	])
	check(ok, "reached the far section through the back room: %s" % bot.failure)
	check_greater(player.global_position.x, 87.8, "player is past the partition")
	check_greater(player.global_position.z, 1.0, "player is back in the main depth lane")


func test_freight_yard_ladders_roofs_and_gap() -> void:
	player.teleport_to(_v(100.8, 1.7, 0.05))
	await physics_frames(10)
	var bot := RouteBot.new(player)
	var ok := await bot.run([{"to": _v(101.55, 2.0), "then": "interact"}])
	check(ok, "grabbed the freight car ladder: %s" % bot.failure)
	check_eq(player.state, Player.State.CLIMB, "player is climbing")
	ok = await bot.run([{"to": player.global_position, "then": "climb_up"}])
	check(ok, "climbed to the roof: %s" % bot.failure)
	check_near(player.global_position.y, 3.8, 0.06, "player stands on the first car's roof")
	# Run along the roof and jump the gap to the second car.
	ok = await bot.run([
		{"to": _v(104.0, 0.2)},
		{"to": _v(107.6, 0.2), "then": "jump"},
		{"to": _v(111.6, 0.2), "timeout": 4.0},
	])
	check(ok, "ran along the roof and jumped the gap: %s" % bot.failure)
	await physics_frames(20)
	check_near(player.global_position.y, 3.8, 0.06, "player landed on the second car's roof")
	check_greater(player.global_position.x, 110.4, "player is on the second car")
	# A second, shorter gap leads onto the loading gantry at the end of the siding.
	ok = await bot.run([
		{"to": _v(116.9, 0.3), "then": "jump"},
		{"to": _v(119.2, 0.3), "timeout": 4.0, "sprint": false},
	])
	check(ok, "jumped from the car roof onto the gantry: %s" % bot.failure)
	await physics_frames(20)
	check_near(player.global_position.y, 3.8, 0.06, "player stands on the gantry")
	check_greater(player.global_position.x, 118.4, "player is on the gantry deck")
	# Down the gantry ladder.
	ok = await bot.run([{"to": _v(119.25, 0.9), "then": "interact"}])
	check(ok, "grabbed the gantry ladder from the top: %s" % bot.failure)
	ok = await bot.run([{"to": player.global_position, "then": "climb_down"}])
	check(ok, "climbed down: %s" % bot.failure)
	check_near(player.global_position.y, 0.0, 0.06, "player is back on the ground")


func test_every_freight_ladder_reaches_the_roof() -> void:
	# (ladder x, the z to stand at in front of it)
	for spot: Vector2 in [Vector2(101.55, 2.0), Vector2(107.45, 2.0), Vector2(110.95, 2.0), Vector2(116.85, 2.0), Vector2(119.25, 1.9)]:
		player.teleport_to(_v(spot.x, spot.y, 0.05), Vector3.FORWARD)
		await physics_frames(10)
		var bot := RouteBot.new(player)
		var ok := await bot.run([{"to": _v(spot.x, spot.y), "radius": 0.5, "then": "interact"}])
		check(ok and player.state == Player.State.CLIMB, "ladder at x=%.1f can be grabbed: %s" % [spot.x, bot.failure])
		ok = await bot.run([{"to": player.global_position, "then": "climb_up"}])
		check(ok, "ladder at x=%.1f leads to the top: %s" % [spot.x, bot.failure])
		check_near(player.global_position.y, 3.8, 0.06, "player stands on top at x=%.1f" % spot.x)


func test_warehouse_b_takes_longer_to_cross_than_warehouse_a() -> void:
	var route := _route_platform_to_freight_yard()
	# Split the end-to-end route at the buildings' doors.
	var through_a := route.slice(2, 10)
	var through_b := route.slice(12)
	player.teleport_to(_v(35.0, 1.1, 0.05))
	await physics_frames(10)
	var bot := RouteBot.new(player)
	var ok := await bot.run(through_a)
	var seconds_a := bot.get_seconds()
	check(ok, "crossed Warehouse A: %s" % bot.failure)
	game.reset_stamina()
	player.teleport_to(_v(70.2, 1.1, 0.05))
	await physics_frames(10)
	ok = await bot.run(through_b)
	var seconds_b := bot.get_seconds()
	check(ok, "crossed Warehouse B: %s" % bot.failure)
	note("Warehouse A door to door: %.1f s, Warehouse B door to door: %.1f s" % [seconds_a, seconds_b])
	check_greater(seconds_b, seconds_a + 0.8, "Warehouse B takes noticeably longer to get through")


func test_return_run_from_warehouse_b_to_train() -> void:
	var far_point := warehouse_b.get_node("FarPoint") as Marker3D
	player.teleport_to(far_point.global_position)
	await physics_frames(20)
	var bot := RouteBot.new(player)
	var ok := await bot.run(_route_far_point_to_train())
	check(ok, "ran from the far end of Warehouse B to the train: %s" % bot.failure)
	check(player.is_on_train(), "player is holding on to the train")
	var seconds_taken := bot.get_seconds()
	note("return run: %.1f s (design target: about 20 s)" % seconds_taken)
	check_greater(seconds_taken, 15.0, "the run is not trivially short")
	check_less(seconds_taken, 25.0, "the run takes roughly 20 seconds")
