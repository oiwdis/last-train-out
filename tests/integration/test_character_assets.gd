extends TestSuite
var game: Game
var player: Player
var worker: WorkerAnimator
var view: ExplorationCamera

func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn", 8) as Game
	player = game.player
	player.input.scripted = true
	player.input.camera_relative = false
	player.teleport_to(Vector3(10,1.05,0.4), Vector3.RIGHT)
	worker = player.visual.get_node("RailWorker") as WorkerAnimator
	view = game.camera_rig.exploration
	await seconds(0.5)

func after_each() -> void:
	await free_spawned()

func test_authored_character_has_weighted_humanoid_and_individual_fingers() -> void:
	check_eq(worker.skeleton.get_bone_count(), 52, "weighted humanoid skeleton imported")
	var fingers := 0
	for i in worker.skeleton.get_bone_count():
		var name := worker.skeleton.get_bone_name(i)
		if "Hand" in name and name.ends_with("3"):
			fingers += 1
	check_eq(fingers, 10, "each finger has three articulated bones")
	var skin := worker.model.find_child("WorkerSkin", true, false) as MeshInstance3D
	check(skin != null and skin.skin != null, "authored face and hands are skinned")
	check_greater(skin.mesh.surface_get_array_len(0), 3000, "detailed anatomical topology replaces primitive face")

func test_all_required_animation_clips_import_without_root_motion_tracks() -> void:
	for name in ["idle", "walk", "sprint", "jump", "fall", "land", "climb", "hang", "vault", "carry", "carry_walk", "pickup", "drop", "operate"]:
		check(worker.animation.has_animation(name), "animation exists: " + name)
		var clip := worker.animation.get_animation(name)
		check_greater(clip.length, 0.1, "clip has actual duration")
		check_greater(clip.get_track_count(), 20, "clip animates a skeleton")
		for track in clip.get_track_count():
			check(String(clip.track_get_path(track)).contains(":"), "animation affects bones, not the gameplay root")
	check(not worker.animation.has_animation("A_TPose"), "source rest-pose clip is not a gameplay state")

func test_real_movement_drives_blended_walk_sprint_and_idle() -> void:
	player.input.script_move(1)
	await seconds(0.5)
	check_eq(worker.current_state, &"walk", "walk state observes actual relative movement")
	check_greater(worker.animation.speed_scale, 1, "cycle playback tracks movement speed")
	player.input.script_move(1, 0, true)
	await seconds(0.5)
	check_eq(worker.current_state, &"sprint", "sprinting selects running animation")
	player.input.clear()
	await seconds(0.6)
	check_eq(worker.current_state, &"idle", "stopping blends back to breathing")

func test_jump_and_traversal_states_have_distinct_skeletal_presentations() -> void:
	player.input.script_jump()
	await physics_frames(3)
	check_eq(worker.current_state, &"jump", "actual jump selects takeoff")
	for pair in [[Player.State.FALL, &"fall"], [Player.State.CLIMB, &"climb"], [Player.State.HANG, &"hang"], [Player.State.VAULT, &"vault"]]:
		check_eq(WorkerAnimator.locomotion_clip(pair[0], false, 0), pair[1], "traversal state has a named animation")
	await seconds(1.6)
	check(player.is_grounded(), "animation never displaces the physical character")

func test_departing_train_does_not_make_stationary_passenger_walk() -> void:
	var crew := game.train.get_node("CrewCar") as TrainCar
	player.teleport_to(crew.to_global(Vector3(0,1.05,0)))
	await seconds(0.5)
	game.train.start()
	await seconds(2)
	check_greater(game.train.speed, 0.5, "train really moved")
	check_eq(worker.current_state, &"idle", "train world velocity is excluded from gait")

func test_first_person_renders_only_the_matching_arm_meshes() -> void:
	view.request_perspective(0)
	await seconds(0.5)
	var arms := view._first_person_hands.get_node("FirstPersonWorker") as WorkerAnimator
	check(not player.visual.visible, "full body and face are hidden at the eye")
	check(not view._first_person_hands.visible, "idle first-person view hides the shoulder cut surfaces")
	var visible := 0
	for mesh: MeshInstance3D in arms.model.find_children("*", "MeshInstance3D", true, false):
		check(mesh.visible == mesh.name.begins_with("FP"), "only the dedicated arm geometry renders")
		if mesh.visible:
			visible += 1
			check(mesh.skin != null, "first-person sleeves and fingers deform on the same rig")
	check_eq(visible, 2, "one authored skin mesh and one matching sleeve mesh")
	view.request_perspective(1)
	await seconds(0.6)
	check(not view._first_person_hands.visible and player.visual.visible, "perspective restores the full body")

func _cargo() -> WorldItem:
	var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"), 1, player.global_position + Vector3(0.4,0.1,0))
	await seconds(0.2)
	check(game.scavenging.pick_up(player, cargo), "real inventory transaction picks up cargo")
	await seconds(0.9)
	return cargo

