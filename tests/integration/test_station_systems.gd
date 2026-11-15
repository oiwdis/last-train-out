extends TestSuite
## Camera, building cutaways, debug menu, world-system stubs and whole-station
## train rides, all on the real main scene.

const MAIN := "res://scenes/main/main.tscn"

var game: Game
var player: Player
var train: Train
var camera: CameraRig
var station: Station
var wall_a_front: CutawayWall
var wall_a_back: CutawayWall
var wall_b_front: CutawayWall
var wall_b_back: CutawayWall
var wall_back_room: CutawayWall


func before_each() -> void:
	game = await spawn_scene(MAIN, 6) as Game
	player = game.player
	train = game.train
	camera = game.camera_rig
	station = game.station
	wall_a_front = station.get_node("WarehouseA/FrontWall") as CutawayWall
	wall_a_back = station.get_node("WarehouseA/BackWall") as CutawayWall
	wall_b_front = station.get_node("WarehouseB/FrontWall") as CutawayWall
	wall_b_back = station.get_node("WarehouseB/BackWall") as CutawayWall
	wall_back_room = station.get_node("WarehouseB/BackRoomFront") as CutawayWall
	player.input.scripted = true
	player.input.clear()


func after_each() -> void:
	await free_spawned()


func _press_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().process_frame


func _button(button_name: String) -> Button:
	return game.debug_menu.get_node("%" + button_name) as Button


# --- Building cutaways -----------------------------------------------------------

func test_legacy_cutaway_component_opens_and_closes_per_building() -> void:
	# Retained component regression; immersive gameplay keeps these disabled.
	for trigger in game.find_children("*", "CutawayTrigger", true, false):
		trigger.immersive = false
	await seconds(0.5)
	check(not wall_a_front.is_cut_away() and not wall_b_front.is_cut_away(), "walls are intact while the player is outside")
	check_near(wall_a_front.get_fade(), 0.0, 0.001, "Warehouse A front wall is fully visible")
	# Enter Warehouse A.
	player.teleport_to(Vector3(44.0, 0.05, 1.1))
	await seconds(1.0)
	check(wall_a_front.is_cut_away(), "Warehouse A front wall is cut away while the player is inside")
	check_near(wall_a_front.get_fade(), 1.0, 0.001, "the cutaway transition completed")
	check(not wall_a_back.is_cut_away(), "the back wall stays while the player is inside")
	check(not wall_b_front.is_cut_away(), "Warehouse B is unaffected")
	# Walk out through the door: the wall comes back.
	player.teleport_to(Vector3(63.0, 0.05, 0.4))
	await seconds(1.0)
	check(not wall_a_front.is_cut_away(), "the wall returns when the player leaves")
	check_near(wall_a_front.get_fade(), 0.0, 0.001, "the wall is fully visible again")
	# Warehouse B works independently.
	player.teleport_to(Vector3(76.0, 0.05, 0.75))
	await seconds(1.0)
	check(wall_b_front.is_cut_away(), "Warehouse B front wall is cut away while the player is inside")
	check(not wall_a_front.is_cut_away(), "Warehouse A stays closed")
	check(not wall_back_room.is_cut_away(), "the back room wall is intact from the main hall")
	# The back room has its own cutaway.
	player.teleport_to(Vector3(88.3, 0.05, 0.1))
	await seconds(1.0)
	check(wall_back_room.is_cut_away(), "the back room's wall is cut away while the player is in it")
	check(wall_b_front.is_cut_away(), "the building's front wall stays cut away as well")


func test_legacy_cutaway_fades_without_changing_collision() -> void:
	wall_a_front.request_cut(self)
	player.teleport_to(Vector3(44.0, 0.05, 1.1))
	var saw_partial := false
	for i in 40:
		await get_tree().process_frame
		var fade := wall_a_front.get_fade()
		if fade > 0.05 and fade < 0.95:
			saw_partial = true
	check(saw_partial, "the wall passes through intermediate transparency")
	# Collision is untouched by the cutaway: the player cannot walk out through it.
	await seconds(0.5)
	player.input.script_move(0.0, 1.0, true)
	await seconds(2.5)
	player.input.script_move(0.0)
	check_less(player.global_position.z, 4.4, "the cut-away wall still blocks movement")


