class_name Game
extends Node3D
## Wires the long-lived gameplay objects together: player, train, camera, UI and
## the (placeholder) world systems. Each of those stays independent; this script
## is the only place that knows about all of them.

@export var player: Player
@export var train: Train
@export var camera_rig: CameraRig
@export var station: Station
## Used when there is no Station (test scenes).
@export var fallback_spawn: Marker3D
@export var debug_menu: DebugMenu
@export var hud: Hud

@export_group("Systems")
@export var fog_system: FogSystem
@export var passenger_system: PassengerSystem
@export var inventory_system: InventorySystem

@export_group("Camera")
## Wider framing used while the train is on the move.
@export var train_departure_profile: CameraProfile
@export var train_departure_priority := 5

## The player is reset when falling below this height.
@export var kill_plane_y := -25.0

const TRAIN_PROFILE_KEY := &"train_departure"

var scavenging: ScavengingSystem
var supply_ui: SupplyUI
var graphics: GraphicsSettings


func _exit_tree() -> void:
	FabricatedMesh.clear_cache()


func _ready() -> void:
	if station != null:
		var dressing := AssetDressing.new()
		dressing.name = "AuthoredAssets"
		station.add_child(dressing)
		dressing.build(station)
	var effects := PresentationEffects.new()
	effects.name = "PresentationEffects"
	add_child(effects)
	effects.bind(player)
	var audio := RailAudio.new()
	audio.name = "RailAudio"
	add_child(audio)
	audio.bind(player, train)
	if debug_menu != null:
		debug_menu.bind(player, train)
		debug_menu.train_start_requested.connect(start_train)
		debug_menu.train_stop_requested.connect(stop_train)
		debug_menu.train_reset_requested.connect(reset_train)
		debug_menu.departure_mode_selected.connect(set_departure_mode)
		debug_menu.max_speed_changed.connect(set_train_max_speed)
		debug_menu.player_reset_requested.connect(reset_player)
		debug_menu.stamina_reset_requested.connect(reset_stamina)
		debug_menu.station_reset_requested.connect(reset_station)
		debug_menu.fog_surge_requested.connect(trigger_fog_surge)
	if hud != null:
		hud.bind(player, train, station)
	if player != null and hud != null:
		player.grab_failed.connect(_on_player_grab_failed)
	if train != null:
		train.departure_started.connect(_on_train_departure_started)
		train.stopped.connect(_on_train_stopped)
	if fog_system != null:
		fog_system.surge_triggered.connect(_on_fog_surge_triggered)
	if passenger_system != null:
		passenger_system.passenger_state_changed.connect(_on_passenger_state_changed)
	if inventory_system != null:
		inventory_system.inventory_changed.connect(_on_inventory_changed)
		scavenging = ScavengingSystem.new()
		scavenging.name = "Scavenging"
		add_child(scavenging)
		scavenging.bind(player, inventory_system, station, train, self)
		if hud != null:
			scavenging.notice.connect(func(text: String) -> void: hud.show_message(text, 3.2))
	graphics = GraphicsSettings.new()
	graphics.name = "GraphicsSettings"
	add_child(graphics)
	graphics.bind(self, station.get_node_or_null("Atmosphere") as Atmosphere if station != null else null)
	if scavenging != null:
		supply_ui = SupplyUI.new()
		supply_ui.name = "SupplyUI"
		add_child(supply_ui)
		supply_ui.bind(scavenging, graphics)
	if camera_rig != null and camera_rig.exploration != null:
		for trigger in find_children("*", "CutawayTrigger", true, false):
			trigger.immersive = true
		if debug_menu != null:
			debug_menu.open_changed.connect(func(open: bool) -> void: camera_rig.exploration.set_menu_open(&"debug", open))
		if supply_ui != null:
			supply_ui.open_changed.connect(func(open: bool) -> void: camera_rig.exploration.set_menu_open(&"inventory", open))
			supply_ui.add_camera_settings(camera_rig.exploration)


func _physics_process(_delta: float) -> void:
	if player != null and player.global_position.y < kill_plane_y:
		reset_player()


# --- Train ---------------------------------------------------------------------

