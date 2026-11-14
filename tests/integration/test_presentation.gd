extends TestSuite
## Presentation regressions use the real scene and signals, including cutaway geometry.

var game: Game


func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn") as Game
	game.player.input.scripted = true
	game.player.input.clear()
	await seconds(0.3)


func after_each() -> void:
	await free_spawned()


func test_departure_instrument_tracks_real_train_states() -> void:
	check_eq(game.hud.get_departure_status(), "AT PLATFORM", "parked train is identified")
	game.train.start()
	await seconds(0.2)
	check_eq(game.hud.get_departure_status(), "DEPARTING", "departure is visible without opening debug")
	await seconds(11)
	check_eq(game.hud.get_departure_status(), "UNDER WAY", "cruise status is live")
	game.train.stop()
	await seconds(0.2)
	check_eq(game.hud.get_departure_status(), "BRAKING", "braking is distinguished from departure")
	await seconds(7)
	check_eq(game.hud.get_departure_status(), "STOPPED", "stopped away from platform is not mislabelled")
	game.reset_train()
	await seconds(0.2)
	check_eq(game.hud.get_departure_status(), "AT PLATFORM", "reset refreshes the instrument")


func test_location_changes_follow_interior_and_upper_floor() -> void:
	game.player.teleport_to(Vector3(44.5, 0.05, 1.2))
	await seconds(0.4)
	check_eq(game.hud.get_location(), "A  /  BONDED STORES", "ground floor identified")
	game.player.teleport_to(Vector3(51, 3.65, 1.2))
	await seconds(0.4)
	check_eq(game.hud.get_location(), "A  /  UPPER STORES", "upper floor identified")
	game.player.teleport_to(Vector3(80.5, 0.05, 1.0))
	await seconds(0.4)
	check_eq(game.hud.get_location(), "B  /  TRANSFER HALL", "second warehouse has its own identity")
	game.reset_player()
	await seconds(0.4)
	check_eq(game.hud.get_location(), "01  /  PLATFORM", "leaving buildings restores exterior label")


func test_boarding_confirmation_requires_sustained_contact() -> void:
	var flat := game.train.get_node("FlatCar") as TrainCar
	game.player.teleport_to(flat.to_global(Vector3(0, 1.05, 0)))
	await seconds(0.6)
	check(game.player.is_on_train(), "player is really aboard")
	check_eq(game.hud.get_message(), "ABOARD  /  HOLD ON", "successful boarding is confirmed")
	await seconds(3)
	check_eq(game.hud.get_message(), "", "confirmation expires instead of repeating every tick")


func test_interaction_prompt_uses_player_eligibility() -> void:
	var ladder := game.train.get_node("CrewCar/RoofLadder") as Ladder
	game.player.teleport_to(Vector3(ladder.global_position.x, 1.05, -1.55), Vector3.FORWARD)
	await seconds(0.3)
	check_eq(game.hud._prompt.text, game.player.get_interaction_prompt(), "HUD agrees with actual available action")
	check(game.hud._prompt.text.contains("E"), "boarding input is visible near the ladder")
	game.player.input.script_interact()
	await seconds(0.4)
	check(game.hud._prompt.text.contains("climb"), "attached prompt switches to climb controls")
	game.player.teleport_to(Vector3(25, 1.05, 0.3))
	await seconds(0.4)
	check_eq(game.hud._prompt.text, game.player.get_interaction_prompt(), "detaching removes stale controls")


func test_exhaustion_is_readable_and_recovers() -> void:
	game.player.stamina.current = 0
	game.player.stamina.is_exhausted = true
	await seconds(0.2)
	check(game.hud._stamina_label.text.contains("EXHAUSTED"), "exhaustion has text as well as color")
	game.reset_stamina()
	await seconds(0.2)
	check_eq(game.hud._stamina_label.text, "STAMINA", "reset clears the warning")
	check_near(game.hud._stamina_target, game.player.stamina.max_stamina, 0.01, "bar target resets")


func test_message_expiry_and_rebinding() -> void:
	game.hud.bind(game.player, game.train, game.station)
	game.hud.bind(game.player, game.train, game.station)
	game.hud.show_message("TEST NOTICE", 0.3)
	check_eq(game.hud.get_message(), "TEST NOTICE", "message is available immediately")
	await seconds(0.8)
	check_eq(game.hud.get_message(), "", "expired message is cleared")
	check_near(game.hud._message_panel.modulate.a, 0, 0.01, "expired notice fades completely")
	check_eq(game.player.stamina.changed.get_connections().filter(func(c: Dictionary) -> bool: return c.callable.get_object() == game.hud).size(), 1, "rebind does not duplicate stamina callbacks")


func test_facade_details_hide_with_cutaway_and_restore() -> void:
	var wall := game.station.get_node("WarehouseA/FrontWall") as CutawayWall
	var meshes := _meshes(wall.get_node("FacadeDetails"))
	check_greater(meshes.size(), 3, "facade includes batched trim and text meshes")
	game.player.teleport_to(Vector3(44.5, 0.05, 1.2))
	await seconds(0.8)
	for mesh in meshes:
		check(not mesh.visible, "decorative facade does not obstruct the interior")
	game.reset_player()
	await seconds(0.8)
	for mesh in meshes:
		check(mesh.visible, "facade detail returns on exit")


func test_rear_details_hide_when_riding_behind_building() -> void:
	var wall := game.station.get_node("WarehouseB/BackWall") as CutawayWall
	var meshes := _meshes(wall.get_node("InteriorDetails"))
	game.player.teleport_to(Vector3(80, 3.7, -3.2))
	await seconds(0.8)
	check(wall.is_cut_away(), "track lane opens the rear wall")
	for mesh in meshes:
		check(not mesh.visible, "rear signs and conduit do not float over rider")


func test_new_art_contains_no_collision_or_excess_lights() -> void:
	var total_meshes := 0
	for root in get_tree().get_nodes_in_group(&"presentation_detail"):
		if not game.is_ancestor_of(root):
			continue
		total_meshes += _meshes(root).size()
		check(_count_type(root, "CollisionObject3D") == 0, "decorations cannot change traversal")
		check(_count_type(root, "Light3D") == 0, "decorations reuse authored lights")
	check_less(total_meshes, 450, "detail batches have a bounded instance budget")
	note("decorative mesh instances: %d" % total_meshes)


func test_feedback_does_not_change_body_scale_or_camera() -> void:
	var body_scale := game.player.scale
	var config := game.player.config
	var camera_profile := game.camera_rig.get_active_profile()
	game.player.input.script_jump()
	await seconds(0.9)
	check_eq(game.player.scale, body_scale, "landing animation never scales the collision body")
	check_eq(game.player.config, config, "presentation never replaces movement tuning")
	check_eq(game.camera_rig.get_active_profile(), camera_profile, "feedback does not replace camera framing")
	check_near(game.player.visual.position.y, 0, 0.1, "landing displacement is limited")


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_meshes(child))
	return found


func _count_type(node: Node, type: String) -> int:
	var count := 1 if node.is_class(type) else 0
	for child in node.get_children():
		count += _count_type(child, type)
	return count
