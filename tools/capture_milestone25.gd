extends Node
## Real rendered views. Teleports between locations are explicit tour cuts.
var game: Game
var view: ExplorationCamera
var output := "res://docs/screenshots/milestone25"
var quality := 2
var only := ""

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			output = argument.trim_prefix("--out=")
		elif argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
		elif argument.begins_with("--quality="):
			quality = clampi(int(argument.trim_prefix("--quality=")), 0, 2)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	_run.call_deferred()

func _run() -> void:
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	game.player.input.scripted = true
	view = game.camera_rig.exploration
	game.graphics.set_preset(quality)
	RenderingServer.set_render_loop_enabled(false)
	await _shot("01_first_person_platform", Vector3(26,1.05,0.5), Vector3(23,2.1,-3.5), 0)
	await _shot("02_third_person_train", Vector3(18,1.05,0.5), Vector3(24,2,-3.5), 1)
	await _shot("03_crew_interior", Vector3(13,1.05,-3.5), Vector3(18,2.5,-3.5), 0)
	await _shot("04_cab_controls", Vector3(21,1.05,-3.5), Vector3(22.5,2.2,-3.5), 0)
	await _shot("05_warehouse_a", Vector3(36,0.05,1.1), Vector3(47,2.3,1), 0)
	await _shot("06_warehouse_b", Vector3(74,0.05,3), Vector3(83,1.6,2), 0)
	await _shot("07_freight_yard", Vector3(101,0.05,6.6), Vector3(114,2,9), 1)
	await _shot("08_waiting_hall", Vector3(15,0.05,9), Vector3(21,1.9,14.5), 0)
	if only == "" or only in "09_camera_inventory_settings":
		game.supply_ui.open()
		await _save("09_camera_inventory_settings")
	print("[capture25] complete")
	get_tree().quit()

func _shot(title: String, feet: Vector3, target: Vector3, perspective: int) -> void:
	if only != "" and only not in title:
		return
	game.player.teleport_to(feet, (target-feet).normalized())
	view.request_perspective(perspective)
	for i in 80:
		await get_tree().physics_frame
	view.aim_at(target)
	for i in 5:
		await get_tree().process_frame
	await _save(title)

func _save(title: String) -> void:
	RenderingServer.set_render_loop_enabled(true)
	for i in 4:
		await RenderingServer.frame_post_draw
	var path := output.path_join(title + ".png")
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("[capture25] %s %s" % [path, error_string(error)])
	RenderingServer.set_render_loop_enabled(false)