func test_carry_pose_places_both_hands_at_cargo_in_both_perspectives() -> void:
	var cargo := await _cargo()
	for perspective in [1, 0, 1]:
		view.request_perspective(perspective)
		await seconds(0.5)
		var rig := worker if perspective == 1 else view._first_person_hands.get_node("FirstPersonWorker") as WorkerAnimator
		check_eq(rig.current_state, &"carry", "dedicated carry state is active")
		if perspective == 0:
			check(view._first_person_hands.visible, "carrying reveals the dedicated arm presentation")
			check_eq(rig.animation.current_animation, "fp_carry", "camera-specific carry clip keeps shoulders below the eye")
			for arm_name in ["mixamorig_LeftArm", "mixamorig_RightArm"]:
				var index := rig.skeleton.find_bone(arm_name)
				var shoulder := rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(index).origin)
				check_less(view.camera.to_local(shoulder).y, -0.15, "FP shoulder cuts stay below the eye instead of filling the screen")
		var centre := cargo.to_global(Vector3(0,0.36,0))
		for i in rig.skeleton.get_bone_count():
			if rig.skeleton.get_bone_name(i).ends_with("LeftHand") or rig.skeleton.get_bone_name(i).ends_with("RightHand"):
				var hand := rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(i).origin)
				check_less(hand.distance_to(centre), 0.43, "weighted hands reach the cargo, without floating away")
		check_eq(cargo.get_parent(), player.carry_anchor, "same object follows the active presentation anchor")
	check_eq(game.scavenging.world_items.size(), 1, "perspective changes never duplicate cargo")

func test_carry_walk_and_drop_animate_without_changing_ownership_rules() -> void:
	var cargo := await _cargo()
	player.input.script_move(1)
	await seconds(0.4)
	check_eq(worker.current_state, &"carry_walk", "walking preserves the two-hand grip")
	check_near(player.get_horizontal_speed(), 2.5, 0.04, "carrying speed remains unchanged")
	player.input.clear()
	check(game.scavenging.drop_heavy(), "drop commits immediately")
	check_eq(worker.current_state, &"drop", "successful drop triggers a skeletal action")
	await seconds(1)
	check(cargo.available and not cargo.held, "cargo remains recoverable after the animation")

func test_operating_controls_plays_action_and_keeps_train_command_immediate() -> void:
	var loco := game.train.get_node("Locomotive") as TrainCar
	player.teleport_to(loco.to_global(Vector3(-2.7,1.05,0)))
	await seconds(0.4)
	check(loco.interior.controls[0].interact(player), "regulator remains reachable")
	check_eq(game.train.state, Train.State.ACCELERATING, "control works immediately")
	check_eq(worker.current_state, &"operate", "control operation reaches the character rig")

func test_station_uses_batched_licensed_geometry_and_preserves_thirteen_caches() -> void:
	var dressing := game.station.get_node("AuthoredAssets") as AssetDressing
	check_greater(dressing.instance_count, 80, "authored models replace the old crate and shelving visuals")
	check_less(dressing.get_child_count(), dressing.instance_count, "repeated models are batched")
	check_eq(game.scavenging.containers.size(), 13, "all original scavenging sites remain")
	var crate := game.station.get_node("Platform/CrateA") as BoxPart
	check(not crate.show_mesh, "old blockout visual is removed")
	check_near((crate.shape as BoxShape3D).size.y, 0.9, 0.001, "vault collision height remains exact")

func test_imported_locomotive_wheels_turn_with_the_original_train_speed() -> void:
	var locomotive := game.train.get_node("Locomotive")
	var art := locomotive.find_children("*", "TrainArt", true, false)[0] as TrainArt
	check_greater(art._drive_wheels.size(), 5, "authored wheel assemblies load")
	var wheel := art._drive_wheels[0]
	var before := wheel.rotation.z
	game.train.start()
	await seconds(1)
	check(absf(wheel.rotation.z - before) > 0.05, "visual wheel rotation observes train speed")

func test_presets_restore_normal_maps_on_batched_assets() -> void:
	var dressing := game.station.get_node("AuthoredAssets")
	var multi := dressing.get_child(0) as MultiMeshInstance3D
	var material := multi.multimesh.mesh.surface_get_material(0) as StandardMaterial3D
	game.graphics.set_preset(2)
	check(material.albedo_texture != null and material.normal_texture != null, "authored UV maps import with materials")
	game.graphics.set_preset(0)
	check(not material.normal_enabled, "Low applies to MultiMesh props")
	check_near(get_viewport().mesh_lod_threshold, 4.0, 0.01, "Low selects generated LODs at a practical screen-space threshold")
	game.graphics.set_preset(1)
	check(material.normal_enabled, "Medium restores original normal maps")
	check_near(get_viewport().mesh_lod_threshold, 2.0, 0.01, "Medium balances mesh detail and distance")
