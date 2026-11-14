extends TestSuite
## Actual immersive main scene; no substitution of the legacy sandbox camera.

var game: Game
var player: Player
var view: ExplorationCamera


func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn") as Game
	player = game.player
	player.input.scripted = true
	view = game.camera_rig.exploration
	view.settings = CameraSettings.new()
	view.request_perspective(1)
	player.teleport_to(Vector3(28, 1.05, 0.4), Vector3.RIGHT)
	await seconds(0.4)


func after_each() -> void:
	for action in [&"move_in", &"move_out", &"move_left", &"move_right"]:
		Input.action_release(action)
	await free_spawned()


func test_first_person_eye_and_third_person_initialization() -> void:
	check(player.input.camera_relative, "immersive movement uses camera yaw")
	check_eq(player.interactor.aim_camera, view.camera, "interaction uses the rendered eye")
	check_greater(view._collision_distance, 2.0, "outdoor third person boom extends")
	view.request_perspective(0)
	await seconds(0.8)
	check_less(view.camera.global_position.distance_to(player.global_position + Vector3.UP * 1.6), 0.02, "first person camera reaches eye height")
	check(not player.visual.visible, "first person hides the body from its own camera")
	check_near(view.camera.fov, 78, 0.1, "first person uses configured FOV")


func test_mouse_look_is_unbounded_horizontally_and_limited_vertically() -> void:
	var original := view.yaw
	view.look(Vector2(100, 50))
	check_near(wrapf(view.yaw - original, -PI, PI), -0.25, 0.001, "horizontal sensitivity applied")
	view.look(Vector2(100000, 100000))
	check_near(view.pitch, deg_to_rad(-75), 0.001, "downward pitch is bounded")
	view.look(Vector2(-200000, -200000))
	check_near(view.pitch, deg_to_rad(75), 0.001, "upward pitch is bounded")
	check(is_finite(view.yaw) and absf(view.yaw) <= PI, "yaw wraps without limits on rotations")


func test_physical_v_key_switches_view_without_reset() -> void:
	var location := player.global_position
	var key := InputEventKey.new()
	key.physical_keycode = KEY_V
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	for i in 3:
		await render_frame()
	check_eq(view.perspective, 0, "physical V switches into first person")
	key = InputEventKey.new()
	key.physical_keycode = KEY_V
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check_less(player.global_position.distance_to(location), 0.01, "key does not teleport or reset body")


func test_physical_wasd_follows_camera_in_all_four_directions() -> void:
	player.input.scripted = false
	for yaw in [0.0, PI / 2, PI, -PI / 2]:
		player.teleport_to(Vector3(130, 0.05, 8))
		view.yaw = yaw
		await seconds(0.2)
		var start := player.global_position
		Input.action_press(&"move_in")
		await seconds(0.5)
		Input.action_release(&"move_in")
		var displacement := player.global_position - start
		displacement.y = 0
		var forward := -Basis(Vector3.UP, yaw).z
		check_greater(displacement.dot(forward), 1.1, "W travels forward at yaw %.2f" % yaw)
		check_less(absf(displacement.dot(Basis(Vector3.UP, yaw).x)), 0.08, "no lateral drift")


func test_swept_sphere_prevents_camera_crossing_warehouse_wall() -> void:
	player.teleport_to(Vector3(44, 0.05, 3.65), Vector3.FORWARD)
	view.pitch = 0
	await seconds(0.4)
	check_less(view._collision_distance, 0.8, "wall retracts camera boom")
	check_less(view.camera.global_position.z, 4.4, "camera stays inside wall")
	player.teleport_to(Vector3(130, 0.05, 8), Vector3.FORWARD)
	await seconds(0.5)
	check_greater(view._collision_distance, 3.0, "camera extends when obstruction clears")


func test_switch_preserves_motion_stamina_and_held_object() -> void:
	var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"), 1, player.global_position + Vector3(0.3, 0.1, 0))
	await seconds(0.2)
	check(game.scavenging.pick_up(player, cargo), "cargo picked up")
	player.input.script_move(1)
	await seconds(0.4)
	player.input.script_jump()
	await physics_frames(4)
	for perspective in [0, 1, 0, 1]:
		var position := player.global_position
		var velocity := player.velocity
		var stamina := player.stamina.current
		view.request_perspective(perspective)
		check_eq(player.global_position, position, "switch never teleports player")
		check_eq(player.velocity, velocity, "switch preserves velocity")
		check_eq(player.stamina.current, stamina, "switch preserves stamina")
		check_eq(game.scavenging.carried, cargo, "same cargo remains held")
		check_eq(cargo.get_parent(), player.carry_anchor, "cargo moves to active carrying anchor")


