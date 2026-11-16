extends TestSuite
var game: Game
var worker: WorkerAnimator

func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn",8) as Game
	game.player.input.scripted = true
	game.player.input.camera_relative = false
	game.player.teleport_to(Vector3(12,1.05,.4),Vector3.RIGHT)
	worker = game.player.visual.get_node("RailWorker")
	await seconds(.6)

func after_each() -> void:
	await free_spawned()

func test_first_person_extraction_keeps_complete_hand_and_forearm_skin() -> void:
	var body := worker.model.find_child("WorkerSkin",true,false) as MeshInstance3D
	var hands := worker.model.find_child("FPHands",true,false) as MeshInstance3D
	var fp_vertices: Dictionary = {}
	for surface in hands.mesh.get_surface_count():
		var positions: PackedVector3Array = hands.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for point in positions:
			fp_vertices[point.snapped(Vector3.ONE*.00001)] = true
	var arm_binds: Dictionary = {}
	for bind in body.skin.get_bind_count():
		var title := String(body.skin.get_bind_name(bind))
		if title.contains("Hand") or title.contains("ForeArm"):
			arm_binds[bind] = true
	var checked := 0
	var missing := 0
	for surface in body.mesh.get_surface_count():
		var arrays := body.mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := bones.size()/positions.size()
		for index in positions.size():
			var arm_weight := 0.0
			for slot in stride:
				if arm_binds.has(bones[index*stride+slot]):
					arm_weight += weights[index*stride+slot]
			if arm_weight>.99:
				checked += 1
				if not fp_vertices.has(positions[index].snapped(Vector3.ONE*.00001)):
					missing += 1
	check_greater(checked,2000,"checks authored finger, palm, wrist and forearm vertices")
	check_eq(missing,0,"FP extraction cannot punch holes in fully arm-weighted skin")
	note("complete arm-weighted skin vertices retained: %d" % checked)

func test_cargo_wrists_reach_each_real_object_in_both_perspectives() -> void:
	for perspective in [1,0]:
		game.camera_rig.exploration.request_perspective(perspective)
		for item in [&"coal_sack",&"fuel_drum",&"machine_component"]:
			var cargo := game.scavenging.spawn_world(ItemCatalog.find(item),1,game.player.global_position+Vector3(.3,.05,0))
			check(game.scavenging.pick_up(game.player,cargo),"real hold transaction accepted")
			await seconds(.7)
			var rig := worker if perspective==1 else game.camera_rig.exploration._first_person_hands.get_node("FirstPersonWorker") as WorkerAnimator
			var pose := rig.pose_correction
			check_eq(pose.grip_targets.size(),2,"both grips resolved on the held WorldItem")
			for side in ["Left","Right"]:
				check_less(pose.rendered_tips[side+"arm"].distance_to(pose.grip_targets[side]),.075,"rendered wrist reaches "+String(item)+" in perspective "+str(perspective))
			check(game.scavenging.drop_heavy(),"pose solver preserves drop ownership")
			await seconds(.3)

func test_stance_contacts_hold_to_their_support_during_walk() -> void:
	game.player.input.script_move(1)
	var samples := 0
	var error := 0.0
	for frame in 100:
		await physics_frames(1)
		var pose := worker.pose_correction
		for side: String in pose.contacts:
			var contact: Dictionary = pose.contacts[side]
			if contact.weight>.98 and pose.rendered_tips.has(side+"leg"):
				samples += 1
				var target: Vector3 = contact.body.to_global(contact.local)
				error = maxf(error,pose.rendered_tips[side+"leg"].distance_to(target))
	check_greater(samples,8,"walking has measurable planted stance intervals")
	check_less(error,.04,"rendered ankle stays on its support during full-weight stance")
	note("fully planted samples=%d, max ankle contact error=%.4f m" % [samples,error])

func test_stationary_feet_follow_the_moving_car() -> void:
	var crew := game.train.get_node("CrewCar") as TrainCar
	game.player.teleport_to(crew.to_global(Vector3(0,1.05,0)))
	await seconds(.7)
	game.train.start()
	await seconds(1.5)
	check_greater(game.train.speed,.1,"support really moves")
	var pose := worker.pose_correction
	check_eq(pose.contacts.size(),2,"both idle feet retain contacts")
	for side: String in pose.contacts:
		var contact: Dictionary = pose.contacts[side]
		check_eq(contact.body,crew,"contact uses the moving car, not a world-space point")
		check_less(pose.rendered_tips[side+"leg"].distance_to(crew.to_global(contact.local)),.04,"ankle tracks car-local contact")

func test_running_gear_preserves_rod_length_and_quartering() -> void:
	for phase in range(32):
		var distance := phase*.13
		for side in [-1.0,1.0]:
			var pin := TrainMechanics.crank(distance,side,1)
			var slide := TrainMechanics.crosshead(pin)
			check_near(pin.distance_to(slide),TrainMechanics.CONNECTING_LENGTH,.0001,"slider-crank never stretches its rod")
			check_near(slide.y,TrainMechanics.AXLE_HEIGHT,.0001,"crosshead stays in cylinder guide")
		var left := TrainMechanics.crank(distance,-1,1)-Vector3(TrainMechanics.AXLES[1],TrainMechanics.AXLE_HEIGHT,-.81)
		var right := TrainMechanics.crank(distance,1,1)-Vector3(TrainMechanics.AXLES[1],TrainMechanics.AXLE_HEIGHT,.71)
		check_near(left.dot(right),0,.0001,"opposite cylinders are quartered")

