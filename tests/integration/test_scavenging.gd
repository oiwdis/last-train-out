extends TestSuite

var game: Game
var service: ScavengingSystem
var bag: InventoryModel
var messages: Array[String] = []


func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn") as Game
	service = game.scavenging
	bag = game.inventory_system.backpack
	game.player.input.scripted = true
	game.player.input.clear()
	messages.clear()
	service.notice.connect(func(message: String) -> void: messages.append(message))
	await seconds(0.3)


func after_each() -> void:
	await free_spawned()


func _cache(id: StringName) -> SearchContainer:
	for cache in service.containers:
		if cache.cache_id == id:
			return cache
	return null


func _approach(cache: SearchContainer) -> bool:
	game.player.input.clear()
	for offset: Vector3 in [Vector3(0, 0.03, 0.8), Vector3(-0.85, 0.03, 0), Vector3(0.85, 0.03, 0), Vector3(0, 0.03, -0.8), Vector3(-0.65, 0.03, -0.55), Vector3(0.65, 0.03, 0.55), Vector3(0, 0.03, 0)]:
		var point := cache.global_position + offset
		if not game.player.interactor.capsule_fits(point):
			continue
		game.player.teleport_to(point, Vector3(-offset.x, 0, -offset.z).normalized() if offset.length() > 0.1 else Vector3.RIGHT)
		await seconds(0.3)
		game.camera_rig.exploration.aim_at(cache.global_position + Vector3.UP * 0.65)
		if game.player.is_grounded() and cache.can_interact(game.player) and game.player._choose_interaction().get("interactable") == cache:
			return true
	return false


func _total_items() -> Dictionary:
	var total := {}
	var models: Array[InventoryModel] = [bag, game.inventory_system.storage]
	for cache in service.containers:
		models.append(cache.contents)
	for model in models:
		for id: StringName in model.totals():
			total[id] = int(total.get(id, 0)) + model.count(id)
	for world in service.world_items:
		if is_instance_valid(world) and not world.is_queued_for_deletion():
			total[world.item.id] = int(total.get(world.item.id, 0)) + world.amount
	return total


func test_every_authored_search_location_is_reachable_and_selectable() -> void:
	check_eq(service.containers.size(), 13, "all exploration sites are populated")
	for cache in service.containers:
		check(await _approach(cache), "%s can be approached and used without going through geometry" % cache.cache_id)
		check(cache.search_seconds >= 1 and cache.search_seconds <= 4, "search duration stays within brief")
		check_greater(cache.contents.used_slots(), 0, "cache has seeded supplies")


func test_search_both_warehouses_through_the_real_interaction_input() -> void:
	for id in [&"a_toolbox", &"b_cabinet"]:
		var cache := _cache(id)
		if not check(await _approach(cache), "warehouse cache is reachable"):
			continue
		var total := _total_items()
		game.player.input.script_interact()
		await physics_frames(2)
		check_eq(service.active_search, cache, "E starts the intended search")
		check(game.supply_ui._progress_panel.visible, "progress indicator is visible")
		await seconds(cache.search_seconds + 0.2)
		check(cache.is_searched, "search finishes")
		check(service.active_search == null, "completion releases active search")
		check(not game.supply_ui._progress_panel.visible, "progress closes after completion")
		check_eq(_total_items(), total, "search preserves every item")
	check_greater(bag.used_slots(), 0, "search rewards reach the backpack")


func test_search_cancellation_does_not_reroll_or_consume_loot() -> void:
	var cache := _cache(&"platform_luggage")
	check(await _approach(cache), "can approach luggage")
	var original := cache.contents.totals()
	for i in 3:
		service.use_container(game.player, cache)
		await seconds(0.3)
		service.cancel_search()
		check(not cache.is_searched, "cancelled cache remains unsearched")
		check_eq(cache.contents.totals(), original, "repeated cancellations cannot reroll supplies")
	service.use_container(game.player, cache)
	game.player.input.script_move(-1)
	await physics_frames(2)
	check(service.active_search == null, "walking cancels immediately")
	game.player.input.clear()


func test_full_backpack_leaves_overflow_inside_the_searched_cache() -> void:
	for id in ItemCatalog.IDS:
		var item := ItemCatalog.find(id)
		if not item.heavy:
			bag.add(item, item.stack_limit)
	var cache := _cache(&"platform_luggage")
	check(await _approach(cache), "cache reachable")
	var before := _total_items()
	var stored := cache.contents.totals()
	service.use_container(game.player, cache)
	await seconds(cache.search_seconds + 0.2)
	check_eq(cache.contents.totals(), stored, "overflow remains in container")
	check(messages.any(func(text: String) -> bool: return text.contains("Backpack full")), "full warning is explicit")
	var item := cache.contents.get_slot(0).item as ItemDefinition
	for i in 6:
		var slot := bag.get_slot(i)
		if not slot.is_empty() and (slot.item as ItemDefinition).id == item.id:
			service.drop_slot(i, true)
			break
	service.use_container(game.player, cache)
	check_less(cache.contents.count(item.id), int(stored[item.id]), "remaining loot can be collected without another search")
	check_eq(_total_items(), before, "overflow, drop and recollection conserve quantities")


