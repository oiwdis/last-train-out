class_name FogSystem
extends Node
## World authority adapter. Simulation can be advanced remotely later; presentation
## only reads it. Explicit player registration supports several independent doses.
signal fog_state_changed(state: FogState)
signal surge_triggered(intensity: float)
enum FogState { DISTANT, APPROACHING, CRITICAL, ENGULFED }
@export var config: FogConfig = preload("res://resources/fog/standard.tres")
# Resolve after script classes finish loading; Game/Train also reference FogRoute.
@export var route: FogRoute = load("res://resources/fog/harlow_route.tres")
@export var scenario_seed := 3001
var simulation: FogSimulation
var state := FogState.DISTANT
var surge_count := 0
var train_progress := 0.0
var players: Dictionary = {}
var shelters: Array[FogShelter] = []
var fuel: FogFuel
var presentation: FogPresentation
var survival_hud: FogHUD
var game: Game
var _accumulator := 0.0

func _ready() -> void:
	config = config.duplicate()
	simulation = FogSimulation.new(config, route, scenario_seed)
	simulation.event_announced.connect(_event_notice)
	set_physics_process(false)

func bind(owner_game: Game) -> void:
	game = owner_game
	register_player("local", game.player)
	_build_shelters()
	fuel = FogFuel.new()
	add_child(fuel)
	fuel.bind(game, config)
	survival_hud = FogHUD.new()
	add_child(survival_hud)
	survival_hud.bind(self, "local")
	presentation = FogPresentation.new()
	add_child(presentation)
	presentation.bind(self, "local")
	_add_clues()
	set_physics_process(true)

func register_player(id: String, player: Player) -> FogExposure:
	if players.has(id):
		return players[id].exposure
	var dose := FogExposure.new()
	dose.name = "FogExposure"
	player.add_child(dose)
	players[id] = {"player": player, "exposure": dose, "segment": ""}
	dose.died.connect(func() -> void: _on_death(id))
	return dose

func unregister_player(id: String) -> void:
	if not players.has(id):
		return
	var entry: Dictionary = players[id]
	if is_instance_valid(entry.exposure):
		entry.exposure.queue_free()
	players.erase(id)

func _physics_process(delta: float) -> void:
	_accumulator += delta
	while _accumulator + 0.00000001 >= FogSimulation.STEP:
		_accumulator = maxf(0, _accumulator - FogSimulation.STEP)
		simulation.step()
		_update_players(FogSimulation.STEP)
		if fuel != null:
			fuel.tick(FogSimulation.STEP)
	if game != null:
		# The existing controller supplies authoritative distance. Only this adapter
		# knows that the baseline train travels a straight authored segment.
		train_progress = game.train.distance if game.train.route == route else route.project(game.train.to_global(game.train.travel_direction.normalized() * game.train.distance))
		var danger := int(simulation.danger(train_progress))
		for entry: Dictionary in players.values():
			danger = maxi(danger, int(simulation.danger(entry.exposure.progress)))
		set_state(danger as FogState)

func _update_players(delta: float) -> void:
	for id in players.keys():
		var entry: Dictionary = players[id]
		var player := entry.player as Player
		if not is_instance_valid(player):
			players.erase(id)
			continue
		var dose := entry.exposure as FogExposure
		dose.progress = route.project(player.global_position, entry.segment)
		var cover := shelter_at(player.global_position, player.is_on_train())
		dose.shelter = cover.title
		dose.tick(delta, simulation.front - dose.progress, cover.protection, config)
		player.stamina.regen_multiplier = lerpf(1, config.minimum_regen_multiplier, dose.exposure / 100)
		player.survival_speed_multiplier = lerpf(1, config.minimum_movement_multiplier, clampf((dose.exposure - config.movement_penalty_threshold) / maxf(1, 100 - config.movement_penalty_threshold), 0, 1))

func shelter_at(point: Vector3, on_train: bool = false) -> Dictionary:
	for shelter in shelters:
		if is_instance_valid(shelter) and shelter.contains(point):
			return {"protection": shelter.protection(config), "title": shelter.title()}
	return {"protection": config.protection_open if on_train else 0.0, "title": "OPEN PLATFORM" if on_train else "OUTDOORS"}

func set_state(value: FogState) -> void:
	if state != value:
		state = value
		fog_state_changed.emit(state)

func trigger_surge(intensity: float = 1.0) -> void:
	if simulation.request_event("surge"):
		surge_count += 1
		surge_triggered.emit(clampf(intensity, 0, 1))

## A scene transition must call this, not reset(). Time/front/events keep advancing.
func enter_station(id: String) -> bool:
	return simulation.enter_station(id)

