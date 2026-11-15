extends TestSuite
var game: Game
var fog: FogSystem
var dose: FogExposure

func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn", 8) as Game
	game.player.input.scripted = true
	fog = game.fog_system
	fog.config.events_enabled = false
	dose = fog.players.local.exposure

func after_each() -> void:
	await free_spawned()

func test_real_train_escapes_and_station_is_consumed() -> void:
	fog.simulation.front = -5
	var car := game.train.get_node("CrewCar") as TrainCar
	game.player.teleport_to(car.to_global(Vector3(0, 1.05, 0)))
	await seconds(0.5)
	game.train.set_mode_index(0)
	game.train.start()
	await seconds(20)
	check_greater(game.train.distance, 150, "existing train integrator drives escape")
	check_greater(fog.train_progress - fog.simulation.front, 130, "safe gap grows")
	check_greater(fog.simulation.front, 0, "station engulfed behind departing train")
	check(game.player.is_on_train(), "moving interior remains compatible")

func test_stationary_train_is_caught_and_damage_is_real() -> void:
	fog.simulation.front = -1
	await seconds(15)
	check_eq(fog.state, FogSystem.FogState.ENGULFED, "fog catches train")
	check_greater(dose.exposure, 20, "stationary player exposed")
	check_less(dose.health, 100, "health actually falls")

func test_cab_doors_and_roof_have_distinct_protection() -> void:
	var car := game.train.get_node("Locomotive") as TrainCar
	var point := car.to_global(Vector3(-2.7, 1.05, 0))
	check_near(fog.shelter_at(point).protection, fog.config.protection_building, 0.001, "open cab leaks")
	for door in car.interior.doors:
		door.is_open = false
	check_near(fog.shelter_at(point).protection, fog.config.protection_cab, 0.001, "closed cab strongest")
	check_near(fog.shelter_at(car.to_global(Vector3(-2.7, 3.8, 0)), true).protection, fog.config.protection_open, 0.001, "roof is exposed")
	check_near(fog.shelter_at(Vector3(80, 0.05, 2)).protection, fog.config.protection_building, 0.001, "warehouse leaks")
	check_near(fog.shelter_at(Vector3(80, 10, 2)).protection, 0, 0.001, "above warehouse roof unprotected")

func test_boarding_during_exposure_does_not_clear_dose() -> void:
	fog.simulation.front = 25
	dose.exposure = 60
	var car := game.train.get_node("Locomotive") as TrainCar
	for door in car.interior.doors:
		door.is_open = false
	game.player.teleport_to(car.to_global(Vector3(-2.7, 1.05, 0)))
	await seconds(1)
	check_greater(dose.exposure, 60, "boarding is not an exposure reset")
	check_near(dose.protection, fog.config.protection_cab, 0.001, "cab protection applied")

func test_leaving_moving_train_loses_shelter() -> void:
	var car := game.train.get_node("CrewCar") as TrainCar
	for door in car.interior.doors:
		door.is_open = false
	game.player.teleport_to(car.to_global(Vector3(0, 1.05, 0)))
	game.train.start()
	await seconds(2)
	check_near(dose.protection, fog.config.protection_passenger, 0.001, "moving crew car shelter")
	game.player.teleport_to(Vector3(20, 1.05, 1))
	await seconds(0.5)
	check_near(dose.protection, 0, 0.001, "leaving car loses protection")

func test_reversing_progress_reduces_gap() -> void:
	game.train.distance = 60
	await physics_frames(1)
	var forward := fog.train_progress
	game.train.distance = 10
	await physics_frames(1)
	check_near(forward - fog.train_progress, 50, 0.001, "route projection handles reversing distance without moving front")

func test_fog_during_search_preserves_loot_and_interaction() -> void:
	var cache := game.scavenging.containers[0]
	game.player.teleport_to(cache.global_position + Vector3(0, 0.04, -1))
	await seconds(0.5)
	check(game.scavenging.use_container(game.player, cache), "search begins")
	fog.simulation.front = dose.progress + 2
	await seconds(cache.search_seconds + 0.5)
	check(cache.is_searched, "fog does not cancel a live search")
	check_greater(game.inventory_system.backpack.used_slots(), 0, "supplies retained")
	check_greater(dose.exposure, 0, "searching does not pause exposure")
	check_eq(fog.survival_hud.layer, 45, "warning layer remains above inventory")

func test_heavy_cargo_keeps_existing_speed_risk() -> void:
	var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"), 1, game.player.global_position)
	game.scavenging.pick_up(game.player, cargo)
	check(game.player.carrying_heavy, "real cargo held")
	game.player.input.script_move(1, 0, true)
	await seconds(1)
	check_less(game.player.get_horizontal_speed(), 2.6, "heavy carry still limits speed")
	check(not game.player.is_sprinting(), "heavy carry still blocks sprint")
	check(game.scavenging.drop_heavy(), "abandoning cargo remains immediate")
	await seconds(1)
	check_greater(game.player.get_horizontal_speed(), 3, "dropping cargo helps escape")

