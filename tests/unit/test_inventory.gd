extends TestSuite


func test_catalog_has_complete_reusable_definitions() -> void:
	var ids := {}
	for id in ItemCatalog.IDS:
		var item := ItemCatalog.find(id)
		check(item != null and item.id == id, "definition resolves by stable ID")
		check(not ids.has(id), "item IDs are unique")
		ids[id] = true
		check(item.icon != null and item.world_scene != null, "every supply has icon and world representation")
		check(item.weight > 0 and item.stack_limit >= 1 and not item.description.is_empty(), "authoring fields are complete")
		check(not item.heavy or item.stack_limit == 1, "heavy objects are individually represented")
	check_eq(ids.size(), 9, "all nine requested items are defined")


func test_stacking_fills_existing_slots_before_new_ones() -> void:
	var bag := InventoryModel.new(6)
	var food := ItemCatalog.find(&"canned_food")
	check_eq(bag.add(food, 3), 3, "initial pickup accepted")
	check_eq(bag.add(food, 4), 4, "pickup spills into next stack")
	check_eq(bag.get_slot(0).amount, 4, "first stack filled")
	check_eq(bag.get_slot(1).amount, 3, "remainder in second slot")
	check_eq(bag.used_slots(), 2, "only two slots consumed")
	check_near(bag.total_weight(), 3.5, 0.001, "weight is quantity-aware")


func test_capacity_returns_unaccepted_quantity_to_caller() -> void:
	var bag := InventoryModel.new(6)
	var food := ItemCatalog.find(&"canned_food")
	check_eq(bag.add(food, 30), 24, "six slots enforce stack limits")
	check_eq(bag.add(food, 1), 0, "full backpack rejects more")
	check_eq(bag.count(food.id), 24, "rejection does not change inventory")
	check_eq(bag.remove_at(2, 99), 4, "cannot remove more than one slot contains")
	check_eq(bag.add(food, 5), 4, "freed slot is reusable")


func test_heavy_items_do_not_enter_backpack() -> void:
	var item := ItemCatalog.find(&"coal_sack")
	var bag := InventoryModel.new()
	var hold := InventoryModel.new(2, true)
	check_eq(bag.add(item, 1), 0, "backpack rejects physical cargo")
	check_eq(hold.add(item, 3), 2, "train has configurable heavy capacity")
	check_eq(hold.transfer_to(bag, 0), 0, "withdrawal cannot put cargo into a pack")
	check_eq(hold.count(item.id), 2, "rejected transfer preserves cargo")


func test_invalid_mutations_leave_inventory_unchanged() -> void:
	var bag := InventoryModel.new()
	check_eq(bag.add(null, 1), 0, "null item rejected")
	check_eq(bag.add(ItemCatalog.find(&"tools"), -3), 0, "negative pickup rejected")
	check_eq(bag.remove_at(-1, 2), 0, "invalid slot rejected")
	check_eq(bag.remove_at(100, 2), 0, "out of range slot rejected")
	check_eq(bag.used_slots(), 0, "no ghost stacks")
	bag.add(ItemCatalog.find(&"tools"), 2)
	check_eq(bag.transfer_to(bag, 0), 0, "self transfer is a no-op")
	check_eq(bag.remove_at(0, -2), 0, "negative removal does not add items")
	var snapshot := bag.get_slot(0)
	snapshot.amount = 999
	check_eq(bag.count(&"tools"), 2, "UI snapshots cannot mutate slot quantities")


func test_partial_transfer_preserves_both_sides() -> void:
	var source := InventoryModel.new(3)
	var destination := InventoryModel.new(1)
	var food := ItemCatalog.find(&"canned_food")
	source.add(food, 10)
	destination.add(food, 3)
	check_eq(source.transfer_to(destination, 0), 1, "only free space is transferred")
	check_eq(source.count(food.id), 9, "unaccepted source quantity stays")
	check_eq(destination.count(food.id), 4, "destination stack capped")
	check_eq(source.count(food.id) + destination.count(food.id), 13, "all items conserved")


func test_transfer_signals_observe_atomic_state_and_reject_reentrancy() -> void:
	var source := InventoryModel.new(2)
	var destination := InventoryModel.new(2)
	source.add(ItemCatalog.find(&"scrap_metal"), 12)
	var observed: Array[int] = []
	var attempts: Array[int] = []
	var callback := func() -> void:
		observed.append(source.count(&"scrap_metal") + destination.count(&"scrap_metal"))
		attempts.append(source.transfer_to(destination, 0))
		attempts.append(destination.remove_at(0, 1))
	source.changed.connect(callback)
	check_eq(source.transfer_to(destination, 0, 4), 4, "transfer completes")
	check_eq(observed, [12], "listeners see the completed transaction")
	check_eq(attempts, [0, 0], "signal callbacks cannot interleave mutations")
	source.changed.disconnect(callback) # Break the test callback's deliberate model references.


func test_many_repeated_transfers_never_create_or_lose_items() -> void:
	var a := InventoryModel.new(6)
	var b := InventoryModel.new(8)
	a.add(ItemCatalog.find(&"scrap_metal"), 23)
	a.add(ItemCatalog.find(&"canned_food"), 11)
	b.add(ItemCatalog.find(&"tools"), 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	for iteration in 500:
		var source := a if iteration % 2 == 0 else b
		var destination := b if source == a else a
		source.transfer_to(destination, rng.randi_range(0, source.slot_count - 1), rng.randi_range(1, 10))
		check_eq(a.count(&"scrap_metal") + b.count(&"scrap_metal"), 23, "scrap conserved")
		check_eq(a.count(&"canned_food") + b.count(&"canned_food"), 11, "food conserved")
		check_eq(a.count(&"tools") + b.count(&"tools"), 5, "tools conserved")


func test_loot_tables_use_a_private_seeded_rng() -> void:
	var table := load("res://resources/loot/warehouse_b.tres") as LootTable
	var first := _loot_counts(table.generate(71))
	for i in 50:
		randf()
	check_eq(_loot_counts(table.generate(71)), first, "unrelated random calls cannot change a cache")
	var variations := {}
	for i in 20:
		variations[str(_loot_counts(table.generate(i)))] = true
	check_greater(variations.size(), 1, "different seeds produce different discoveries")


func test_loot_distribution_uses_authored_tables_and_valid_quantities() -> void:
	var platform := load("res://resources/loot/platform.tres") as LootTable
	for seed_value in 25:
		for entry in platform.generate(seed_value):
			check(not (entry.item as ItemDefinition).heavy, "platform has only basic backpack supplies")
			check(entry.amount > 0, "loot quantities are positive")
	var valuable := load("res://resources/loot/precision.tres") as LootTable
	check_eq(_loot_counts(valuable.generate(1)), {&"machine_component": 1}, "far warehouse guarantees valuable heavy cargo")


func _loot_counts(entries: Array[Dictionary]) -> Dictionary:
	var result := {}
	for entry in entries:
		var id := (entry.item as ItemDefinition).id
		result[id] = int(result.get(id, 0)) + int(entry.amount)
	return result