func test_pickup_drop_and_repeated_interactions_conserve_items() -> void:
	var food := ItemCatalog.find(&"canned_food")
	var world := service.spawn_world(food, 7, game.player.global_position + Vector3(0.4, 0.1, 0))
	await seconds(0.2)
	var before := _total_items()
	check(service.pick_up(game.player, world), "pickup works")
	check_eq(bag.count(food.id), 7, "all food stacked in backpack")
	for i in 10:
		service.pick_up(game.player, world)
	check_eq(bag.count(food.id), 7, "retired world item cannot be picked up again")
	check(service.drop_slot(0), "one item dropped")
	check_eq(bag.count(food.id), 6, "drop subtracts exactly one")
	check(service.drop_slot(0, true), "rest of selected stack dropped")
	check_eq(_total_items(), before, "drop/pickup does not lose or duplicate anything")


func test_search_reveals_a_single_heavy_object_exactly_once() -> void:
	var cache := _cache(&"a_coal")
	check(await _approach(cache), "coal cache reachable")
	var before := _total_items()
	service.use_container(game.player, cache)
	await seconds(cache.search_seconds + 0.2)
	check_eq(service.world_items.size(), 1, "coal becomes one physical sack")
	check_eq(service.world_items[0].item.id, &"coal_sack", "correct cargo definition")
	for i in 15:
		service.collect_container(cache)
	check_eq(service.world_items.size(), 1, "repeated collection cannot respawn cargo")
	check_eq(_total_items(), before, "revealed cargo retains its original quantity")


func test_storage_deposit_withdraw_and_partial_capacity() -> void:
	game.player.teleport_to(service.storage_point.global_position + Vector3(0, 0.05, 0.75), Vector3.FORWARD)
	await seconds(0.3)
	check(service.storage_in_range(), "hold reachable from platform")
	bag.add(ItemCatalog.find(&"scrap_metal"), 15)
	bag.add(ItemCatalog.find(&"medicine"), 3)
	var before := _total_items()
	check_eq(service.deposit_all(), 18, "deposit all moves backpack supplies")
	check_eq(service.deposit_all(), 0, "repeated deposit cannot duplicate")
	check_eq(bag.used_slots(), 0, "backpack empty after deposit")
	check_eq(service.withdraw_slot(0), 8, "withdraw fills backpack using stack limits")
	check_eq(_total_items(), before, "deposit and withdrawal conserve all quantities")
	game.inventory_system.storage = InventoryModel.new(1, true)
	game.inventory_system.storage.add(ItemCatalog.find(&"scrap_metal"), 7)
	check_eq(service.deposit_all(), 1, "storage capacity permits a partial transfer")
	check_eq(bag.count(&"scrap_metal"), 7, "excess stays in backpack")


func test_storage_out_of_range_and_moving_away_reject_transactions() -> void:
	bag.add(ItemCatalog.find(&"tools"), 2)
	check_eq(service.deposit_all(), 0, "remote deposit rejected")
	game.player.teleport_to(service.storage_point.global_position + Vector3(0, 0.05, 0.75), Vector3.FORWARD)
	await seconds(0.3)
	service.open_storage(game.player)
	check(game.supply_ui.storage_mode, "ledger opens at the hold")
	game.train.start()
	await seconds(3)
	check(not game.supply_ui.is_open(), "moving out of range closes the ledger")
	check(not game.player.input.blocked, "movement is restored after interruption")
	check_eq(service.deposit_all(), 0, "stale UI cannot transfer to a distant train")
	check_eq(bag.count(&"tools"), 2, "interrupted access preserves backpack")


func test_station_reset_restores_seeded_caches_and_clears_collected_supplies() -> void:
	var original := _total_items()
	var cache := _cache(&"platform_luggage")
	check(await _approach(cache), "cache reachable")
	service.use_container(game.player, cache)
	await seconds(cache.search_seconds + 0.2)
	service.drop_slot(0)
	game.reset_station()
	await physics_frames(4)
	check_eq(bag.used_slots(), 0, "reset clears backpack")
	check_eq(game.inventory_system.storage.used_slots(), 0, "reset clears hold")
	check_eq(service.world_items.size(), 0, "reset removes dropped items")
	check(not cache.is_searched, "cache is searchable again")
	check_eq(_total_items(), original, "same seed restores exactly one original loot population")
	game.reset_station()
	await physics_frames(4)
	check_eq(_total_items(), original, "repeated reset does not accumulate loot")


func test_search_cancelled_by_reset_and_backpack_opening() -> void:
	var cache := _cache(&"platform_luggage")
	check(await _approach(cache), "cache reachable")
	service.use_container(game.player, cache)
	game.supply_ui.open()
	check(service.active_search == null, "opening backpack cancels search")
	game.supply_ui.close()
	service.use_container(game.player, cache)
	game.reset_player()
	await seconds(cache.search_seconds + 0.2)
	check(not cache.is_searched, "reset cannot finish a stale search")
	check_eq(bag.used_slots(), 0, "cancelled search awarded nothing")
