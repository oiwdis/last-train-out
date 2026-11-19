class_name JourneySave
extends RefCounted
## JSON-only, bounded and validated before mutation. No objects or scripts in saves.
const VERSION := 1
const PATH := "user://harlow_escape_v1.json"

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high

static func integer(value: Variant, low: int, high: int) -> bool:
	return number(value,low,high) and float(value) == floor(float(value))

static func vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and number(value[0],-100000,100000) and number(value[1],-100000,100000) and number(value[2],-100000,100000)

static func pack(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

static func unpack(v: Array) -> Vector3:
	return Vector3(v[0],v[1],v[2])

static func inventory(model: InventoryModel) -> Array:
	var result := []
	for i in model.slot_count:
		var slot := model.get_slot(i)
		result.append({"item":str(slot.item.id),"amount":slot.amount} if not slot.is_empty() else {})
	return result

static func valid_inventory(data: Variant, model: InventoryModel) -> bool:
	if not data is Array or data.size() != model.slot_count:
		return false
	for slot in data:
		if not slot is Dictionary:
			return false
		if slot.is_empty():
			continue
		if not slot.get("item") is String:
			return false
		var item := ItemCatalog.find(slot.item)
		if item == null or (item.heavy and not model.allows_heavy) or not integer(slot.get("amount"),1,item.stack_limit):
			return false
	return true

static func restore_inventory(model: InventoryModel, data: Array) -> void:
	# Only called after whole-save validation. Preserve slot positions exactly.
	for i in model.slot_count:
		model._slots[i] = {} if data[i].is_empty() else {"item":ItemCatalog.find(data[i].item),"amount":int(data[i].amount)}
	model.changed.emit()

static func doors(game: Game) -> Dictionary:
	var result := {}
	for door in game.find_children("*","WorldDoor",true,false):
		var key: String = "train/%s/%s" % [door.get_parent().name,door.name] if door.get_parent() is TrainCar else "harlow/door/%.3f,%.3f,%.3f" % [door.global_position.x,door.global_position.y,door.global_position.z]
		result[key] = door
	return result

static func snapshot(journey: JourneyController) -> Dictionary:
	var g := journey.game
	var train := g.train
	var caches := {}
	for cache in g.scavenging.containers:
		caches[cache.cache_id] = {"searched":cache.is_searched,"slots":inventory(cache.contents)}
	var cargo := []
	for item in g.scavenging.world_items:
		if not is_instance_valid(item) or (not item.available and not item.held) or item.is_queued_for_deletion():
			continue
		var support := item.resting_body
		cargo.append({"id":item.persistent_id,"origin":item.origin_cache,"recorded":item.collection_recorded,"item":str(item.item.id),"amount":item.amount,"held":item.held,
			"position":pack(item.global_position),"velocity":pack(item.velocity),
			"car":str(support.name) if is_instance_valid(support) else "",
			"local":pack(support.to_local(item.global_position)) if is_instance_valid(support) else [0,0,0]})
	var actor := g.player
	var car := actor.get_ride_body() as TrainCar
	var door_states := {}
	var all_doors := doors(g)
	for id in all_doors:
		door_states[id] = all_doors[id].is_open
	return {"version":VERSION,"mission_id":journey.definition.id,"route":journey.route.signature(),
		"difficulty":g.fog_system.config.difficulty,"seed":str(g.fog_system.simulation.seed_value),
		"segment":journey.route.locate(train.distance).segment,"next_stop":journey.next_stop,
		"train":{"distance":train.distance,"speed":train.speed,"state":int(train.state),"mode":train.get_mode_index(),
			"profile":train._profile_time,"effective_speed":train._effective_max_speed,"max_speed":train.max_speed},
		"player":{"position":pack(actor.global_position),"facing":pack(actor.facing),"velocity":pack(actor.velocity),
			"car":str(car.name) if car != null else "","local":pack(car.to_local(actor.global_position)) if car != null else [0,0,0],
			"stamina":actor.stamina.current,"exhausted":actor.stamina.is_exhausted,"cooldown":actor.stamina._regen_cooldown},
		"backpack":inventory(g.inventory_system.backpack),"storage":inventory(g.inventory_system.storage),
		"item_serial":g.scavenging._item_serial,"containers":caches,"cargo":cargo,"doors":door_states,"mission":journey.mission.snapshot(),"fog":g.fog_system.snapshot()}

static func valid(j: JourneyController, d: Dictionary) -> bool:
	if d.get("version") != VERSION or d.get("mission_id") != j.definition.id or d.get("route") != j.route.signature():
		return false
	if not number(d.get("difficulty"),0.6,1.4) or not d.get("seed") is String or not d.seed.is_valid_int() or not integer(d.get("next_stop"),1,3):
		return false
	for key in ["train","player","containers","mission","fog"]:
		if not d.get(key) is Dictionary:
			return false
	var t: Dictionary = d.train
	for key in ["distance","speed","profile","effective_speed","max_speed"]:
		if not number(t.get(key),0,j.route.length()+1 if key == "distance" else 40):
			return false
	if t.max_speed < 0.5 or t.effective_speed < 0.5 or t.profile > 1 or not integer(t.get("state"),0,3) or not integer(t.get("mode"),0,j.game.train.departure_modes.size()-1):
		return false
	if t.distance > float(j.route.stations[j.stops[int(d.next_stop)]])+4:
		return false
	if d.get("segment") != j.route.locate(t.distance).segment:
		return false
	var p: Dictionary = d.player
	for key in ["position","facing","velocity","local"]:
		if not vector(p.get(key)):
			return false
	var cars := [""]
	for car in j.game.train.get_cars():
		cars.append(str(car.name))
	if p.get("car") not in cars or not number(p.get("stamina"),0,100) or not number(p.get("cooldown"),-1,10) or not p.get("exhausted") is bool:
		return false
	if not valid_inventory(d.get("backpack"),j.game.inventory_system.backpack) or not valid_inventory(d.get("storage"),j.game.inventory_system.storage):
		return false
	if d.containers.size() != j.game.scavenging.containers.size():
		return false
	for cache in j.game.scavenging.containers:
		var saved: Variant = d.containers.get(cache.cache_id)
		if not saved is Dictionary or not saved.get("searched") is bool or not valid_inventory(saved.get("slots"),expected_cache(cache,int(d.seed))):
			return false
	if not integer(d.get("item_serial"),0,10000000) or not d.get("cargo") is Array or d.cargo.size() > 1024:
		return false
	var held := 0
	var ids := {}
	for item in d.cargo:
		if not item is Dictionary or not item.get("item") is String or not item.get("id") is String or item.id == "" or ids.has(item.id):
			return false
		if not item.id.begins_with("supply_") or not item.id.trim_prefix("supply_").is_valid_int() or int(item.id.trim_prefix("supply_")) > d.item_serial:
			return false
		if not item.get("origin") is String or (item.origin != "" and not d.containers.has(item.origin)) or not item.get("recorded") is bool:
			return false
		ids[item.id] = true
		var definition := ItemCatalog.find(item.item)
		if definition == null or not integer(item.get("amount"),1,1 if definition.heavy else definition.stack_limit) or not item.get("held") is bool or item.get("car") not in cars:
			return false
		if item.held:
			held += 1
			if not definition.heavy or held > 1:
				return false
		for key in ["position","velocity","local"]:
			if not vector(item.get(key)):
				return false
	if not d.get("doors") is Dictionary or d.doors.size() != doors(j.game).size():
		return false
	for id in doors(j.game):
		if not d.doors.get(id) is bool:
			return false
	var mission := MissionState.new()
	if not mission.restore(d.mission):
		return false
	var config := j.definition.fog.duplicate() as FogConfig
	config.difficulty = d.difficulty
	var fog := FogSimulation.new(config,j.route,int(d.seed))
	var f: Dictionary = d.fog
	if f.get("version") != 1 or not f.get("simulation") is Dictionary or not f.get("players") is Dictionary or f.players.keys() != j.game.fog_system.players.keys():
		return false
	if not number(f.get("fuel"),0,config.fuel_capacity) or not number(f.get("remainder"),0,FogSimulation.STEP-0.000000001) or not fog.restore(f.simulation) or str(f.simulation.seed) != d.seed:
		return false
	for id in f.players:
		if not f.players[id] is Dictionary:
			return false
		var exposure := FogExposure.new()
		var ok := exposure.restore(f.players[id])
		exposure.free()
		if not ok:
			return false
	return true

static func expected_cache(cache: SearchContainer, seed_value: int) -> InventoryModel:
	var count := 1
	for entry in cache.loot_table.generate(seed_value ^ String(cache.cache_id).hash()):
		count += ceili(float(entry.amount)/maxi((entry.item as ItemDefinition).stack_limit,1))
	return InventoryModel.new(count,true)

static func write_file(j: JourneyController, path: String = PATH) -> String:
	if j.game.scavenging.active_search != null or j.game.player.is_attached() or not j.game.player.is_grounded():
		return "Stand on the ground or a train floor and finish searching before saving."
	var data := snapshot(j)
	if not valid(j,data):
		return "Save validation failed; the previous save is intact."
	var file := FileAccess.open(path + ".tmp",FileAccess.WRITE)
	if file == null:
		return "Could not write the save file."
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(path+".tmp",path) != OK:
		return "Could not finish the save; the previous save is intact."
	return "Game saved · fog, cargo and route progress preserved."

static func read_file(path: String = PATH) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 4*1024*1024:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}

