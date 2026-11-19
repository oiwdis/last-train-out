class_name JourneyController
extends Node
## Single authority for arrival, objectives and persistence. Presentation only reads it.
static var pending_load: Dictionary = {}
static var next_seed := 3001
static var next_difficulty := 1.0
var game: Game
var definition: JourneyDefinition
var route: FogRoute
var stations: Array[JourneyStation] = []
var mission := MissionState.new()
var next_stop := 1
var stops: Array[String] = ["harlow","ashford","blackwater","escape"]
var ui: JourneyUI
var ready_to_play := false
var load_milliseconds := 0
var _started := 0

func setup(owner_game: Game, content: JourneyDefinition) -> void:
	_started = Time.get_ticks_msec()
	game = owner_game
	definition = content
	route = definition.build_route()
	game.train.route = route
	game.train.track_length = route.length()
	game.train.max_speed = definition.cruise_speed
	game.train._effective_max_speed = definition.cruise_speed
	game.fog_system.route = route
	game.fog_system.config = definition.fog.duplicate()
	game.fog_system.config.difficulty = next_difficulty
	game.fog_system.scenario_seed = next_seed
	game.fog_system.simulation = FogSimulation.new(game.fog_system.config,route,next_seed)
	game.fog_system.simulation.event_announced.connect(game.fog_system._event_notice)
	var far_end := game.station.get_node_or_null("Ground/BoundaryFarEnd")
	if far_end != null:
		far_end.queue_free()
	# The original line remains under Harlow; curved track starts before it ends.
	var line := game.station.get_node_or_null("MainLine")
	if line != null:
		line.queue_free()
	var track := RouteTrack.new()
	track.name = "RouteTrack"
	game.add_child(track)
	track.build(route,game.player)
	# Harlow retains its authored ground, with a short straight rail module.
	var home_track := Track.new()
	home_track.position = Vector3(-75,0,-3.5)
	home_track.length = 380
	game.add_child(home_track)
	for scene in definition.station_scenes:
		var station := scene.instantiate() as JourneyStation
		station.position = route.sample(float(route.stations[station.station_id]))
		game.add_child(station)
		stations.append(station)
	set_physics_process(false)

func bind() -> void:
	game.scavenging.loot_seed = game.fog_system.simulation.seed_value
	game.scavenging.reset_world()
	for station in stations:
		for cache in station.caches:
			game.scavenging.register_container(cache)
		for building in station.buildings:
			game.fog_system.shelters.append(building.shelter)
		if station.note != null:
			station.note.action = func(_who: Player) -> bool:
				mission.note_read = true
				game.hud.show_message("EVACUATION LOG: Eastbound relief is beyond the crossing. Take food and medicine. The fog follows the railway. Do not wait for the missing crew.",12)
				return true
	# Guaranteed introductory coal; original seeded Harlow caches stay intact.
	var cache := SearchContainer.new()
	cache.cache_id = "harlow_departure_coal"
	cache.title = "Departure coal reserve"
	cache.position = Vector3(5,1.02,2.5)
	cache.style = 2
	var table := LootTable.new()
	var entry := LootEntry.new()
	entry.item = ItemCatalog.find(&"coal_sack")
	table.entries.append(entry)
	table.rolls = 1
	cache.loot_table = table
	game.station.add_child(cache)
	game.scavenging.register_container(cache)
	game.scavenging.collected.connect(mission.record_supply)
	game.fog_system.fuel.refueled.connect(func() -> void:
		var id := current_station()
		if id in MissionState.STATIONS:
			mission.refuels[id] = int(mission.refuels.get(id,0)) + 1)
	game.inventory_system.backpack.add(ItemCatalog.find(&"bandages"),1)
	game.inventory_system.backpack.add(ItemCatalog.find(&"canned_food"),1)
	ui = JourneyUI.new()
	add_child(ui)
	ui.bind(self)
	ready_to_play = true
	load_milliseconds = Time.get_ticks_msec() - _started
	if not pending_load.is_empty():
		var saved := pending_load
		pending_load = {}
		await JourneySave.apply(self,saved)
		if mission.status != "active":
			ui.show_results()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not ready_to_play or mission.status != "active":
		return
	var train := game.train
	var target := float(route.stations[stops[next_stop]])
	if train.state != Train.State.STOPPED and train.state != Train.State.BRAKING and train.distance + train.get_braking_distance() >= target:
		train.stop()
	if next_stop < 3 and absf(train.distance - target) < 4 and train.state == Train.State.STOPPED:
		var id := stops[next_stop]
		if not mission.visited.has(id):
			mission.visited.append(id)
		game.fog_system.enter_station(id)
		next_stop += 1
		game.hud.show_message("Arrived at %s · fog is still advancing" % id.capitalize(),6)
	var dose: FogExposure = game.fog_system.players.local.exposure
	mission.peak_exposure = maxf(mission.peak_exposure,dose.exposure)
	if dose.exposure > 0:
		mission.exposure_seconds += delta
	mission.evaluate(train.distance,route.length(),not dose.dead,game.player.is_on_train())
	if mission.status != "active":
		ui.show_results()

func current_station() -> String:
	var progress := route.project(game.player.global_position)
	for id: String in MissionState.STATIONS:
		if absf(progress - float(route.stations[id])) < 210:
			return id
	return "en route"

func new_game(seed_value: int, difficulty: float) -> void:
	next_seed = seed_value
	next_difficulty = difficulty
	pending_load = {}
	get_tree().paused = false
	get_tree().reload_current_scene()

func continue_game() -> String:
	var data := JourneySave.read_file()
	if data.is_empty():
		return "No readable save found."
	if not JourneySave.valid(self,data):
		return "Save is incompatible or damaged; current journey is unchanged."
	pending_load = data
	next_seed = int(data.seed)
	next_difficulty = float(data.difficulty)
	get_tree().paused = false
	get_tree().reload_current_scene()
	return "Loading saved journey…"
