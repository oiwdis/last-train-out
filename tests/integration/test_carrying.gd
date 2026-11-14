extends TestSuite

var game: Game
var service: ScavengingSystem
var player: Player


func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn") as Game
	service = game.scavenging
	player = game.player
	player.input.scripted = true
	player.input.clear()
	player.teleport_to(Vector3(10, 1.05, 0.4))
	await seconds(0.3)


func after_each() -> void:
	await free_spawned()


func _pick_cargo(id: StringName = &"coal_sack") -> WorldItem:
	var world := service.spawn_world(ItemCatalog.find(id), 1, player.global_position + Vector3(0.4, 0.1, 0))
	await seconds(0.2)
	check(service.pick_up(player, world), "cargo can be picked up")
	check_eq(service.carried, world, "controller owns exactly this object")
	return world


func test_heavy_carry_limits_speed_and_prevents_sprint_without_changing_config() -> void:
	var config := player.config
	var walk := config.walk_speed
	var sprint := config.sprint_speed
	var world := await _pick_cargo()
	player.input.script_move(1, 0, true)
	await seconds(1)
	check_near(player.get_horizontal_speed(), 2.5, 0.03, "cargo walking speed is 2.5 m/s")
	check(not player.is_sprinting(), "sprint input is suppressed while carrying")
	check_near(player.stamina.current, player.stamina.max_stamina, 0.001, "suppressed sprint does not drain stamina")
	check_eq(player.config, config, "same movement resource remains attached")
	check_eq(config.walk_speed, walk, "base walk tuning untouched")
	check_eq(config.sprint_speed, sprint, "base sprint tuning untouched")
	check(world.get_parent() == player.visual and world.held, "object is visibly held by the animated character")
	check_eq(world.collision_mask, 0, "held object cannot collide with the carrier or train")
	player.input.clear()
	service.drop_heavy()
	player.teleport_to(Vector3(20, 1.05, 0.4))
	await seconds(0.2)
	player.input.script_move(1, 0, true)
	await seconds(0.7)
	check_near(player.get_horizontal_speed(), sprint, 0.05, "unladen sprint immediately returns to original tuning")


func test_one_object_limit_and_drop_recovery() -> void:
	var first := await _pick_cargo()
	var second := service.spawn_world(ItemCatalog.find(&"fuel_drum"), 1, player.global_position + Vector3(-0.4, 0.1, 0))
	await seconds(0.2)
	service.pick_up(player, second)
	check_eq(service.carried, first, "cannot replace an already held object")
	check(second.available and not second.held, "second cargo remains in world")
	check(service.drop_heavy(), "dedicated drop releases immediately")
	check(service.carried == null and not player.carrying_heavy, "hands and speed modifier cleared")
	await seconds(0.6)
	check(first.available and first.is_on_floor(), "released cargo stays on ground")
	check_eq(first.collision_layer, 0, "released cargo never pushes or blocks the player")
	service.pick_up(player, first)
	check_eq(service.carried, first, "same physical object can be recovered")
	check_eq(service.world_items.size(), 2, "pickup/drop creates no replacement copies")


func test_carrying_blocks_ladder_with_feedback_then_allows_climb_after_drop() -> void:
	await _pick_cargo()
	var ladder := game.train.get_node("CrewCar/RoofLadder") as Ladder
	player.teleport_to(Vector3(ladder.global_position.x, 1.05, -1.55), Vector3.FORWARD)
	await seconds(0.3)
	check(player.get_interaction_prompt().contains("Drop cargo"), "incompatible action has an explicit prompt")
	player.input.script_interact()
	await physics_frames(2)
	check(not player.is_attached(), "ladder grab is blocked")
	check(game.hud.get_message().contains("Hands full"), "attempt produces feedback")
	check(not player.begin_climb(ladder), "direct climb entry also enforces carrying restriction")
	service.drop_heavy()
	player.input.script_interact()
	await seconds(0.5)
	check(player.is_attached(), "original ladder mechanic works after setting cargo down")