static func apply(j: JourneyController, d: Dictionary) -> bool:
	if not valid(j,d):
		return false
	var g := j.game
	var train := g.train
	j.set_physics_process(false)
	g.fog_system.set_physics_process(false)
	train.set_physics_process(false)
	g.scavenging.reset_world()
	j.next_stop = int(d.next_stop)
	j.mission.restore(d.mission)
	g.fog_system.config.difficulty = d.difficulty
	g.fog_system.simulation.config = g.fog_system.config
	g.fog_system.restore(d.fog)
	train.distance = d.train.distance
	train.speed = d.train.speed
	train.state = int(d.train.state) as Train.State
	train.set_mode_index(int(d.train.mode))
	train._profile_time = d.train.profile
	train._effective_max_speed = d.train.effective_speed
	train.max_speed = d.train.max_speed
	train._apply_positions(0)
	restore_inventory(g.inventory_system.backpack,d.backpack)
	restore_inventory(g.inventory_system.storage,d.storage)
	for cache in g.scavenging.containers:
		cache.contents = expected_cache(cache,int(d.seed))
		restore_inventory(cache.contents,d.containers[cache.cache_id].slots)
		cache.is_searched = d.containers[cache.cache_id].searched
		cache.refresh_prompt()
	var all_doors := doors(g)
	for id in all_doors:
		var door: WorldDoor = all_doors[id]
		door._stop_motion()
		door.is_open = d.doors[id]
		door._collider.set_deferred("disabled",door.is_open)
		door._panel.rotation.y = -PI/2 if door.is_open else 0
		door._align_target()
		door._update_prompt()
	g.player.suspend(8)
	for tick in 3:
		await g.get_tree().physics_frame
	for car in train.get_cars():
		car.reset_physics_interpolation()
	var at := unpack(d.player.position)
	if d.player.car != "":
		at = (train.get_node(d.player.car) as TrainCar).to_global(unpack(d.player.local))
	g.player.teleport_to(at,unpack(d.player.facing))
	g.player.suspend(3)
	g.player.stamina.current = d.player.stamina
	g.player.stamina.is_exhausted = d.player.exhausted
	g.player.stamina._regen_cooldown = d.player.cooldown
	for item in d.cargo:
		var where := unpack(item.position)
		if item.car != "":
			where = (train.get_node(item.car) as TrainCar).to_global(unpack(item.local))
		var world := g.scavenging.spawn_world(ItemCatalog.find(item.item),int(item.amount),where)
		world.persistent_id = item.id
		world.origin_cache = item.origin
		world.collection_recorded = item.recorded
		world.reset_on_train(where)
		world.velocity = unpack(item.velocity)
		if item.held:
			g.scavenging._hold(world)
	for tick in 3:
		await g.get_tree().physics_frame
	g.scavenging._item_serial = int(d.item_serial)
	g.scavenging.loot_seed = int(d.seed)
	g.player.velocity = unpack(d.player.velocity)
	train.set_physics_process(true)
	train.state_changed.emit(train.state)
	if train.is_moving():
		g._on_train_departure_started(train.current_mode)
	g.fog_system.set_physics_process(true)
	j.set_physics_process(true)
	return true