func test_death_drops_cargo_and_restart_restores_controls() -> void:
	var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"), 1, game.player.global_position)
	game.scavenging.pick_up(game.player, cargo)
	dose.health = 0.1
	dose.exposure = 100
	fog.simulation.front = 100
	await seconds(0.3)
	check(dose.dead, "fog death")
	check(game.scavenging.carried == null and cargo.available, "cargo released exactly once")
	check_eq(game.player.process_mode, Node.PROCESS_MODE_DISABLED, "dead survivor cannot continue scavenging")
	game.reset_station()
	await seconds(0.3)
	check(not dose.dead, "new run alive")
	check_eq(game.player.process_mode, Node.PROCESS_MODE_INHERIT, "controls restored")
	check_near(dose.health, 100, 0.001, "health reset only on new run")

func test_fuel_shortage_brakes_and_requires_coal() -> void:
	fog.fuel.amount = 0.3
	game.train.start()
	await seconds(3)
	check_near(fog.fuel.amount, 0, 0.001, "fuel exhausted")
	check(not game.train.start(), "cannot restart empty boiler")
	check_greater(fog.simulation.front, -210, "fog keeps advancing during fuel failure")
	game.inventory_system.storage.add(ItemCatalog.find(&"coal_sack"), 1)
	check(fog.fuel.refuel(), "stored coal powers escape")
	check_eq(game.inventory_system.storage.count(&"coal_sack"), 0, "coal consumed once")
	check(game.train.start(), "refueled train starts")

func test_presets_do_not_change_simulation_or_exposure() -> void:
	var before := fog.simulation.snapshot()
	for index in 3:
		game.graphics.set_preset(index)
		check_eq(fog.simulation.snapshot(), before, "preset %d leaves gameplay unchanged" % index)
		check_eq(fog.presentation.layers.filter(func(layer: MeshInstance3D) -> bool: return layer.visible).size(), [2, 4, 6][index], "only front detail budget changes")

func test_first_and_third_person_preserve_same_threat() -> void:
	fog.simulation.front = 10
	var view := game.camera_rig.exploration
	view.request_perspective(0)
	await seconds(0.3)
	var before := dose.exposure
	view.request_perspective(1)
	await seconds(0.3)
	check_greater(dose.exposure, before, "perspective switching cannot evade dose")
	check_eq(view.perspective, 1, "third person still works")
	check(fog.survival_hud.status.text.contains("EXPOSURE"), "both perspectives share survival HUD")

func test_safe_escape_recovers_dose_but_not_health() -> void:
	dose.exposure = 70
	dose.health = 80
	await seconds(4)
	check_less(dose.exposure, 51, "safe recovery")
	check_near(dose.health, 80, 0.001, "no unearned healing")
	check_less(game.player.stamina.regen_multiplier, 1, "remaining exposure slows regeneration")

func test_world_snapshot_roundtrip_and_invalid_save_atomicity() -> void:
	dose.exposure = 65
	fog.simulation.request_event("surge")
	await seconds(2)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(fog.snapshot()))
	await seconds(1)
	check(fog.restore(saved), "world survival snapshot restores")
	check_near(dose.exposure, saved.players.local.exposure, 0.001, "dose persisted")
	check_near(fog.simulation.warning_left, saved.simulation.warning, 0.001, "surge countdown persisted")
	var bad := saved.duplicate(true)
	bad.players.local.health = -5
	var before := fog.snapshot()
	check(not fog.restore(bad), "bad actor data refused")
	check_eq(fog.snapshot(), before, "world restore atomic")

func test_individual_resets_do_not_reset_fog() -> void:
	fog.simulation.advance(50)
	var before := fog.simulation.front
	game.reset_train()
	game.reset_player()
	check_near(fog.simulation.front, before, 0.001, "teleports do not reset pursuit")

func test_station_transition_survives_live_event() -> void:
	fog.route = fog.route.duplicate(true)
	fog.route.stations["next"] = 300.0
	fog.simulation.route = fog.route
	fog.simulation.request_event("surge")
	await seconds(9)
	var front := fog.simulation.front
	check(fog.enter_station("next"), "station API accepts registered destination")
	await seconds(2)
	check_eq(fog.simulation.station_id, "next", "destination active")
	check_eq(fog.simulation.event, "surge", "surge starts through transition")
	check_greater(fog.simulation.front, front, "front never resets")