func test_carrying_blocks_vault_without_changing_normal_jump() -> void:
	await _pick_cargo()
	# This low platform crate is the original vault obstacle used by the tour.
	player.teleport_to(Vector3(18.6, 1.05, 1.35), Vector3.LEFT)
	await seconds(0.3)
	var choice := player._choose_interaction()
	check(choice.has("vault"), "test is positioned at a real vaultable obstacle")
	player.input.script_interact()
	await physics_frames(2)
	check(player.state != Player.State.VAULT, "cargo prevents vaulting")
	player.teleport_to(Vector3(23, 1.05, 0.4))
	await seconds(0.3)
	var start := player.global_position.y
	player.input.script_jump()
	await seconds(0.2)
	check_greater(player.global_position.y, start + 0.5, "ordinary jump remains available for boarding")


func test_heavy_cargo_can_jump_aboard_and_ride_the_train() -> void:
	await _pick_cargo()
	var flat := game.train.get_node("FlatCar") as TrainCar
	player.teleport_to(Vector3(flat.global_position.x + 2.5, 1.05, -1.55), Vector3.FORWARD)
	await seconds(0.3)
	player.input.script_move(0, -1)
	player.input.script_jump()
	await seconds(0.7)
	player.input.clear()
	await seconds(0.6)
	check(player.is_on_train(), "cargo can be jump-boarded onto the open deck")
	game.train.start()
	await seconds(2)
	check(player.is_on_train() and service.carried != null, "held cargo follows an accelerating train rider")
	check_less(service.carried.global_position.distance_to(player.global_position), 1.5, "held object never lags behind carrier")


func test_loose_cargo_rides_acceleration_and_follows_train_reset() -> void:
	var flat := game.train.get_node("FlatCar") as TrainCar
	var world := service.spawn_world(ItemCatalog.find(&"machine_component"), 1, flat.to_global(Vector3(2.7, 1.08, 0)))
	await seconds(0.8)
	await render_frame()
	var start := flat.to_local(world.global_position)
	check_eq(world.resting_body, flat, "cargo knows its supporting car")
	game.train.start()
	await seconds(7)
	await render_frame()
	check_less(flat.to_local(world.global_position).distance_to(start), 0.08, "loose cargo is carried without sliding off")
	game.reset_train()
	await seconds(0.7)
	await render_frame()
	check_less(flat.to_local(world.global_position).distance_to(start), 0.1, "train reset carries loose cargo back safely")
	check(world.available and world.amount == 1, "reset preserves one recoverable object")


func test_heavy_deposit_withdraw_and_repeat_clicks_conserve_cargo() -> void:
	var world := await _pick_cargo(&"machine_component")
	player.teleport_to(service.storage_point.global_position + Vector3(0, 0.05, 0.75), Vector3.FORWARD)
	await seconds(0.3)
	check_eq(service.deposit_all(), 1, "heavy object deposits directly from hands")
	check(service.carried == null and not player.carrying_heavy, "deposit frees hands and movement")
	check(world.is_queued_for_deletion(), "deposited representation is retired immediately")
	for i in 10:
		service.deposit_all()
	check_eq(game.inventory_system.storage.count(&"machine_component"), 1, "repeat deposits do not duplicate")
	check_eq(service.withdraw_slot(0), 1, "heavy withdrawal goes into hands")
	check_eq(game.inventory_system.storage.count(&"machine_component"), 0, "withdraw removes stored cargo")
	check(service.carried != null and service.carried.item.id == &"machine_component", "withdrawn object is visible")
	check_eq(service.withdraw_slot(0), 0, "repeat withdrawal cannot recreate empty storage")


func test_player_reset_preserves_cargo_and_station_reset_clears_it() -> void:
	var world := await _pick_cargo()
	game.inventory_system.backpack.add(ItemCatalog.find(&"bandages"), 3)
	game.reset_player()
	await seconds(0.2)
	check_eq(service.carried, world, "player reset keeps the same cargo")
	check_eq(game.inventory_system.backpack.count(&"bandages"), 3, "player reset preserves collected supplies")
	check_less(world.global_position.distance_to(player.global_position), 1.5, "cargo follows the reset player")
	game.reset_station()
	await physics_frames(4)
	check(service.carried == null and not player.carrying_heavy, "station reset releases carry restriction")
	check_eq(game.inventory_system.backpack.used_slots(), 0, "station reset clears inventory")
	check_eq(service.world_items.size(), 0, "station reset cannot leave duplicate cargo")
