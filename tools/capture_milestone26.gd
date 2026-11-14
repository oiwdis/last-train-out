extends Node
## Fixed poses shared by the 2.5 baseline and 2.6 result. No quality-specific framing.
var game: Game
var output := "res://docs/screenshots/milestone26/after"
var poses: Array[Dictionary] = []
var only := ""

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			output = argument.trim_prefix("--out=")
		elif argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	_run.call_deferred()

func _run() -> void:
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	game.player.input.scripted = true
	game.graphics.set_preset(2)
	game.camera_rig.set_physics_process(false)
	game.camera_rig.exploration.set_process(false)
	game.camera_rig.exploration.request_perspective(1)
	for trigger in game.find_children("*", "CutawayTrigger", true, false):
		trigger.set_deferred("monitoring", false)
	await get_tree().physics_frame
	var feet := Vector3(28, 1.02, 0.4)
	await shot("01_character_front", feet, feet + Vector3(2.9,1.1,0), feet+Vector3(0,0.9,0), 46)
	await shot("02_character_side", feet, feet + Vector3(0,1.1,2.9), feet+Vector3(0,0.9,0), 46)
	await shot("03_character_rear", feet, feet + Vector3(-2.9,1.1,0), feet+Vector3(0,0.9,0), 46)
	await shot("04_character_face", feet, feet + Vector3(0.65,1.64,0.08), feet+Vector3(0,1.59,0), 46)
	await shot("05_character_hand", feet, feet + Vector3(0.5,0.87,0.75), feet+Vector3(0,0.8,0.32), 42)
	await shot("06_character_gameplay", feet, Vector3(24,3.1,3.1), feet+Vector3(0,1,0), 78)
	await shot("07_locomotive", Vector3(18,1.05,0.5), Vector3(30,4.4,3.9), Vector3(23,2,-3.5), 64)
	await shot("08_locomotive_detail", Vector3(18,1.05,0.5), Vector3(26,1.8,-0.8), Vector3(24.5,1.7,-3.4), 58)
	await shot("09_cab", Vector3(21,1.05,-3.5), Vector3(21,2.65,-3.5), Vector3(22.5,2.2,-3.5), 78, false)
	await shot("10_crew", Vector3(13,1.05,-3.5), Vector3(13,2.65,-3.5), Vector3(18,2.5,-3.5), 78, false)
	await shot("11_platform", Vector3(26,1.05,0.5), Vector3(26,2.65,0.5), Vector3(17,2.1,2.8), 78, false)
	await shot("12_warehouse_a", Vector3(36,0.05,1.1), Vector3(36,1.65,1.1), Vector3(47,2.3,1), 78, false)
	await shot("13_warehouse_b", Vector3(74,0.05,3), Vector3(74,1.65,3), Vector3(83,1.6,2), 78, false)
	await shot("16_running_gear", Vector3(24,0.05,-7), Vector3(26,1.05,-8.3), Vector3(24,0.85,-3.5), 65, false)
	await shot("14_freight_yard", Vector3(101,0.05,6.6), Vector3(99,3.2,4.9), Vector3(114,2,9), 78)
	if only.is_empty() or only in "15_first_person_hands":
		game.player.teleport_to(feet, Vector3.RIGHT)
		for i in 12:
			await get_tree().physics_frame
		var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"), 1, feet + Vector3(0.4,0.05,0))
		game.scavenging._hold(cargo)
		game.camera_rig.exploration.request_perspective(0)
		await shot("15_first_person_hands", feet, feet + Vector3(0,1.6,0), feet + Vector3(7,1.3,-0.9), 78, false)
	var file := FileAccess.open(output.path_join("camera_poses" + ("_" + only if not only.is_empty() else "") + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(poses, "  "))
	file.close()
	# Let deferred visual resources and action signals drain before renderer shutdown.
	RenderingServer.set_render_loop_enabled(false)
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	FabricatedMesh.clear_cache()
	get_tree().quit()

func shot(title: String, feet: Vector3, eye: Vector3, target: Vector3, fov: float, body := true) -> void:
	if not only.is_empty() and not title.contains(only):
		return
	game.player.teleport_to(feet, Vector3.RIGHT)
	game.player.visual.visible = body
	for i in 3:
		await get_tree().physics_frame
	if title.contains("character"):
		var worker := game.player.visual.get_node_or_null("RailWorker")
		if worker != null and worker.has_method("play_action"):
			worker.play_action(&"idle", 100)
			worker.animation.stop()
			worker.animation.play(&"idle", 0.0)
			worker.animation.seek(0, true)
			worker.animation.speed_scale = 0
	if title.contains("first_person_hands"):
		for worker in game.find_children("*", "Node3D", true, false):
			if worker.has_method("play_action"):
				worker.play_action(&"carry", 100)
				worker.animation.stop()
				worker.animation.play(&"fp_carry" if worker.first_person else &"carry", 0.0)
				worker.animation.seek(0.2, true)
				worker.animation.speed_scale = 0
	game.hud._message_time = 0
	game.hud._board_time = 0
	game.hud._message_panel.hide()
	var camera := game.camera_rig.get_camera()
	camera.global_position = eye
	camera.look_at(target)
	camera.fov = fov
	for i in 3:
		await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(output.path_join(title + ".png"))
	poses.append({"name": title, "feet": str(feet), "eye": str(eye), "target": str(target), "fov": fov})
	print("[capture26] ", title, " ", error_string(error))
