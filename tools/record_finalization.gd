extends Node
## Scripted gameplay evidence. Explicit tour cuts, real E/V inputs and inventory ownership.
var game: Game
var view: ExplorationCamera
var output := "res://docs/screenshots/milestone26/finalization/tour"
var quality := 1

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--quality="):
			quality = clampi(int(argument.trim_prefix("--quality=")), 0, 2)
	_run.call_deferred()

func _run() -> void:
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	game.player.input.scripted = true
	view = game.camera_rig.exploration
	game.graphics.set_preset(quality)
	await _cut(Vector3(28,1.05,0.4), Vector3(32,2,0.4), 1, "Milestone 2.6 finalization / character and railway inspection")
	# The tour caption otherwise covers the face throughout this inspection shot.
	game.hud.show_message("", 0)
	view.set_process(false)
	var camera := game.camera_rig.get_camera()
	camera.global_position = Vector3(30.9,2.15,0.4)
	camera.look_at(Vector3(28,1.95,0.4))
	camera.fov = 46
	await _seconds(2.5)
	view.set_process(true)
	view.aim_at(game.player.global_position+Vector3(-8,1.3,0))
	game.hud.show_message("Walk / accelerate to sprint / jump and land",5)
	game.player.input.script_move(-1)
	await _seconds(2.0)
	game.player.input.script_move(-1,0,true)
	await _seconds(2.0)
	game.player.input.script_jump()
	await _seconds(.6)
	game.player.input.clear()
	await _seconds(.6)
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
	view.set_process(false)
	camera.global_position = loco.to_global(Vector3(1.5,1.15,-4.3))
	camera.look_at(loco.to_global(Vector3(.75,.7,0)))
	camera.fov = 60
	game.hud.show_message("Quartered rods and wheels / driven by train speed",3)
	for frame in 120:
		camera.global_position = loco.to_global(Vector3(1.5,1.15,-4.3))
		camera.look_at(loco.to_global(Vector3(.75,.7,0)))
		await get_tree().physics_frame
	view.set_process(true)
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
	game.supply_ui.close()
	await _cut(Vector3(74,0.05,3), Vector3(83,1.6,2), 1, "Tour cut / deteriorated Warehouse B")
	game.player.input.script_move(1)
	await _seconds(2)
	game.player.input.clear()
	await _cut(Vector3(103,0.05,7.4), Vector3(115,1.5,10.7), 0, "Tour cut / freight-yard maintenance route")
	await _seconds(2)
	var ladder := game.station.get_node("GantryLadder") as Ladder
	await _cut(ladder.to_global(Vector3(0,.05,.6)),ladder.to_global(Vector3(0,1.4,0)),1,"Tour cut / climb the manufactured gantry ladder")
	game.player.input.script_interact()
	await _seconds(.3)
	if not _check(game.player.state==Player.State.CLIMB,"E grabs the gantry ladder"):
		return
	game.player.input.script_move(0,-1)
	for frame in 240:
		await get_tree().physics_frame
		if game.player.global_position.y>3.79 and game.player._mode==Player.Mode.LOCOMOTION:
			game.player.input.clear()
			break
	if not _check(game.player.global_position.y>3.7,"climber reaches the gantry through its open rail gap"):
		return
	await _seconds(1)
	await _cut(Vector3(28,1.05,.4),Vector3(15,5,-17),0,"Harlow Junction / final environment")
	await _seconds(2)
	print("[tour-final] complete: camera switch, cab departure, moving interior walk, search, carry, drop/recovery and storage")
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	FabricatedMesh.clear_cache()
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
	print("[tour-final] %s %s" % ["PASS" if ok else "FAIL", text])
	if not ok:
		get_tree().quit(1)
	return ok