func test_buildings_stay_opaque_when_player_passes_behind_them() -> void:
	# Standing in the track lane behind Warehouse A (where the train runs).
	player.teleport_to(Vector3(47.0, 0.05, -3.0))
	await seconds(1.0)
	check(not wall_a_front.is_cut_away(), "front wall stays opaque behind the building")
	check(not wall_a_back.is_cut_away(), "back wall stays opaque in immersive views")
	check(not wall_b_front.is_cut_away(), "the other warehouse is unaffected")
	player.teleport_to(Vector3(65.0, 0.05, -3.0))
	await seconds(1.0)
	check(not wall_a_front.is_cut_away() and not wall_a_back.is_cut_away(), "walls return once the player has passed")


# --- Camera -------------------------------------------------------------------------

func test_camera_keeps_selected_distance_between_location_profiles() -> void:
	for point in [Vector3(130, 0.05, 8), Vector3(44, 0.05, 1.1), Vector3(65, 0.05, 0.4), Vector3(78, 0.05, 0.75)]:
		player.teleport_to(point, Vector3.RIGHT)
		await seconds(0.8)
		check_near(camera.exploration._boom, camera.exploration.settings.third_person_distance, 0.05, "location does not override player-selected view distance")
		check_less(camera.get_framing().distance, camera.exploration._boom + 0.1, "collision may only shorten the boom")


func test_camera_moves_smoothly_through_a_doorway() -> void:
	camera.exploration.request_perspective(0)
	# Sprint from the yard into Warehouse A and out the other side, watching the
	# camera every tick: it must never jump.
	player.teleport_to(Vector3(31.0, 0.05, 1.1))
	await seconds(1.5)
	var eye := camera.get_camera()
	var previous := eye.global_position
	var previous_fov := eye.fov
	var worst_step := 0.0
	var worst_fov_step := 0.0
	var bot := RouteBot.new(player)
	var route := [
		{"to": Vector3(35.8, 0, 1.1)}, {"to": Vector3(46.6, 0, 1.1)}, {"to": Vector3(47.3, 0, 3.3)},
		{"to": Vector3(49.7, 0, 3.0)}, {"to": Vector3(50.6, 0, 1.2)},
	]
	var running := [true]
	var runner := func() -> void:
		await bot.run(route)
		running[0] = false
	runner.call()
	while running[0]:
		await get_tree().physics_frame
		worst_step = maxf(worst_step, eye.global_position.distance_to(previous))
		worst_fov_step = maxf(worst_fov_step, absf(eye.fov - previous_fov))
		previous = eye.global_position
		previous_fov = eye.fov
	note("largest camera move in one tick: %.3f m" % worst_step)
	check(bot.failure == "", "route completed: %s" % bot.failure)
	check_less(worst_step, 0.3, "the camera never snaps (sprinting is 0.1 m per tick)")
	check_less(worst_fov_step, 0.5, "the field of view never jumps")


func test_camera_keeps_player_in_frame_and_follows_body() -> void:
	player.teleport_to(Vector3(8.0, 1.05, 0.5))
	await seconds(1.0)
	player.input.script_move(1.0, 0.0, true)
	await seconds(2.0)
	var focus: Vector3 = camera.get_framing()["focus"]
	player.input.script_move(0.0)
	check_near(focus.x, player.global_position.x, 0.25, "camera follows player without side-scrolling look-ahead")
	check_less(focus.x, player.global_position.x + 4.0, "but keeps the player well inside the frame")
	var on_screen := camera.get_camera().unproject_position(player.global_position + Vector3.UP)
	var viewport := camera.get_viewport().get_visible_rect().size
	check(on_screen.x > viewport.x * 0.15 and on_screen.x < viewport.x * 0.85, "player is horizontally within the middle of the screen")
	check(on_screen.y > viewport.y * 0.15 and on_screen.y < viewport.y * 0.85, "player is vertically within the middle of the screen")


func test_camera_keeps_selected_view_and_stays_with_the_player_during_departure() -> void:
	await seconds(1.5)
	var resting: float = camera.get_framing()["distance"]
	train.set_mode_index(1)
	train.start()
	await seconds(3.0)
	var widened: float = camera.get_framing()["distance"]
	check_near(widened, resting, 0.1, "departure does not force a view change")
	# Let the train run away: the camera must stay with the player on the platform.
	for i in 900:
		await physics_frames(1)
		if train.distance > 150.0:
			break
	var focus: Vector3 = camera.get_framing()["focus"]
	check_less(absf(focus.x - player.global_position.x), 1.5, "the camera did not chase the train away from the player")
	var on_screen := camera.get_camera().unproject_position(player.global_position + Vector3.UP)
	var viewport := camera.get_viewport().get_visible_rect().size
	check(on_screen.x > viewport.x * 0.2 and on_screen.x < viewport.x * 0.8, "player is still framed")
	game.reset_train()
	await seconds(4.0)
	check_near(camera.get_framing()["distance"], resting, 0.5, "framing returns to normal after the train is reset")