func start_train() -> void:
	if train == null:
		return
	if not train.start() and hud != null:
		hud.show_message("The train is at the end of the line  -  reset it first", 3.0)


func stop_train() -> void:
	if train != null:
		train.stop()


func set_departure_mode(index: int) -> void:
	if train != null:
		train.set_mode_index(index)


func set_train_max_speed(value: float) -> void:
	if train != null:
		train.max_speed = value


## Returns the train to the platform. A player who is aboard travels with it.
func reset_train() -> void:
	if train == null:
		return
	if scavenging != null:
		scavenging.cancel_search(false)
		scavenging.reset_loose_train_cargo(train)
	if supply_ui != null:
		supply_ui.close()
	var ride := player.get_ride_body() as TrainCar if player != null else null
	var standing_aboard := ride != null and not player.is_attached()
	var local_offset := Vector3.ZERO
	if standing_aboard:
		local_offset = ride.to_local(player.global_position)
	train.reset_to_station()
	if player == null:
		return
	if standing_aboard:
		# The car reaches the station on the next physics step, so place the
		# player where it will be and hold them still until it has arrived.
		player.teleport_to(train.get_rest_transform(ride) * local_offset + Vector3.UP * 0.02, player.facing)
		player.suspend(3)
	elif not player.is_attached() and train.is_point_in_rest_footprint(player.global_position):
		# Standing where the train is about to reappear: step aside.
		reset_player()


# --- Player --------------------------------------------------------------------

func reset_player() -> void:
	if player == null:
		return
	if scavenging != null:
		scavenging.cancel_search(false)
	if supply_ui != null:
		supply_ui.close()
	player.teleport_to(get_spawn_position())


func reset_stamina() -> void:
	if player != null:
		player.stamina.reset()


func get_spawn_position() -> Vector3:
	if station != null:
		return station.get_player_spawn_position()
	if fallback_spawn != null:
		return fallback_spawn.global_position
	return Vector3.ZERO


# --- Station -------------------------------------------------------------------

## Puts the train, the player and the environment back to their starting state.
func reset_station() -> void:
	if scavenging != null:
		scavenging.reset_world()
	if train != null:
		train.reset_to_station()
		for car in train.get_cars():
			if car.interior != null:
				for door in car.interior.doors:
					door.reset_state()
	reset_player()
	reset_stamina()
	if station != null:
		station.reset_state()
	if fog_system != null:
		fog_system.reset()
	if passenger_system != null:
		passenger_system.reset()
	if inventory_system != null:
		inventory_system.reset()
	if hud != null:
		hud.show_message("Station reset")


func trigger_fog_surge() -> void:
	if fog_system != null:
		fog_system.trigger_surge()
	else:
		print("[Game] Fog surge requested, but this scene has no FogSystem.")


# --- Signal handlers -----------------------------------------------------------

func _on_train_departure_started(_mode: DepartureMode) -> void:
	if camera_rig == null:
		return
	if train_departure_profile != null:
		camera_rig.push_profile(TRAIN_PROFILE_KEY, train_departure_profile, train_departure_priority)
	camera_rig.set_interest_source(train)


func _on_train_stopped() -> void:
	if hud != null and train.is_at_end_of_track():
		hud.show_message("End of the line  -  F1, then Reset entire station", 6.0)
	if camera_rig == null:
		return
	camera_rig.pop_profile(TRAIN_PROFILE_KEY)
	camera_rig.set_interest_source(null)


func _on_player_grab_failed(reason: String) -> void:
	if reason == "too_fast":
		hud.show_message("Too fast to grab - match the train's speed", 1.6)
	elif reason == "hands_full":
		hud.show_message("Hands full — G to drop cargo before climbing or vaulting", 2.5)


func _on_fog_surge_triggered(_intensity: float) -> void:
	if hud != null:
		hud.show_message("Fog surge triggered (placeholder)")


func _on_passenger_state_changed(passenger_id: StringName, state: PassengerSystem.PassengerState) -> void:
	print("[Game] Passenger %s -> %s" % [passenger_id, PassengerSystem.PassengerState.keys()[state]])


func _on_inventory_changed(item_id: StringName, amount: int) -> void:
	print("[Game] Inventory %s = %d" % [item_id, amount])