func test_switch_queues_until_scripted_traversal_finishes() -> void:
	player.teleport_to(Vector3(18.6, 1.05, 1.35), Vector3.LEFT)
	await seconds(0.3)
	player.input.script_interact()
	await physics_frames(3)
	check_eq(player._mode, Player.Mode.SCRIPTED, "real crate starts scripted vault")
	view.request_perspective(0)
	check_eq(view.perspective, 1, "camera change is queued during vault")
	await seconds(1)
	check_eq(view.perspective, 0, "camera change applies once vault completes")


func test_switching_during_acceleration_has_no_train_relative_drift() -> void:
	var flat := game.train.get_node("FlatCar") as TrainCar
	player.teleport_to(flat.to_global(Vector3(2.4, 1.05, 0)))
	await seconds(0.4)
	var origin := flat.to_local(player.global_position)
	game.train.set_mode_index(0)
	game.train.start()
	var drift := 0.0
	for tick in 480:
		if tick % 30 == 0:
			view.request_perspective(1 - view.perspective)
		await render_frame()
		drift = maxf(drift, flat.to_local(player.global_position).distance_to(origin))
	check(player.is_on_train(), "still aboard after repeated perspective switches")
	check_less(drift, 0.03, "switching causes no riding drift")
	check_greater(game.train.speed, 10, "test includes full departure acceleration")


func test_both_perspectives_target_and_search_with_camera_ray() -> void:
	for perspective in [0, 1]:
		game.reset_station()
		view.request_perspective(perspective)
		var cache := game.scavenging.containers[0]
		player.teleport_to(cache.global_position + Vector3(0, 0.05, -1.1), Vector3.FORWARD)
		await seconds(0.8)
		view.aim_at(cache.global_position + Vector3.UP * 0.65)
		await physics_frames(2)
		check_eq(player.interactor.find_interactable(), cache, "reticle selects cache in perspective %d" % perspective)
		player.input.script_interact()
		await seconds(cache.search_seconds + 0.2)
		check(cache.is_searched, "E completes actual search in perspective %d" % perspective)
		check_greater(game.inventory_system.backpack.used_slots(), 0, "search yields supplies")


func test_targeting_rejects_objects_behind_wall_or_beyond_reach() -> void:
	view.request_perspective(0)
	var cache := game.scavenging.containers[0]
	player.teleport_to(cache.global_position + Vector3(0, 0.05, 4), Vector3.FORWARD)
	await seconds(0.8)
	view.aim_at(cache.global_position + Vector3.UP * 0.65)
	check(player.interactor.find_interactable() != cache, "camera cannot grant remote reach")
	player.teleport_to(cache.global_position + Vector3(0, 0.05, -1.1), Vector3.FORWARD)
	var wall := StaticBody3D.new()
	game.add_child(wall)
	wall.global_position = cache.global_position + Vector3(0, 1, -0.55)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.12)
	collider.shape = shape
	wall.add_child(collider)
	await seconds(0.3)
	view.aim_at(cache.global_position + Vector3.UP * 0.65)
	check(player.interactor.find_interactable() != cache, "wall blocks even protruding interaction volumes")


func test_held_cargo_does_not_block_storage_targeting_in_either_view() -> void:
	for perspective in [0, 1]:
		var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"), 1, player.global_position + Vector3(0.3, 0.1, 0))
		await seconds(0.2)
		check(game.scavenging.pick_up(player, cargo), "cargo picked up for storage visit")
		view.request_perspective(perspective)
		var hold := game.scavenging.storage_point
		player.teleport_to(hold.global_position + Vector3(0, 0.05, 0.75), Vector3.FORWARD)
		await seconds(0.8)
		view.aim_at(hold.global_position + Vector3.UP * 0.65)
		check_eq(player.interactor.find_interactable(), hold, "held mesh/area does not consume storage ray")
		player.input.script_interact()
		await physics_frames(3)
		check(game.supply_ui.storage_mode, "E opens storage while carrying in perspective %d" % perspective)
		check_eq(game.scavenging.deposit_all(), 1, "cargo deposits once")
		game.supply_ui.close()


func test_camera_preferences_persist_and_menu_sources_are_independent() -> void:
	var path := "user://test_camera.cfg"
	view.settings.default_perspective = 0
	view.settings.sensitivity = 0.004
	view.settings.first_person_fov = 90
	view.settings.third_person_distance = 4.5
	view.settings.smoothing = 9
	check_eq(view.settings.save_preferences(path), OK, "preferences saved")
	var loaded := CameraSettings.new()
	loaded.load_preferences(path)
	for key in ["default_perspective", "sensitivity", "first_person_fov", "third_person_distance", "smoothing"]:
		check_eq(loaded.get(key), view.settings.get(key), "%s survives reload" % key)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.supply_ui.open()
	game.debug_menu.set_open(true)
	game.supply_ui.close()
	check_eq(view._menu_sources.size(), 1, "closing inventory retains debug mouse release")
	game.debug_menu.set_open(false)
	check(view._menu_sources.is_empty(), "last closed menu restores gameplay capture")