# --- Debug menu ---------------------------------------------------------------------

func test_debug_menu_toggles_with_f1_and_closes_with_escape() -> void:
	var menu := game.debug_menu
	check(not menu.is_open(), "the menu starts closed")
	await _press_action(&"debug_toggle")
	check(menu.is_open(), "F1 opens the menu")
	await _press_action(&"debug_toggle")
	check(not menu.is_open(), "F1 closes it again")
	await _press_action(&"debug_toggle")
	await _press_action(&"debug_close")
	check(not menu.is_open(), "Esc closes the menu")
	await _press_action(&"debug_close")
	check(not menu.is_open(), "Esc does not open it")


func test_debug_menu_train_controls() -> void:
	var menu := game.debug_menu
	menu.set_open(true)
	_button("StartButton").pressed.emit()
	await seconds(1.0)
	check_eq(train.state, Train.State.ACCELERATING, "Start gets the train moving")
	check_greater(train.speed, 0.05, "the train has speed")
	_button("StopButton").pressed.emit()
	check_eq(train.state, Train.State.BRAKING, "Stop brakes the train")
	await seconds(2.0)
	check_eq(train.state, Train.State.STOPPED, "the train comes to a halt")
	check_greater(train.distance, 0.01, "the train moved away from the stop")
	_button("ResetTrainButton").pressed.emit()
	await seconds(0.2)
	check_near(train.distance, 0.0, 0.001, "Reset returns the train to the platform")
	# Departure mode buttons are generated from the train's modes.
	var mode_row := menu.get_node("%ModeRow")
	check_eq(mode_row.get_child_count(), 3, "there is a button for each departure mode")
	for index in 3:
		(mode_row.get_child(index) as Button).pressed.emit()
		check_eq(train.get_mode_index(), index, "mode button %d selects that departure mode" % index)
	# Maximum speed slider.
	var slider := menu.get_node("%SpeedSlider") as HSlider
	slider.value = 20.0
	check_near(train.max_speed, 20.0, 0.001, "the slider sets the train's maximum speed")
	check_eq((menu.get_node("%SpeedValue") as Label).text, "20.0 m/s", "the slider shows its value")
	slider.value = 12.0


func test_debug_menu_player_and_station_controls() -> void:
	var menu := game.debug_menu
	menu.set_open(true)
	var spawn := game.get_spawn_position()
	player.input.script_move(1.0, 0.0, true)
	await seconds(3.0)
	player.input.script_move(0.0)
	check_greater(player.global_position.distance_to(spawn), 5.0, "player ran away from the spawn point")
	check_less(player.stamina.current, player.stamina.max_stamina - 10.0, "sprinting used stamina")
	_button("ResetStaminaButton").pressed.emit()
	check_near(player.stamina.current, player.stamina.max_stamina, 0.001, "Reset stamina refills the bar")
	_button("ResetPlayerButton").pressed.emit()
	await seconds(0.5)
	check_less(player.global_position.distance_to(spawn), 0.1, "Reset position returns the player to the spawn point")
	# Reset entire station.
	train.start()
	player.input.script_move(1.0, 0.0, true)
	await seconds(3.0)
	player.input.script_move(0.0)
	_button("ResetStationButton").pressed.emit()
	await seconds(0.5)
	check_less(player.global_position.distance_to(spawn), 0.1, "station reset moves the player back")
	check_near(train.distance, 0.0, 0.001, "station reset parks the train")
	check_eq(train.state, Train.State.STOPPED, "station reset stops the train")
	check_near(player.stamina.current, player.stamina.max_stamina, 0.001, "station reset refills stamina")
	# Fog surge warning.
	var surges := [0]
	game.fog_system.surge_triggered.connect(func(_intensity: float) -> void: surges[0] += 1)
	_button("FogButton").pressed.emit()
	check_eq(surges[0], 1, "the fog surge button reaches the FogSystem")
	check_eq(game.fog_system.surge_count, 1, "the FogSystem recorded the surge")
	check(game.hud.get_message().contains("warning"), "the HUD announces the surge warning")


