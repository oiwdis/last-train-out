extends Node
## Real scene/input scenarios. Setup/time cuts are explicitly captioned; the
## Warehouse B -> train escape has no teleports or fog edits once it starts.
var game: Game
var fog: FogSystem
var view: ExplorationCamera
var bot: RouteBot
var dose: FogExposure
var checks: Array[Dictionary] = []
var output := "res://docs/screenshots/milestone3"
var movie := false
var _failed := false

func _ready() -> void:
	movie = OS.has_feature("movie")
	_run.call_deferred()

func _run() -> void:
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await _seconds(0.2)
	game.player.input.scripted = true
	fog = game.fog_system
	fog.config.events_enabled = false
	view = game.camera_rig.exploration
	bot = RouteBot.new(game.player)
	dose = fog.players.local.exposure
	game.graphics.set_preset(0)
	view.request_perspective(0)
	_caption("A · Harlow Junction / ordinary scavenging", 5)
	await _walk([{"to": Vector3(13, 1, 1.2)}])
	await _search(&"platform_luggage")
	await _save("01_distant_scavenging")
	await _walk([{"to": Vector3(13, 1, 0.3)}, {"to": Vector3(27.2, 1, 0.3)}, {"to": Vector3(27.2, 1, 1.2)}])
	await _search(&"platform_locker")
	_check(game.inventory_system.backpack.used_slots() > 0 and dose.health == 100, "A: two real searches completed safely")
	await _seconds(1)
	# A labeled scenario cut avoids making viewers wait several minutes.
	await _cut(Vector3(98.2, 0.05, 1.45), Vector3(98.2, 1, 2.5), "B · SETUP CUT / Warehouse B, escape route now critical")
	fog.simulation.front = -14
	await _seconds(0.3)
	await _search(&"b_precision")
	await _save("02_critical_warehouse_b")
	_caption("Extra supplies secured. Now get back to the train.", 5)
	view.request_perspective(1)
	var health_before := dose.health
	await _walk(_return_route())
	await _walk([{"to": game.player.global_position, "then": "climb_up"}])
	_check(game.player.is_on_train(), "B: physically returned, vaulted and climbed onto train")
	await _save("03_last_second_boarding")
	var loco := game.train.get_node("Locomotive") as TrainCar
	await _walk([{"to": loco.to_global(Vector3(-2.7, 1.05, 0)), "sprint": false}])
	view.request_perspective(0)
	await _seconds(1)
	view.aim_at(loco.interior.controls[0].global_position)
	await _seconds(0.25)
	game.player.input.script_interact()
	await _seconds(2)
	print("[fog-gameplay] regulator: ", game.train.state, " player ", game.player.global_position, " health ", dose.health)
	_check(game.train.is_moving(), "B: cab regulator starts escape")
	_check(not dose.dead and dose.health <= health_before, "B: survived return while fog continued")
	_caption("F / G · Keep steam up. Exposure falls as we pull clear.", 7)
	view.request_perspective(1)
	view.aim_at(loco.global_position + Vector3(-14, 2, 4))
	await _seconds(14)
	await _save("04_departure_and_recovery")
	_check(fog.train_progress - fog.simulation.front > 70, "F: train outruns persistent front")
	_check(dose.exposure < 1, "G: exposure recovers after escape")
	await _seconds(10)
	_check(game.train.distance > 190, "F: sustained pursuit along baseline route")
	# Heavy cargo scenario, kept separate so no loot is injected into the escape.
	game.reset_station()
	await _seconds(0.2)
	await _cut(Vector3(57, 0.06, 2.85), Vector3(57, 0.8, 3.9), "C · SETUP CUT / coal reserve, heavy cargo decision")
	fog.simulation.front = -12
	await _search(&"a_coal")
	var cargo: WorldItem
	for item in game.scavenging.world_items:
		if item.item.id == &"coal_sack" and item.available:
			cargo = item
	_check(cargo != null, "C: searched reserve reveals actual coal")
	if cargo == null:
		_finish()
		return
	view.aim_at(cargo.global_position + Vector3.UP * 0.4)
	await _seconds(0.25)
	game.player.input.script_interact()
	await _seconds(0.5)
	_check(game.scavenging.carried == cargo, "C: reticle pickup holds coal sack")
	view.request_perspective(1)
	await _save("05_heavy_cargo_risk")
	game.player.input.script_move(-1, 0, true)
	await _seconds(1.2)
	_check(game.player.get_horizontal_speed() < 2.6, "C: heavy cargo caps movement")
	game.player.input.clear()
	game.scavenging.drop_heavy()
	_caption("Leave the coal. Free hands and sprinting may save the run.", 5)
	await _seconds(2)
	_check(cargo.available and game.scavenging.carried == null, "C: abandoned loot remains recoverable")
	game.reset_station()
	await _seconds(0.2)
	await _cut(loco.to_global(Vector3(-2.7, 1.05, 0)), loco.interior.controls[0].global_position, "D · SETUP CUT / nearly empty boiler")
	fog.simulation.front = -8
	fog.fuel.amount = 0.4
	game.player.input.script_interact()
	await _seconds(5)
	_check(fog.fuel.amount == 0 and not game.train.start(), "D: empty boiler prevents departure; fog advances")
	await _save("06_fuel_shortage")
	game.reset_station()
	await _seconds(0.2)
	await _cut(Vector3(19, 1.05, 0.6), Vector3(-15, 2.2, 0.6), "E · SETUP CUT / deliberately entering the front")
	fog.simulation.front = 5
	await _seconds(10)
	_check(dose.health < 100 and dose.exposure > 20, "E: deliberate exposure causes progressive damage")
	await _save("07_engulfed")
	_caption("Get clear of the boundary — recovery takes time.", 5)
	view.aim_at(Vector3(32, 2, 1))
	await _walk([{"to": Vector3(29, 1, 1), "sprint": true}, {"to": Vector3(33.9, 0, 1)}, {"to": Vector3(35.8, 0, 1.1)}, {"to": Vector3(46.6, 0, 1.1)}])
	await _seconds(9)
	_check(not dose.dead and dose.exposure < 1, "G: walking clear allows recovery")
	await _save("08_recovered")
	game.reset_station()
	await _seconds(0.2)
	fog.simulation.front = -25
	fog.trigger_surge()
	_caption("Surges always give ten seconds of advance warning.", 5)
	view.aim_at(Vector3(-30, 4, -3.5))
	await _seconds(3)
	await _save("09_surge_warning")
	_finish()

