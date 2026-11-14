extends Node
## Scripted evidence tour: real interactions, with explicit teleports between tour locations.
## --fast disables intermediate drawing for screenshots. Never use --fast with Movie Maker.

var _game: Game
var _out := "res://docs/screenshots/milestone2"
var _fast := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--fast":
			_fast = true
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_run.call_deferred()


func _run() -> void:
	_game = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Game
	add_child(_game)
	_game.player.input.scripted = true
	_game.player.input.clear()
	await _seconds(0.5)
	_game.graphics.set_preset(1)
	if _fast:
		RenderingServer.set_render_loop_enabled(false)
	await _search(&"platform_luggage")
	await _search(&"a_toolbox", "01_search_warehouse_a.png")
	await _search(&"b_cabinet", "02_search_warehouse_b.png")
	_game.supply_ui.open()
	_game.supply_ui.select_slot(0)
	await _seconds(2)
	await _save("03_six_slot_inventory.png")
	_game.supply_ui.close()
	await _search(&"b_precision")
	var cargo: WorldItem
	for world in _game.scavenging.world_items:
		if is_instance_valid(world) and world.available and world.item.id == &"machine_component":
			cargo = world
	if cargo == null or not _game.scavenging.pick_up(_game.player, cargo):
		_fail("could not pick up discovered component")
		return
	_game.hud.show_message("Heavy cargo · 2.5 m/s · G drops it immediately", 5)
	await _seconds(1.5)
	_game.player.teleport_to(Vector3(27, 1.05, 0.4), Vector3.LEFT)
	_game.hud.show_message("Tour cut / return to the platform with the component", 3)
	await _seconds(1)
	await _save("04_heavy_carrying.png")
	_game.player.input.script_move(-1, 0, true)
	await _seconds(2.5)
	_game.player.input.clear()
	_game.scavenging.drop_heavy()
	await _seconds(0.7)
	await _save("05_dropped_cargo.png")
	_game.scavenging.pick_up(_game.player, cargo)
	await _seconds(1)
	_game.player.teleport_to(_game.scavenging.storage_point.global_position + Vector3(0, 0.05, 0.75), Vector3.FORWARD)
	await _seconds(1.7)
	_game.player.input.script_interact()
	await _seconds(1.3)
	if not _game.supply_ui.storage_mode:
		_fail("storage interaction did not open")
		return
	var deposited := _game.scavenging.deposit_all()
	await _seconds(1)
	await _save("06_train_storage.png")
	_game.supply_ui.selected_storage = &"machine_component"
	_game.supply_ui._withdraw_selected()
	await _seconds(1.3)
	_game.scavenging.deposit_all()
	await _seconds(0.7)
	_game.supply_ui.close()
	_game.player.teleport_to(Vector3(13, 1.05, 0.4))
	await _seconds(1.5)
	_game.graphics.set_preset(0)
	_game.hud.show_message("LOW / reduced 3D resolution, clear full-resolution HUD", 3)
	await _seconds(1)
	await _save("07_graphics_low.png")
	_game.graphics.set_preset(2)
	_game.hud.show_message("HIGH / native resolution and supported atmosphere", 3)
	await _seconds(1)
	await _save("08_graphics_high.png")
	_game.graphics.set_preset(1)
	print("[milestone2] finished; first deposit: %d supplies; storage: %s; backpack: %s" % [
		deposited, str(_game.inventory_system.storage.totals()), str(_game.inventory_system.backpack.totals())])
	get_tree().quit()


func _search(id: StringName, screenshot: String = "") -> void:
	var cache: SearchContainer
	for candidate in _game.scavenging.containers:
		if candidate.cache_id == id:
			cache = candidate
	if cache == null or not await _approach(cache):
		_fail("unreachable cache: %s" % id)
		return
	_game.hud.show_message("Tour / %s · E to search, move or Esc to cancel" % cache.title, 2.5)
	await _seconds(1.2)
	_game.player.input.script_interact()
	await _seconds(cache.search_seconds * 0.45)
	if _game.scavenging.active_search != cache:
		_fail("search did not start: %s" % id)
		return
	if screenshot != "":
		await _save(screenshot)
	await _seconds(cache.search_seconds * 0.6)
	if not cache.is_searched:
		_fail("search did not complete: %s" % id)
	await _seconds(0.6)


func _approach(cache: SearchContainer) -> bool:
	_game.player.input.clear()
	for offset: Vector3 in [Vector3(0, 0.03, 0.8), Vector3(-0.85, 0.03, 0), Vector3(0.85, 0.03, 0), Vector3(0, 0.03, -0.8), Vector3(-0.65, 0.03, -0.55), Vector3(0.65, 0.03, 0.55)]:
		var point := cache.global_position + offset
		if not _game.player.interactor.capsule_fits(point):
			continue
		_game.player.teleport_to(point, Vector3(-offset.x, 0, -offset.z).normalized())
		await _seconds(0.3)
		if _game.player.is_grounded() and cache.can_interact(_game.player) and _game.player._choose_interaction().get("interactable") == cache:
			return true
	return false


func _seconds(duration: float) -> void:
	for i in maxi(roundi(duration * Engine.physics_ticks_per_second), 1):
		await get_tree().physics_frame


func _save(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _fast:
		RenderingServer.set_render_loop_enabled(true)
	for i in 8:
		await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(_out.path_join(file_name))
	print("[milestone2] ", file_name, " ", error_string(result))
	if _fast:
		RenderingServer.set_render_loop_enabled(false)


func _fail(message: String) -> void:
	push_error("[milestone2] " + message)
	get_tree().quit(1)
