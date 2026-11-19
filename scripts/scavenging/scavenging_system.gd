class_name ScavengingSystem
extends Node
## Coordinates world ownership and inventory transactions. Data models know no UI or nodes.

signal collected(cache_id: String, item_id: String, amount: int)
signal notice(text: String)
signal search_progress(title: String, fraction: float)
signal search_finished(completed: bool)
signal carrying_changed(item: ItemDefinition)
signal storage_requested

@export var loot_seed := 2017
var player: Player
var inventories: InventorySystem
var world_root: Node3D
var storage_point: SupplyInteractable
var containers: Array[SearchContainer] = []
var world_items: Array[WorldItem] = []
var carried: WorldItem
var active_search: SearchContainer
var search_elapsed := 0.0
var _search_origin := Vector3.ZERO
var _transaction := false
var _item_serial := 0


func bind(player_ref: Player, inventory_ref: InventorySystem, station: Station, train: Train, world_parent: Node3D) -> void:
	player = player_ref
	inventories = inventory_ref
	world_root = Node3D.new()
	world_root.name = "DroppedSupplies"
	world_parent.add_child(world_root)
	if station != null:
		var sites := (load("res://scenes/station/scavenging_sites.tscn") as PackedScene).instantiate()
		station.add_child(sites)
		for child in sites.get_children():
			var cache := child as SearchContainer
			containers.append(cache)
			cache.action = func(who: Player) -> bool: return use_container(who, cache)
			cache.reset_loot(loot_seed)
	if train != null:
		storage_point = SupplyInteractable.new()
		storage_point.name = "TrainStorage"
		storage_point.position = Vector3(-1.0, 1.0, 1.2)
		storage_point.prompt = "Open train storage"
		storage_point.reach = 1.85
		storage_point.action = open_storage
		train.get_node("FlatCar").add_child(storage_point)
		var d := DetailBuilder.new(storage_point, "StorageMarking")
		d.box(Vector3(0, 0.38, -0.6), Vector3(1.4, 0.75, 0.55), Color("405f5b"))
		d.box(Vector3(0, 0.77, -0.6), Vector3(1.45, 0.05, 0.6), DetailBuilder.INK)
		d.signboard(Vector3(0, 0.42, -0.3), "SUPPLY HOLD", 1.3, 0.36, DetailBuilder.AMBER)
		d.signboard(Vector3(0, 1.6, -0.45), "DEPOSIT / COLLECT", 2.7, 0.45)
		d.finish()
	set_physics_process(false)


func use_container(who: Player, cache: SearchContainer) -> bool:
	if who != player or _transaction or not cache.is_reachable(player):
		return false
	if active_search == cache:
		cancel_search()
		return true
	if carried != null:
		notice.emit("Hands full — G to set down cargo before searching")
		return true
	if not player.is_grounded():
		notice.emit("Stand on firm ground to search")
		return true
	if cache.is_searched:
		collect_container(cache)
		return true
	cancel_search(false)
	active_search = cache
	search_elapsed = 0
	_search_origin = player.global_position
	cache.refresh_prompt(true)
	search_progress.emit(cache.title, 0)
	set_physics_process(true)
	return true


func cancel_search(show_notice: bool = true) -> void:
	if active_search == null:
		return
	active_search.refresh_prompt()
	active_search = null
	search_elapsed = 0
	set_physics_process(false)
	search_finished.emit(false)
	if show_notice:
		notice.emit("Search cancelled — supplies remain untouched")


func _physics_process(delta: float) -> void:
	if active_search == null:
		return
	if not player.is_grounded() or player.input.move.length_squared() > 0.01 or player.global_position.distance_to(_search_origin) > 0.2 or not active_search.is_reachable(player):
		cancel_search()
		return
	search_elapsed += delta
	search_progress.emit(active_search.title, minf(search_elapsed / active_search.search_seconds, 1))
	if search_elapsed >= active_search.search_seconds:
		var cache := active_search
		active_search = null
		set_physics_process(false)
		cache.complete()
		collect_container(cache)
		search_finished.emit(true)


