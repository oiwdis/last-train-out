extends TestSuite

var game: Game


func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn") as Game
	game.player.input.scripted = true
	game.player.input.clear()
	await seconds(0.3)


func after_each() -> void:
	await free_spawned()


func test_keyboard_inventory_selection_drop_and_close() -> void:
	game.inventory_system.backpack.add(ItemCatalog.find(&"canned_food"), 6)
	await _action(&"inventory_toggle")
	check(game.supply_ui.is_open(), "Tab input opens ledger")
	check(game.player.input.blocked, "ledger prevents accidental movement")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_2
	key.pressed = true
	Input.parse_input_event(key)
	await physics_frames(2)
	check_eq(game.supply_ui.selected_slot, 1, "number key selects second stack")
	await _action(&"drop_item")
	check_eq(game.inventory_system.backpack.get_slot(1).amount, 1, "Q drops one from selected slot")
	await _action(&"debug_close")
	check(not game.supply_ui.is_open() and not game.player.input.blocked, "Esc closes ledger and restores control")


func test_mouse_slot_actions_and_tooltips_match_inventory() -> void:
	game.inventory_system.backpack.add(ItemCatalog.find(&"medicine"), 4)
	game.supply_ui.open()
	game.supply_ui._slots[1].pressed.emit()
	check_eq(game.supply_ui.selected_slot, 1, "clicking a slot selects it")
	check(game.supply_ui._slots[1].tooltip_text.contains("Medicine"), "tooltip identifies item")
	check(game.supply_ui._slots[1].tooltip_text.contains("kg"), "tooltip includes carrying information")
	check(game.supply_ui._icons[1].texture != null, "item icon is displayed")
	check(game.supply_ui._slot_labels[1].text.contains("1 / 3"), "stack amount and limit are displayed")


func test_graphics_presets_switch_render_features_without_touching_physics() -> void:
	var body_scale := game.player.scale
	var config := game.player.config
	var tick_rate := Engine.physics_ticks_per_second
	var train_speed := game.train.max_speed
	var environment := (game.station.get_node("Atmosphere") as Atmosphere).get_environment()
	var metal := preload("res://resources/materials/train_body.tres")
	game.graphics.set_preset(0)
	check(not metal.normal_enabled and metal.roughness_texture == null, "Low removes costly triplanar normal/roughness samples")
	check(not environment.volumetric_fog_enabled and not environment.glow_enabled, "Low disables expensive fog and bloom")
	check_eq(get_viewport().msaa_3d, Viewport.MSAA_DISABLED, "Low avoids MSAA")
	check_less(get_viewport().scaling_3d_scale, 0.66, "Low reduces 3D render resolution")
	for entry in game.graphics._lights:
		check(not (entry.light as Light3D).shadow_enabled, "Low disables shadow passes")
	game.graphics.set_preset(1)
	check(metal.normal_enabled and metal.roughness_texture != null, "Medium restores authored PBR maps")
	check(not environment.volumetric_fog_enabled and environment.glow_enabled, "Medium keeps readable depth haze and glow")
	game.graphics.set_preset(2)
	check_eq(get_viewport().msaa_3d, Viewport.MSAA_2X, "High restores antialiasing")
	check_near(get_viewport().scaling_3d_scale, 1, 0.001, "High renders at native scale")
	check(not environment.volumetric_fog_enabled, "unsupported headless fog still falls back safely")
	check_eq(game.player.scale, body_scale, "graphics never scales player physics")
	check_eq(game.player.config, config, "graphics leaves movement tuning untouched")
	check_eq(Engine.physics_ticks_per_second, tick_rate, "physics tick rate never changes")
	check_eq(game.train.max_speed, train_speed, "train mechanics are unchanged")


func test_train_storage_controls_refresh_immediately() -> void:
	game.player.teleport_to(game.scavenging.storage_point.global_position + Vector3(0, 0.05, 0.75), Vector3.FORWARD)
	await seconds(0.3)
	game.inventory_system.backpack.add(ItemCatalog.find(&"tools"), 2)
	game.scavenging.open_storage(game.player)
	game.supply_ui._deposit_all.pressed.emit()
	check(game.supply_ui._hold_heading.text.contains("2 SUPPLIES"), "storage quantity refreshes synchronously")
	check(game.supply_ui._storage_ids.has(&"tools"), "stored tools appear in ledger")
	game.supply_ui.selected_storage = &"tools"
	game.supply_ui._withdraw.pressed.emit()
	check_eq(game.inventory_system.backpack.count(&"tools"), 2, "withdraw button transfers stored stack")
	check(game.supply_ui._hold_heading.text.contains("0 SUPPLIES"), "withdrawal updates storage immediately")


func test_fullscreen_resolution_budget_uses_window_pixels_not_ui_coordinates() -> void:
	var window := get_window()
	var original := window.size
	window.size = Vector2i(2560, 1600)
	await physics_frames(2)
	game.graphics.set_preset(0)
	check_near(get_viewport().scaling_3d_scale, 720.0 / 1600.0, 0.001, "Low budgets a 1600-pixel-tall display to 720p")
	game.graphics.set_preset(1)
	check_near(get_viewport().scaling_3d_scale, 1080.0 / 1600.0, 0.001, "Medium budgets full-screen resolution to 1080p")
	window.size = original
	await physics_frames(2)


func _action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frames(2)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frames(1)
