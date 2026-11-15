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