func test_gauges_follow_start_brake_stop_and_speed_without_mutating_train() -> void:
	var art := game.train.get_node("Locomotive").find_children("*","TrainArt",true,false)[0] as TrainArt
	var mechanics := art.mechanics
	check_eq(mechanics.gauges.size(),3,"three independent live needles")
	game.train.start()
	await seconds(1)
	check_near(mechanics.gauge_values.x,game.train.speed/40.0,.01,"144 km/h dial uses actual speed")
	check_eq(mechanics.gauge_values.y,1.0,"regulator opens with departure command")
	game.train.stop()
	await seconds(.2)
	check_eq(mechanics.gauge_values.y,0.0,"regulator closes during braking")
	check_eq(mechanics.gauge_values.z,1.0,"brake dial reflects applied state")
	game.train.reset_to_station()
	await physics_frames(3)
	check_near(mechanics.gauge_values.x,0,.001,"speed needle returns to zero")
	check_near(mechanics.gauges[0].rotation.x,deg_to_rad(-130),.001,"zero speed points toward the printed zero on the left")
	check_near(mechanics.gauges[2].rotation.x,deg_to_rad(130),.001,"applied brake points toward 100 percent on the right")
	check_near(art._wheel_phase,0,.001,"visual crank resets with the train")

func test_planar_pbr_preserves_metres_normals_and_shared_materials() -> void:
	var source := preload("res://resources/materials/wall_brick.tres")
	var a := FabricatedMesh.box(Vector3(4,2,.2),source)
	var b := FabricatedMesh.box(Vector3(2,3,.2),source)
	var material := a.surface_get_material(0) as StandardMaterial3D
	check_eq(material,b.surface_get_material(0),"different dimensions reuse one material")
	check(not material.uv1_triplanar,"flat faces sample each PBR map once")
	check_eq(material.normal_texture,source.normal_texture,"authored scan retained")
	var arrays := a.surface_get_arrays(0)
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	check_greater(uv.size(),20,"baked UVs cover all faces and bevels")
	check_greater((arrays[Mesh.ARRAY_TANGENT] as PackedFloat32Array).size(),0,"normal mapping has a tangent basis")
	check_eq(a.get_aabb().size,Vector3(4,2,.2),"render optimization cannot resize the collision-aligned mesh")
	for index in 3:
		game.graphics.set_preset(index)
		check_eq(material.normal_enabled,index>0,"preset toggles cached projected material normals")
		for skin: StandardMaterial3D in game.graphics._materials:
			if skin.get_meta("skin_scattering_candidate",false):
				check(not skin.subsurf_scatter_enabled,"shipped presets avoid the expensive separate-specular path")
				check(not game.graphics._materials[skin].skin,"scene teardown cannot restore a transient SSS-enabled state")

func test_gantry_and_columns_keep_existing_traversal_volumes() -> void:
	var ladder := game.station.get_node("GantryLadder") as Ladder
	game.player.teleport_to(ladder.to_global(Vector3(0,.05,.42)),Vector3.FORWARD)
	await seconds(.3)
	check(ladder.can_interact(game.player),"detailed ladder remains reachable")
	check(ladder.interact(game.player),"ladder attaches the physical player")
	game.player.input.script_move(0,-1)
	for frame in 240:
		await physics_frames(1)
		if game.player.global_position.y>3.79 and game.player._mode==Player.Mode.LOCOMOTION:
			game.player.input.clear()
			break
	check_greater(game.player.global_position.y,3.7,"player climbs onto the open gantry deck")
	check_near((game.station.get_node("FreightYard/GantryDeck") as BoxPart).size.y,.2,.001,"deck collision kept")
	var pillar := game.station.get_node("WarehouseB/MainHall/HallPillarA") as BoxPart
	check_eq((pillar.shape as BoxShape3D).size,Vector3(.35,5.5,.35),"column collision stays authored size")
	check(pillar.get_node("BoltedSteelColumn") is MeshInstance3D,"close column has replacement steelwork")

func test_render_preparation_restores_camera_without_advancing_gameplay() -> void:
	var camera := game.get_viewport().get_camera_3d()
	var pose := camera.global_transform
	var player_at := game.player.global_position
	var train_at := game.train.global_position
	var speed := game.train.speed
	var was_paused := get_tree().paused
	var children := game.get_child_count()
	# Dummy rendering still exercises the camera/lifecycle contract. Real pipeline
	# timing and the entry route are checked separately on the native Mac renderer.
	await RenderWarmup.prepare(game)
	check_eq(game.get_viewport().get_camera_3d(),camera,"original camera remains current")
	check_eq(camera.global_transform,pose,"preparation never moves the gameplay camera")
	check_eq(game.player.global_position,player_at,"player is not teleported or simulated")
	check_eq(game.train.global_position,train_at,"train is not moved")
	check_eq(game.train.speed,speed,"train integrator is untouched")
	check_eq(get_tree().paused,was_paused,"preparation restores the previous pause state")
	check_eq(game.get_child_count(),children,"temporary camera and loading panel are removed")