func collect_container(cache: SearchContainer) -> void:
	if _transaction or not cache.is_searched or not cache.is_reachable(player):
		return
	_transaction = true
	var gathered := 0
	var cargo := 0
	for i in cache.contents.slot_count:
		var slot := cache.contents.get_slot(i)
		if slot.is_empty():
			continue
		var definition := slot.item as ItemDefinition
		if definition.heavy:
			for j in int(slot.amount):
				var world := spawn_world(definition, 1, find_drop_position(cargo))
				if world != null:
					cache.contents.remove_at(i, 1)
					cargo += 1
					collected.emit(cache.cache_id, str(definition.id), 1)
		else:
			var accepted := cache.contents.transfer_to(inventories.backpack, i)
			gathered += accepted
			if accepted > 0:
				collected.emit(cache.cache_id, str(definition.id), accepted)
	cache.refresh_prompt()
	_transaction = false
	if cache.contents.used_slots() > 0:
		notice.emit("Backpack full — %d collected; remaining supplies stay here" % gathered)
	elif gathered + cargo > 0:
		notice.emit("Search complete · +%d supplies%s" % [gathered, " · %d heavy cargo revealed" % cargo if cargo > 0 else ""])
	else:
		notice.emit("Already searched — this cache is empty")


func spawn_world(definition: ItemDefinition, amount: int, at: Vector3) -> WorldItem:
	if definition == null or amount <= 0 or (definition.heavy and amount != 1):
		return null
	var world := WorldItem.new()
	_item_serial += 1
	world.persistent_id = "supply_%d" % _item_serial
	world.item = definition
	world.amount = amount
	world.position = world_root.to_local(at)
	world_root.add_child(world)
	world.interaction.action = func(who: Player) -> bool: return pick_up(who, world)
	world_items.append(world)
	return world


func pick_up(who: Player, world: WorldItem) -> bool:
	if who != player or _transaction or not is_instance_valid(world) or not world.available or not world.interaction.is_reachable(player):
		return false
	if world.item.heavy:
		if carried != null:
			notice.emit("One heavy object at a time — G to drop the current cargo")
		elif not player.is_grounded() or player._mode != Player.Mode.LOCOMOTION:
			notice.emit("Finish climbing and stand on firm ground before lifting cargo")
		else:
			cancel_search(false)
			_hold(world)
			notice.emit("Carrying %s · 2.5 m/s · G to drop" % world.item.display_name)
		return true
	_transaction = true
	world.available = false
	var accepted := inventories.backpack.add(world.item, world.amount)
	world.amount -= accepted
	if world.amount == 0:
		world.retire()
	else:
		world.available = true
		world.interaction.prompt = "Take %s ×%d" % [world.item.display_name, world.amount]
	_transaction = false
	notice.emit("+%d %s" % [accepted, world.item.display_name] if accepted > 0 else "Backpack full — drop or deposit a stack first")
	return true


func _hold(world: WorldItem) -> void:
	carried = world
	player.carrying_heavy = true
	world.hold(player)
	carrying_changed.emit(world.item)


func drop_heavy() -> bool:
	if _transaction or carried == null:
		return false
	_transaction = true
	var world := carried
	carried = null
	player.carrying_heavy = false
	world.release(world_root, find_drop_position(), player.get_world_velocity())
	carrying_changed.emit(null)
	_transaction = false
	notice.emit("Set down %s — E to recover" % world.item.display_name)
	return true


func drop_slot(index: int, whole_stack: bool = false) -> bool:
	if _transaction:
		return false
	var slot := inventories.backpack.get_slot(index)
	if slot.is_empty():
		return false
	_transaction = true
	var amount := int(slot.amount) if whole_stack else 1
	var world := spawn_world(slot.item, amount, find_drop_position())
	var removed := inventories.backpack.remove_at(index, amount) if world != null else 0
	if removed == 0 and world != null:
		world.retire()
	elif world != null:
		world.velocity = player.get_world_velocity()
	_transaction = false
	if removed > 0:
		notice.emit("Dropped %d %s" % [removed, (slot.item as ItemDefinition).display_name])
	return removed > 0