## Explicit new-run action only; individual train/player teleports do not reset danger.
func reset() -> void:
	simulation.reset()
	_accumulator = 0
	surge_count = 0
	set_state(FogState.DISTANT)
	if fuel != null:
		fuel.amount = config.initial_fuel
	for entry: Dictionary in players.values():
		entry.exposure.reset()
		entry.player.process_mode = Node.PROCESS_MODE_INHERIT
		entry.player.survival_speed_multiplier = 1.0
		entry.player.stamina.regen_multiplier = 1.0
		entry.player.input.blocked = false
	if game != null and game.camera_rig.exploration != null:
		game.camera_rig.exploration.set_menu_open(&"fog_failure", false)

func _on_death(id: String) -> void:
	var player := players[id].player as Player
	if game != null and player == game.player:
		game.scavenging.cancel_search(false)
		game.scavenging.drop_heavy()
		game.supply_ui.close()
		game.camera_rig.exploration.set_menu_open(&"fog_failure", true)
	player.input.clear()
	player.input.blocked = true
	player.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	player.process_mode = Node.PROCESS_MODE_DISABLED

func _event_notice(kind: String) -> void:
	if game != null and game.hud != null:
		game.hud.show_message({"surge": "Fog surge building — return to the train", "calm": "The wind is falling — a brief calm is coming", "dense": "A dense front is gathering — visibility will fall", "disturbance": "Metal echoes from inside the fog"}[kind], config.event_warning_seconds)

func _build_shelters() -> void:
	for car in game.train.get_cars():
		if car.name == "FlatCar":
			continue
		var shelter := FogShelter.new()
		shelter.kind = 0 if car.name == "Locomotive" else 1
		shelter.bounds = AABB(Vector3(-4.1, 0.85, -1.15), Vector3(2.9, 2.35, 2.3)) if shelter.kind == 0 else AABB(Vector3(-3.3, 0.85, -1.15), Vector3(6.6, 2.35, 2.3))
		car.add_child(shelter)
		shelter.doors = car.interior.doors
		shelters.append(shelter)
	for spec in [["WarehouseA", 24.0, 7.0], ["WarehouseB", 29.0, 6.8]]:
		var building := game.station.get_node_or_null(spec[0])
		if building != null:
			var shelter := FogShelter.new()
			shelter.bounds = AABB(Vector3(0.5, 0, -1), Vector3(spec[1], spec[2], 5.4))
			building.add_child(shelter)
			shelters.append(shelter)

func _add_clues() -> void:
	for spec in [[Vector3(28, 1.02, 1.5), "Dispatch note: It follows the rails. Keep steam up. Closed doors buy time, not safety."], [Vector3(78, 0.05, 2.7), "Warehouse log: The grey took the west platform first. We heard a train inside it. There was no train."]]:
		var clue := SupplyInteractable.new()
		clue.position = spec[0]
		clue.prompt = "Read fog dispatch"
		clue.action = func(_who: Player) -> bool:
			game.hud.show_message(spec[1], 9)
			return true
		game.station.add_child(clue)
		var label := Label3D.new()
		label.text = "DISPATCH NOTE"
		label.position.y = 0.5
		label.pixel_size = 0.004
		label.font_size = 24
		label.modulate = RailTheme.AMBER
		clue.add_child(label)

## Serializable world survival state; a future world save also stores train,
## inventory and actor transforms. This API does not pretend to save those systems.
func snapshot() -> Dictionary:
	var doses := {}
	for id in players:
		doses[id] = players[id].exposure.snapshot()
	return {"version": 1, "simulation": simulation.snapshot(), "players": doses,
		"fuel": fuel.amount if fuel != null else 0, "remainder": _accumulator}

func restore(data: Dictionary) -> bool:
	if not (data.get("version") is int or data.get("version") is float):
		return false
	if data.version != 1 or not data.get("simulation") is Dictionary or not data.get("players") is Dictionary:
		return false
	for key in ["fuel", "remainder"]:
		if not data.has(key) or not (data[key] is int or data[key] is float) or not is_finite(float(data[key])):
			return false
	if data.fuel < 0 or data.fuel > config.fuel_capacity or data.remainder < 0 or data.remainder >= FogSimulation.STEP:
		return false
	if data.players.size() != players.size():
		return false
	for id in players:
		if not data.players.has(id) or not data.players[id] is Dictionary:
			return false
		var validator := FogExposure.new()
		var valid := validator.restore(data.players[id])
		validator.free()
		if not valid:
			return false
	if not simulation.restore(data.simulation):
		return false
	_accumulator = data.remainder
	if fuel != null:
		fuel.amount = data.fuel
	for id in players:
		players[id].exposure.restore(data.players[id])
		players[id].player.process_mode = Node.PROCESS_MODE_INHERIT
		players[id].player.input.blocked = false
		if players[id].exposure.dead:
			_on_death(id)
	if game != null:
		game.camera_rig.exploration.set_menu_open(&"fog_failure", players.local.exposure.dead)
	_update_players(0)
	return true