func test_debug_menu_diagnostics_are_live() -> void:
	var menu := game.debug_menu
	menu.set_open(true)
	await seconds(0.4)
	check(menu.get_diagnostic("FPS").is_valid_int(), "FPS is shown")
	check_eq(menu.get_diagnostic("Movement state"), "IDLE", "movement state is shown")
	check_eq(menu.get_diagnostic("Grounded"), "yes", "grounded flag is shown")
	check_eq(menu.get_diagnostic("On train"), "no", "on-train flag is shown")
	check_eq(menu.get_diagnostic("Departure mode"), "Normal", "departure mode is shown")
	check(menu.get_diagnostic("Train speed").begins_with("0.00 m/s"), "train speed is shown")
	check(menu.get_diagnostic("Stamina").begins_with("100 / 100"), "stamina is shown")
	player.input.script_move(1.0, 0.0, true)
	await seconds(0.8)
	check_eq(menu.get_diagnostic("Movement state"), "SPRINT", "movement state updates")
	check(menu.get_diagnostic("Player speed").begins_with("6.00 m/s"), "player speed updates")
	player.input.script_move(0.0)
	# Standing on the train is reported.
	var flat_car := train.get_node("FlatCar") as TrainCar
	player.teleport_to(flat_car.to_global(Vector3(0.0, 1.05, 0.35)))
	train.set_mode_index(0)
	train.start()
	await seconds(1.5)
	check_eq(menu.get_diagnostic("On train"), "yes", "on-train flag updates")
	check_eq(menu.get_diagnostic("Departure mode"), "Emergency Steam", "departure mode updates")
	check(not menu.get_diagnostic("Train speed").begins_with("0.00"), "train speed updates")
	check_eq(menu.get_diagnostic("Train state"), "ACCELERATING", "train state updates")


func test_debug_menu_does_not_steal_player_input() -> void:
	var menu := game.debug_menu
	menu.set_open(true)
	await seconds(0.2)
	# No control in the menu can take keyboard focus (Space/E must never click a button).
	var focusable: Array[String] = []
	var pending: Array[Node] = [menu]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Control and (node as Control).focus_mode != Control.FOCUS_NONE:
			focusable.append(str(node.name))
		pending.append_array(node.get_children())
	check(focusable.is_empty(), "no debug control accepts keyboard focus: %s" % str(focusable))
	_button("ResetStaminaButton").pressed.emit()
	check(menu.get_viewport().gui_get_focus_owner() == null, "nothing holds keyboard focus after using the menu")
	# The player still moves and jumps while the menu is open.
	var x_start := player.global_position.x
	player.input.script_move(1.0)
	await seconds(1.0)
	check_greater(player.global_position.x, x_start + 2.0, "the player walks while the menu is open")
	player.input.script_move(0.0)
	player.input.script_jump()
	await physics_frames(6)
	check(not player.is_grounded(), "the player jumps while the menu is open")


# --- World-system stubs -----------------------------------------------------------

func test_system_stubs_are_wired() -> void:
	check(game.fog_system != null and game.passenger_system != null and game.inventory_system != null, "all three stubs exist in the main scene")
	var fog_states: Array = []
	game.fog_system.fog_state_changed.connect(func(state: FogSystem.FogState) -> void: fog_states.append(state))
	game.fog_system.set_state(FogSystem.FogState.APPROACHING)
	check_eq(fog_states, [FogSystem.FogState.APPROACHING], "FogSystem announces state changes")
	var passenger_events: Array = []
	game.passenger_system.passenger_state_changed.connect(
		func(id: StringName, state: PassengerSystem.PassengerState) -> void: passenger_events.append([id, state]))
	game.passenger_system.register_passenger(&"test_passenger")
	game.passenger_system.set_passenger_state(&"test_passenger", PassengerSystem.PassengerState.ABOARD)
	check_eq(passenger_events, [[&"test_passenger", PassengerSystem.PassengerState.ABOARD]], "PassengerSystem announces state changes")
	var inventory_events: Array = []
	game.inventory_system.inventory_changed.connect(func(item: StringName, amount: int) -> void: inventory_events.append([item, amount]))
	game.inventory_system.add_item(&"coal", 3)
	check_eq(game.inventory_system.remove_item(&"coal", 5), 3, "InventorySystem never removes more than it holds")
	check_eq(inventory_events, [[&"coal", 3], [&"coal", 0]], "InventorySystem announces changes")
	game.reset_station()
	check_eq(game.fog_system.state, FogSystem.FogState.DISTANT, "station reset returns the fog to distant")
	check_eq(game.passenger_system.get_passenger_count(), 0, "station reset clears passengers")
	check_eq(game.inventory_system.get_amount(&"coal"), 0, "station reset clears the inventory")


# --- Whole-station train rides ---------------------------------------------------

