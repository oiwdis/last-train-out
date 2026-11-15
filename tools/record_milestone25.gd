extends Node
## Scripted gameplay evidence. Explicit tour cuts, real E/V inputs and inventory ownership.
var game: Game
var view: ExplorationCamera
var output := "res://docs/screenshots/milestone25"

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	game.player.input.scripted = true
	view = game.camera_rig.exploration
	game.graphics.set_preset(1)
	await _cut(Vector3(22, 1.05, 0.5), Vector3(26, 2.1, -3.5), 1, "V / switch first and third person")
	await _seconds(1.6)
	await _switch()
	await _seconds(1.6)
	var loco := game.train.get_node("Locomotive") as TrainCar
	await _cut(loco.to_global(Vector3(-2.7, 1.05, 0)), loco.interior.controls[0].global_position, 0, "Tour cut / cab regulator starts departure")
	game.player.input.script_interact()
	await _seconds(1)
	if not _check(game.train.state == Train.State.ACCELERATING, "cab starts train"):
		return
	var crew := game.train.get_node("CrewCar") as TrainCar
	await _cut(crew.to_global(Vector3(-2, 1.05, 0)), crew.to_global(Vector3(2, 2.5, 0)), 0, "Tour cut / walk through the moving crew car")
	game.player.input.script_move(1)
	await _seconds(0.6)
	await _switch()
	await _seconds(0.6)
	game.player.input.clear()
	await _seconds(1)
	if not _check(game.player.is_on_train(), "walking passenger stays aboard"):
		return
	await _save("10_moving_train_third_person")
	await _switch()
	await _seconds(1)
	game.reset_station()
	await _seconds(0.2)
	await _search(&"a_toolbox", "11_search_first_person")
	await _search(&"a_coal", "")
	var cargo: WorldItem
	for item in game.scavenging.world_items:
		if item.item.id == &"coal_sack" and item.available:
			cargo = item
	if not _check(cargo != null, "search reveals coal sack"):
		return
	view.aim_at(cargo.global_position + Vector3.UP * 0.4)
	await _seconds(0.3)
	game.player.input.script_interact()
	await _seconds(0.5)
	if not _check(game.scavenging.carried == cargo, "reticle pickup holds discovered cargo"):
		return
	game.hud.show_message("Coal sack / visible cargo, 2.5 m/s, no sprint", 3)
	await _save("12_first_person_carrying")
	await _seconds(1)
	await _switch()
	await _seconds(1)
	await _save("13_third_person_carrying")
	await _cut(Vector3(27, 1.05, 0.4), Vector3(12, 2, 0.4), 1, "Tour cut / return with the same coal sack")
	game.player.input.script_move(-1, 0, true)
	await _seconds(1.7)
	game.player.input.clear()
	game.scavenging.drop_heavy()
	await _seconds(0.7)
	view.request_perspective(0)
	await _seconds(0.6)
	view.aim_at(cargo.global_position + Vector3.UP * 0.4)
	game.player.input.script_interact()
	await _seconds(0.5)
	if not _check(game.scavenging.carried == cargo, "dropped cargo can be recovered"):
		return
	var hold := game.scavenging.storage_point
	await _cut(hold.global_position + Vector3(0, 0.05, 0.75), hold.global_position + Vector3.UP * 0.65, 0, "Tour cut / secure backpack and physical cargo aboard")
	game.player.input.script_interact()
	await _seconds(0.3)
	if not _check(game.supply_ui.storage_mode, "camera target opens train hold while carrying"):
		return
	game.scavenging.deposit_all()
	await _seconds(1.5)
	await _save("14_supplies_secured")
	if not _check(game.inventory_system.storage.count(&"coal_sack") == 1, "exactly one discovered sack is stored"):
		return
	print("[tour25] complete: camera switch, cab departure, moving interior walk, search, carry, drop/recovery and storage")
	get_tree().quit()

func _search(id: StringName, screenshot: String) -> void:
	var cache: SearchContainer
	for candidate in game.scavenging.containers:
		if candidate.cache_id == id:
			cache = candidate
	await _cut(cache.global_position + Vector3(0, 0.04, -1.05), cache.global_position + Vector3.UP * 0.65, 0, "Tour cut / %s" % cache.title)
	game.player.input.script_interact()
	await _seconds(0.7)
	if screenshot != "":
		await _save(screenshot)
	await _seconds(cache.search_seconds)
	_check(cache.is_searched, "searched %s using E" % id)

func _cut(feet: Vector3, target: Vector3, perspective: int, caption: String) -> void:
	game.player.input.clear()
	game.player.teleport_to(feet, (target - feet).normalized())
	view.request_perspective(perspective)
	await _seconds(0.8)
	view.aim_at(target)
	game.hud.show_message(caption, 3)
	await _seconds(0.5)

func _switch() -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_V
		key.pressed = pressed
		Input.parse_input_event(key)
		Input.flush_buffered_events()
		await get_tree().process_frame

func _seconds(duration: float) -> void:
	for i in ceili(duration * Engine.physics_ticks_per_second):
		await get_tree().physics_frame

func _save(title: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(title + ".png"))

func _check(ok: bool, text: String) -> bool:
	print("[tour25] %s %s" % ["PASS" if ok else "FAIL", text])
	if not ok:
		get_tree().quit(1)
	return ok
