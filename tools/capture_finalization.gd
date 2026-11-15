extends "res://tools/capture_milestone26.gd"
## Three-way comparison: copy this and its parent to both detached baselines.
func _run() -> void:
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	game.player.input.scripted = true
	game.player.input.camera_relative = false
	game.graphics.set_preset(2)
	game.camera_rig.set_physics_process(false)
	game.camera_rig.exploration.set_process(false)
	game.camera_rig.exploration.request_perspective(1)
	for trigger in game.find_children("*","CutawayTrigger",true,false):
		trigger.set_deferred("monitoring",false)
	await get_tree().physics_frame
	_comparison_lighting()
	var feet := Vector3(28,1.02,.4)
	await shot("01_character_face",feet,feet+Vector3(.65,1.64,.08),feet+Vector3(0,1.59,0),46)
	await shot("02_character_front",feet,feet+Vector3(2.9,1.1,0),feet+Vector3(0,.9,0),46)
	await shot("03_character_side",feet,feet+Vector3(0,1.1,2.9),feet+Vector3(0,.9,0),46)
	await shot("04_character_rear",feet,feet+Vector3(-2.9,1.1,0),feet+Vector3(0,.9,0),46)
	for sprint in [false,true]:
		game.player.teleport_to(feet,Vector3.RIGHT)
		for rig in game.find_children("*","Node3D",true,false):
			if rig.has_method("play_action"):
				rig._action_remaining = 0
		game.player.input.script_move(1,0,sprint)
		await _simulate_frames(24)
		var at: Vector3 = game.player.global_position
		await _live_shot("06_sprinting" if sprint else "05_walking",at+Vector3(1.7,1.1,2.4),at+Vector3(0,.9,0),55)
		game.player.input.clear()
	game.player.teleport_to(feet,Vector3.RIGHT)
	await _simulate_frames(12)
	var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,feet+Vector3(.3,.05,0))
	game.scavenging.pick_up(game.player,cargo)
	await _simulate_frames(36)
	await _live_shot("07_heavy_carry",feet+Vector3(2.6,1.15,1.6),feet+Vector3(0,1,0),52)
	game.camera_rig.exploration.request_perspective(0)
	await _simulate_frames(36)
	await _live_shot("08_first_person_hands",feet+Vector3(0,1.6,0),feet+Vector3(7,1.3,-.9),78)
	game.scavenging.drop_heavy()
	game.camera_rig.exploration.request_perspective(1)
	await shot("09_locomotive",Vector3(18,1.05,.5),Vector3(30,4.4,3.9),Vector3(23,2,-3.5),64)
	game.train.start()
	await _simulate_frames(60)
	var offset: Vector3 = game.train.travel_direction*game.train.distance
	await _live_shot("10_moving_wheels",Vector3(26,1.05,-8.3)+offset,Vector3(24,.85,-3.5)+offset,65)
	game.train.reset_to_station()
	await shot("11_cab",Vector3(21,1.05,-3.5),Vector3(21,2.65,-3.5),Vector3(22.5,2.2,-3.5),78,false)
	await shot("12_crew",Vector3(13,1.05,-3.5),Vector3(13,2.65,-3.5),Vector3(18,2.5,-3.5),78,false)
	await shot("13_platform",Vector3(26,1.05,.5),Vector3(26,2.65,.5),Vector3(17,2.1,2.8),78,false)
	await shot("14_warehouse_a",Vector3(36,.05,1.1),Vector3(36,1.65,1.1),Vector3(47,2.3,1),78,false)
	await shot("15_warehouse_b",Vector3(74,.05,3),Vector3(74,1.65,3),Vector3(83,1.6,2),78,false)
	await shot("16_freight_yard",Vector3(101,.05,6.6),Vector3(101,2.5,6.6),Vector3(117,2.1,9),78,false)
	await shot("17_distant_environment",Vector3(28,1.05,.4),Vector3(28,3.8,5.7),Vector3(15,5,-17),78,false)
	var file := FileAccess.open(output.path_join("camera_poses"+("_"+only if not only.is_empty() else "")+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"preset":"High","lighting":"Shared final HDR, ambient, haze and SSAO; original scene fixtures retained","resolution":str(get_window().size),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"poses":poses},"  "))
	file.close()
	RenderingServer.set_render_loop_enabled(false)
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	FabricatedMesh.clear_cache()
	get_tree().quit()

func _live_shot(title: String, eye: Vector3, target: Vector3, fov: float) -> void:
	if not only.is_empty() and not title.contains(only):
		return
	# This capture owns camera placement, so perform the body visibility update
	# normally made by ExplorationCamera._place_camera in regular gameplay.
	game.player.visual.visible = not title.contains("first_person_hands")
	var camera := game.camera_rig.get_camera()
	camera.global_position = eye
	camera.look_at(target)
	camera.fov = fov
	for frame in 3:
		await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(output.path_join(title+".png"))
	poses.append({"name":title,"feet":str(game.player.global_position),"eye":str(eye),"target":str(target),"fov":fov,"player_speed":game.player.get_horizontal_speed(),"train_speed":game.train.speed})
	print("[capture-final] ",title," ",error_string(error))

func _simulate_frames(count: int) -> void:
	# Setup physics still executes normally; only unused intermediate renders are skipped.
	get_viewport().disable_3d = true
	for frame in count:
		await get_tree().physics_frame
	get_viewport().disable_3d = false

func _comparison_lighting() -> void:
	# A capture-only control: M2.5 originally used a solid night background.
	# Use the final outdoor lighting for every revision to compare the artwork.
	# The moon transform/energy and tonemapper are identical in all source scenes.
	var environment: Environment = game.station.get_node("Atmosphere").get_environment()
	var material := PanoramaSkyMaterial.new()
	material.panorama = load("res://assets/sky/kloofendal_overcast_puresky_1k.hdr")
	material.energy_multiplier = .55
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = .7
	environment.fog_density = .0025
	environment.fog_sky_affect = .18
	environment.ssao_enabled = true
	environment.ssao_radius = 1.0
	environment.ssao_intensity = 1.1