func test_ride_on_roof_through_entire_station() -> void:
	var crew_car := train.get_node("CrewCar") as TrainCar
	player.teleport_to(crew_car.to_global(Vector3(0.5, 3.7, 0.2)))
	await seconds(0.5)
	await render_frame()
	var start := crew_car.to_local(player.global_position)
	train.set_mode_index(0)
	train.start()
	var worst_drift := 0.0
	var fell_off := false
	var opened_a := false
	var opened_b := false
	for i in 1500:
		await render_frame()
		var now := crew_car.to_local(player.global_position)
		worst_drift = maxf(worst_drift, now.distance_to(start))
		if not player.is_on_train():
			fell_off = true
			break
		opened_a = opened_a or (wall_a_front.is_cut_away() and wall_a_back.is_cut_away())
		opened_b = opened_b or (wall_b_front.is_cut_away() and wall_b_back.is_cut_away())
		if train.distance > 170.0:
			break
	note("rode %.0f m at up to %.1f m/s, max drift %.4f m" % [train.distance, train.speed, worst_drift])
	check(not fell_off, "the rider is never knocked off while passing the station")
	check_greater(train.distance, 170.0, "the train carried the rider out of the station")
	check_less(worst_drift, 0.03, "no sliding on the roof")
	check(not opened_a, "Warehouse A stays opaque while rider passes behind")
	check(not opened_b, "Warehouse B stays opaque while rider passes behind")
	await seconds(1.0)
	check(not wall_b_front.is_cut_away(), "the last building closed again behind the train")


func test_cling_to_ladder_through_entire_station() -> void:
	var ladder := train.get_node("Locomotive/CabLadder") as Ladder
	player.teleport_to(Vector3(ladder.global_position.x, 1.05, -1.6), Vector3.FORWARD)
	await physics_frames(10)
	player.input.script_interact()
	await seconds(0.6)
	check_eq(player.state, Player.State.CLIMB, "player holds the locomotive's ladder")
	train.set_mode_index(0)
	train.start()
	var knocked_off := false
	for i in 1500:
		await physics_frames(1)
		if player.state != Player.State.CLIMB:
			knocked_off = true
			break
		if train.distance > 170.0:
			break
	check(not knocked_off, "nothing along the line scrapes a climber off the train")
	check_greater(train.distance, 170.0, "the train left the station with the climber")
	check_near(player.get_world_velocity().x, train.speed, 0.2, "the climber travels at train speed")


func test_reset_train_while_clinging_to_it() -> void:
	var ladder := train.get_node("CrewCar/RoofLadder") as Ladder
	player.teleport_to(Vector3(ladder.global_position.x, 1.05, -1.6), Vector3.FORWARD)
	await physics_frames(10)
	player.input.script_interact()
	await seconds(0.6)
	check_eq(player.state, Player.State.CLIMB, "player holds the ladder")
	train.set_mode_index(0)
	train.start()
	await seconds(7.0)
	game.reset_train()
	await seconds(0.5)
	check_eq(player.state, Player.State.CLIMB, "the player is still on the ladder after the reset")
	check_near(player.global_position.x, ladder.global_position.x, 0.05, "and came back to the platform with it")
	check_less(player.get_world_velocity().length(), 0.1, "without any stray velocity")
	player.input.script_interact()
	await seconds(1.0)
	check(player.is_grounded(), "letting go lands the player safely")
	check_near(player.global_position.y, 1.0, 0.05, "on the platform")


func test_player_on_track_is_pushed_not_swallowed() -> void:
	# Stand on the track bed right in front of the locomotive.
	var locomotive := train.get_node("Locomotive") as TrainCar
	player.teleport_to(Vector3(locomotive.global_position.x + 6.5, 0.05, -3.5))
	await seconds(0.5)
	check(player.is_grounded(), "player stands on the track bed")
	train.set_mode_index(0)
	train.start()
	var inside_train := false
	for i in 420:
		await render_frame()
		var local := locomotive.to_local(player.global_position)
		# Inside the solid part of the locomotive?
		if absf(local.x) < 4.2 and absf(local.z) < 1.2 and local.y < 3.0 and local.y > -0.5:
			inside_train = true
	var ahead := player.global_position.x - locomotive.global_position.x
	note("after 7 s the player is %.2f m ahead of the locomotive's centre, y %.2f" % [ahead, player.global_position.y])
	check(not inside_train, "the player never ends up inside the locomotive")
	check_greater(ahead, 4.0, "the player is pushed along in front of the train")
	check_greater(player.global_position.y, -0.1, "the player is not pushed through the ground")
	check(is_finite(player.global_position.x), "the player's position stays valid")