func _walk(steps: Array) -> void:
	for step: Dictionary in steps:
		var target: Vector3 = step.to
		if target.distance_to(game.player.global_position) > 1:
			view.aim_at(target + Vector3.UP * 1.5)
		var ok := await bot.run([step])
		_check(ok, "route: " + (bot.failure if not ok else str(target.snappedf(0.1))))
		if not ok:
			_failed = true
			_finish()
			return

func _search(id: StringName) -> void:
	for cache in game.scavenging.containers:
		if cache.cache_id == id:
			view.aim_at(cache.global_position + Vector3.UP * 0.65)
			await _seconds(0.2)
			game.player.input.script_interact()
			await _seconds(cache.search_seconds + 0.4)
			_check(cache.is_searched, "searched " + str(id) + " using E")
			return
	_check(false, "missing cache " + str(id))

func _cut(feet: Vector3, target: Vector3, caption: String) -> void:
	game.player.input.clear()
	game.player.teleport_to(feet)
	view.request_perspective(0)
	await _seconds(0.3)
	view.aim_at(target)
	_caption(caption, 5)
	await _seconds(1)

func _caption(text: String, duration: float) -> void:
	game.hud.show_message(text, duration)

func _seconds(duration: float) -> void:
	for i in ceili(duration * Engine.physics_ticks_per_second):
		await get_tree().physics_frame

func _save(title: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(title + ".png"))

func _check(ok: bool, label: String) -> void:
	checks.append({"passed": ok, "check": label})
	print("[fog-gameplay] %s %s" % ["PASS" if ok else "FAIL", label])
	_failed = _failed or not ok

func _finish() -> void:
	var file := FileAccess.open("res://docs/validation/milestone3/gameplay.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "headless": DisplayServer.get_name() == "headless", "checks": checks, "passed": not _failed}, "  "))
	get_tree().quit(1 if _failed else 0)

func _return_route() -> Array:
	return [
		{"to": Vector3(94.9, 0, 0.6)}, {"to": Vector3(93.4, 0, 1.5)},
		{"to": Vector3(91.7, 0, 1.5)}, {"to": Vector3(91.7, 0, 0)},
		{"to": Vector3(88.3, 0, 0.1)}, {"to": Vector3(87.4, 0, -0.75)},
		{"to": Vector3(86.5, 0, 0.2)}, {"to": Vector3(83, 0, -0.1)},
		{"to": Vector3(83, 0, 1.6)}, {"to": Vector3(81.6, 0, 2.2)},
		{"to": Vector3(78.9, 0, 2.2)}, {"to": Vector3(78.6, 0, 0.75)},
		{"to": Vector3(76.1, 0, 0.75)}, {"to": Vector3(74.3, 0, 3.3)},
		{"to": Vector3(71.3, 0, 2.6)}, {"to": Vector3(70.6, 0, 1.1)},
		{"to": Vector3(69.4, 0, 1.1)}, {"to": Vector3(65.3, 0, 1.5), "then": "interact"},
		{"to": Vector3(60.6, 0, 1.1)}, {"to": Vector3(58.6, 0, 1.1)},
		{"to": Vector3(54.8, 0, 1.1), "then": "interact"},
		{"to": Vector3(50.6, 0, 1.2)}, {"to": Vector3(49.7, 0, 3)},
		{"to": Vector3(47.3, 0, 3.3)}, {"to": Vector3(46.6, 0, 1.1)},
		{"to": Vector3(35.8, 0, 1.1)}, {"to": Vector3(33.9, 0, 1)},
		{"to": Vector3(29.6, 0, 1)}, {"to": Vector3(20.6, 0, -1.5), "then": "interact"}
	]
