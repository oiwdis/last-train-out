extends "res://tools/capture_milestone26.gd"
## Identical, unobstructed cameras for the second M2.6 environment pass.
## The older freight evidence camera sat inside Warehouse B's front detailing.

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
	await shot("01_platform", Vector3(26,1.05,0.5), Vector3(26,2.65,0.5), Vector3(17,2.1,2.8), 78, false)
	await shot("02_waiting_hall", Vector3(16,0.05,6), Vector3(24,2.1,5), Vector3(14,2.1,10), 68, false)
	await shot("03_station_house", Vector3(12,1.05,0), Vector3(23,4.7,0), Vector3(12,4.7,-9), 68, false)
	await shot("04_warehouse_a", Vector3(36,0.05,1.1), Vector3(36,1.65,1.1), Vector3(47,2.3,1), 78, false)
	await shot("05_warehouse_b", Vector3(74,0.05,3), Vector3(74,1.65,3), Vector3(83,1.6,2), 78, false)
	await shot("06_freight_yard", Vector3(101,0.05,6.6), Vector3(99,3.2,7.4), Vector3(114,2,9), 78, false)
	await shot("07_freight_car", Vector3(104,0.05,4.5), Vector3(100,2.8,5.8), Vector3(105,1.9,0.2), 68, false)
	await shot("08_container", Vector3(111,0.05,8), Vector3(112,1.7,8.5), Vector3(108,1.4,11.5), 68, false)
	var file := FileAccess.open(output.path_join("camera_poses" + ("_" + only if not only.is_empty() else "") + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(poses, "  "))
	file.close()
	RenderingServer.set_render_loop_enabled(false)
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	FabricatedMesh.clear_cache()
	get_tree().quit()