func find_drop_position(index: int = 0) -> Vector3:
	# Use the player's clear capsule as the fallback. Cargo never collides with the player.
	var offsets: Array[Vector3] = [player.facing * 0.65 + Vector3.RIGHT * index * 0.55,
		Vector3.RIGHT * 0.65, Vector3.LEFT * 0.65, Vector3.ZERO]
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.26
	shape.height = 0.74
	query.shape = shape
	query.collision_mask = 5
	for offset in offsets:
		var at := player.global_position + offset + Vector3.UP * 0.12
		query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.4)
		if player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return at
	return player.global_position + Vector3.UP * 0.2


func storage_in_range() -> bool:
	return is_instance_valid(storage_point) and storage_point.is_reachable(player)


func open_storage(who: Player) -> bool:
	if who != player or not storage_in_range():
		return false
	cancel_search(false)
	storage_requested.emit()
	return true


func deposit_all() -> int:
	if _transaction or not storage_in_range():
		return 0
	_transaction = true
	var moved := 0
	for i in inventories.backpack.slot_count:
		moved += inventories.backpack.transfer_to(inventories.storage, i)
	if carried != null and inventories.storage.add(carried.item, 1) == 1:
		carried.retire()
		carried = null
		player.carrying_heavy = false
		carrying_changed.emit(null)
		moved += 1
	_transaction = false
	notice.emit("Secured aboard · %d supplies deposited" % moved if moved > 0 else "Nothing deposited — check your supplies and storage capacity")
	return moved


func deposit_slot(index: int) -> int:
	if _transaction or not storage_in_range():
		return 0
	var moved := inventories.backpack.transfer_to(inventories.storage, index)
	notice.emit("Secured aboard · %d supplies deposited" % moved if moved > 0 else "Nothing deposited — hold full or selected slot empty")
	return moved


func withdraw_slot(index: int) -> int:
	if _transaction or not storage_in_range():
		return 0
	var slot := inventories.storage.get_slot(index)
	if slot.is_empty():
		return 0
	if not (slot.item as ItemDefinition).heavy:
		var moved := inventories.storage.transfer_to(inventories.backpack, index)
		notice.emit("Withdrew %d %s" % [moved, (slot.item as ItemDefinition).display_name] if moved > 0 else "Backpack full — supplies remain in the train")
		return moved
	if carried != null or not player.is_grounded() or player._mode != Player.Mode.LOCOMOTION:
		notice.emit("Heavy cargo needs free hands and firm footing")
		return 0
	_transaction = true
	var world := spawn_world(slot.item, 1, player.global_position)
	var moved := inventories.storage.remove_at(index, 1) if world != null else 0
	if moved == 1:
		_hold(world)
	elif world != null:
		world.retire()
	_transaction = false
	return moved


func reset_world() -> void:
	cancel_search(false)
	for world in world_items:
		if is_instance_valid(world):
			world.retire()
	world_items.clear()
	carried = null
	player.carrying_heavy = false
	carrying_changed.emit(null)
	for cache in containers:
		cache.reset_loot(loot_seed)


func reset_loose_train_cargo(train: Train) -> void:
	for world in world_items:
		if is_instance_valid(world) and world.available and is_instance_valid(world.resting_body):
			var car := world.resting_body
			var local := car.to_local(world.global_position)
			world.reset_on_train(train.get_rest_transform(car) * local + Vector3.UP * 0.02)


func register_container(cache: SearchContainer) -> void:
	if containers.has(cache):
		return
	containers.append(cache)
	cache.action = func(who: Player) -> bool: return use_container(who, cache)
	cache.reset_loot(loot_seed)
