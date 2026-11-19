extends TestSuite
## Combined mission fixtures. Repositioning here is explicit test setup; the
## separately recorded journey uses continuous controls and zero teleports.
var game: Game
var worker: WorkerAnimator
var art: TrainArt

func before_each() -> void:
	JourneyController.pending_load = {}
	game = await spawn_scene("res://scenes/missions/harlow_escape.tscn",16) as Game
	game.player.input.scripted = true
	game.player.input.camera_relative = false
	worker = game.player.visual.get_node("RailWorker")
	art = game.train.get_node("Locomotive").find_children("*","TrainArt",true,false)[0]
	game.camera_rig.exploration.request_perspective(1)
	await seconds(.5)

func after_each() -> void:
	get_tree().paused = false
	await free_spawned()

func test_shipped_survival_scene_loads_both_real_rigs_and_locomotive() -> void:
	check(game.journey.ready_to_play,"real mission bound")
	check_greater(worker.skeleton.get_bone_count(),40,"authored skin is present")
	check(worker.model.find_child("WorkerSkin",true,false) is MeshInstance3D,"full skin loaded")
	var hands := game.camera_rig.exploration._first_person_hands.get_node("FirstPersonWorker") as WorkerAnimator
	check(hands.model.find_child("FPHands",true,false) is MeshInstance3D,"first person skinned arms retained")
	check(art.has_node("AuthoredLocomotive"),"licensed locomotive retained")
	check_eq(art.mechanics.rods.size(),8,"live rods and crossheads loaded")
	check(game.station.has_node("EnvironmentArt"),"Harlow architecture retained")
	check(game.station.has_node("AuthoredAssets"),"Harlow authored props retained")

func test_exposure_damage_slows_actual_gait_without_invalid_bones() -> void:
	game.player.teleport_to(Vector3(12,1.05,.4),Vector3.RIGHT)
	game.player.input.script_move(1)
	game.player.input.sprint_held = true
	await seconds(1)
	var healthy_speed := game.player.get_horizontal_speed()
	var healthy_cadence := worker._playback_rate
	var dose: FogExposure = game.fog_system.players.local.exposure
	dose.exposure = 95
	game.fog_system.simulation.front = 250
	await seconds(1.5)
	check_less(dose.health,100,"fog really damages the detailed survivor")
	check_less(game.player.get_horizontal_speed(),healthy_speed*.9,"controller applies survival penalty")
	check_less(worker._playback_rate,healthy_cadence,"animation follows reduced physical speed")
	check_eq(worker.current_state,&"sprint","injured sprint retains a valid locomotion clip")
	finite_rig()

func test_realistic_carry_grips_remain_valid_under_fog_in_both_views() -> void:
	game.fog_system.players.local.exposure.exposure = 80
	game.fog_system.simulation.front = 150
	var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,game.player.global_position)
	check(game.scavenging.pick_up(game.player,cargo),"coal ownership acquired")
	for mode in [1,0]:
		game.camera_rig.exploration.request_perspective(mode)
		await seconds(.7)
		var rig := worker if mode == 1 else game.camera_rig.exploration._first_person_hands.get_node("FirstPersonWorker") as WorkerAnimator
		check_eq(rig.current_state,&"carry","carry clip active under exposure")
		check_eq(rig.pose_correction.grip_targets.size(),2,"both grips resolved")
		for side in ["Left","Right"]:
			check_less(rig.pose_correction.rendered_tips[side+"arm"].distance_to(rig.pose_correction.grip_targets[side]),.09,"wrists remain on real sack")
	check(game.scavenging.drop_heavy(),"normal drop still owns one object")
	check_eq(game.scavenging.world_items.size(),1,"no duplicate from camera or damage")

func test_authored_locomotive_and_rods_follow_curves_and_grade() -> void:
	for distance in [850.0,1450.0,2700.0,3800.0]:
		await route_fixture(distance)
		var loco := game.train.get_node("Locomotive") as TrainCar
		var model := art.get_node("AuthoredLocomotive") as Node3D
		check_less(model.global_position.distance_to(loco.global_position),.001,"model remains attached to real body")
		check_near(model.global_basis.x.dot(loco.global_basis.x),1,.001,"render heading follows curved car")
		check_near(art._wheel_phase,game.train.distance,.001,"crank phase uses route arc metres")
		for rod in art.mechanics.rods:
			check((rod.mesh as Node3D).global_transform.is_finite(),"running gear finite at grade change")

func test_route_phase_and_gauges_survive_fuel_exhaustion_and_restart() -> void:
	await route_fixture(850)
	game.fog_system.fuel.amount = .25
	game.train.start()
	await seconds(9)
	check_eq(game.train.state,Train.State.STOPPED,"fuel shortage physically stops detailed train")
	check_near(art._wheel_phase,game.train.distance,.001,"stopped rods match stopping distance")
	check_near(art.mechanics.gauge_values.x,0,.001,"speed needle returns to zero")
	check_eq(art.mechanics.gauge_values.y,0.0,"regulator closed on empty boiler")
	check_eq(art.mechanics.gauge_values.z,1.0,"brake indicated")
	game.inventory_system.storage.add(ItemCatalog.find(&"coal_sack"),1)
	check(game.fog_system.fuel.refuel(),"collected storage fuel consumed")
	check(game.train.start(),"departure restored")
	await seconds(2)
	check_greater(game.train.speed,.2,"train accelerates")
	check_near(art._wheel_phase,game.train.distance,.2,"rods animate during acceleration")
	check_near(art.mechanics.gauge_values.x,game.train.speed/40,.01,"actual speed on instrument")
	check_eq(art.mechanics.gauge_values.y,1.0,"regulator open after refuel")

func test_saved_camera_cargo_and_art_restore_at_all_three_stations() -> void:
	var journey := game.journey
	for index in 3:
		var distance := float(journey.route.stations[journey.stops[index]])
		journey.next_stop = mini(index+1,3)
		await route_fixture(distance)
		var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,game.player.global_position)
		game.scavenging._hold(cargo)
		game.camera_rig.exploration.restore_view(index%2,-1.2,.21)
		var saved := snapshot()
		game.camera_rig.exploration.restore_view(1-index%2,1.1,-.5)
		check(await JourneySave.apply(journey,saved),"whole world restores at "+journey.stops[index])
		await seconds(.6)
		check_eq(game.camera_rig.exploration.perspective,index%2,"perspective recovered")
		check_near(game.camera_rig.exploration.yaw,-1.2,.001,"heading recovered")
		check_near(game.camera_rig.exploration.pitch,.21,.001,"pitch recovered")
		check_eq(game.scavenging.world_items.size(),1,"one restored cargo owner")
		check(game.player.is_on_train(),"rider remains on restored car")
		check_near(art._wheel_phase,game.train.distance,.01,"visual mechanism restored")
		check(worker._action_remaining <= 0,"load does not leave interaction action stuck")
		finite_rig()
		game.scavenging.reset_world()

func test_moving_save_restores_mechanism_camera_and_loose_supports() -> void:
	await route_fixture(860)
	var crew := game.train.get_node("CrewCar") as TrainCar
	game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,crew.to_global(Vector3(1,1.05,.5)))
	game.train.start()
	await seconds(4)
	game.camera_rig.exploration.restore_view(0,-.9,.1)
	var saved := snapshot()
	await seconds(2)
	check(await JourneySave.apply(game.journey,saved),"travel save applied")
	await seconds(1)
	check_eq(game.camera_rig.exploration.perspective,0,"cab perspective retained")
	check_near(art._wheel_phase,game.train.distance,.2,"rods synchronized after resumed motion")
	check_near(art.mechanics.gauge_values.x,game.train.speed/40,.01,"speed gauge synchronized")
	check(game.player.is_on_train(),"saved passenger stable on curve")
	check_less(crew.to_local(game.scavenging.world_items[0].global_position).length(),4,"saved loose cargo stays in moving car")

func test_camera_validation_is_atomic_and_original_m3_saves_still_load() -> void:
	var saved := snapshot()
	for camera in ["wrong",{}, {"perspective":2,"yaw":0,"pitch":0},{"perspective":0,"yaw":INF,"pitch":0},{"perspective":1,"yaw":0,"pitch":2}]:
		var bad := saved.duplicate(true)
		bad.camera = camera
		check(not await JourneySave.apply(game.journey,bad),"invalid camera rejected before mutation")
		check_eq(game.train.distance,saved.train.distance,"train intact")
	saved.erase("camera")
	game.camera_rig.exploration.request_perspective(0)
	check(await JourneySave.apply(game.journey,saved),"original v1 shape accepted")
	check_eq(game.camera_rig.exploration.perspective,0,"older save retains chosen perspective")

func test_render_preparation_covers_new_sites_and_fog_without_advancing_survival() -> void:
	var before := snapshot()
	var original := game.get_viewport().get_camera_3d()
	var children := game.get_child_count()
	check_greater(get_tree().get_nodes_in_group("render_warmup_view").size(),8,"added station views included")
	check_eq(get_tree().get_nodes_in_group("render_warmup_material").size(),1,"one actual fog shader representative")
	await RenderWarmup.prepare(game)
	check_eq(snapshot(),before,"loading cannot burn fuel, advance fog, move cargo or change camera")
	check_eq(game.get_viewport().get_camera_3d(),original,"gameplay eye restored")
	check_eq(game.get_child_count(),children,"all temporary nodes removed")
	get_tree().paused = true
	await RenderWarmup.prepare(game)
	check(get_tree().paused,"preset preparation preserves ledger pause")

func test_station_dressing_uses_shared_pbr_without_new_collision_owners() -> void:
	for station in game.journey.stations:
		var dressing := station.get_node("AuthoredStationDetails") as JourneyStationArt
		check_greater(dressing.instance_count,15,"reused props at "+station.station_id)
		check_eq(dressing.find_children("*","CollisionObject3D",true,false).size(),0,"dressing cannot seal routes")
		for mesh: MultiMeshInstance3D in dressing.find_children("*","MultiMeshInstance3D",true,false):
			check_eq(mesh.visibility_range_end,65.0,"props retain spatial culling budget")
			for surface in mesh.multimesh.mesh.get_surface_count():
				check(game.graphics._materials.has(mesh.multimesh.mesh.surface_get_material(surface)),"preset owns imported material")
		for cache in station.caches:
			check(game.scavenging.containers.has(cache),"original cache stays registered")
			check(cache.contents.used_slots()>0,"station supplies preserved")

func test_four_danger_states_and_presets_keep_identical_simulation() -> void:
	var fog := game.fog_system
	for gap in [1000.0,300.0,80.0,-10.0]:
		fog.simulation.front = fog.players.local.exposure.progress-gap
		var before := fog.snapshot()
		var danger := fog.simulation.danger(fog.players.local.exposure.progress)
		for preset in 3:
			game.graphics.set_preset(preset)
			check_eq(fog.snapshot(),before,"quality never mutates danger")
			check_eq(fog.simulation.danger(fog.players.local.exposure.progress),danger,"same danger classification")
			var visible := 0
			for layer in fog.presentation.layers:
				visible += int(layer.visible)
				check(layer.material_override is ShaderMaterial,"fog shader retained beside PBR")
			check_eq(visible,[2,4,6][preset],"fog rendering budget changes independently")

func test_fog_death_and_fresh_scene_recover_authored_character() -> void:
	game.fog_system.players.local.exposure.exposure = 100
	game.fog_system.players.local.exposure.health = .1
	game.fog_system.simulation.front = 100
	await seconds(.3)
	check_eq(game.journey.mission.status,"failed","fog death opens failure ledger")
	check(game.player.input.blocked,"dead player cannot move")
	finite_rig()
	get_tree().paused = false
	await free_spawned()
	game = await spawn_scene("res://scenes/missions/harlow_escape.tscn",16) as Game
	worker = game.player.visual.get_node("RailWorker")
	check_eq(game.journey.mission.status,"active","fresh mission active")
	check_eq(game.fog_system.players.local.exposure.health,100.0,"health reset")
	check(not game.player.input.blocked,"input recovered")
	check_eq(worker.current_state,&"idle","rig returns to valid idle")
	finite_rig()

func test_results_pause_keeps_model_and_world_state_intact() -> void:
	var saved := snapshot()
	var fog_before := game.fog_system.snapshot()
	game.journey.mission.status = "escaped"
	game.journey.ui.show_results()
	await physics_frames(3)
	check(game.journey.ui.panel.visible and get_tree().paused,"results visible and simulation paused")
	check_eq(game.fog_system.snapshot(),fog_before,"results do not advance danger")
	check_eq(game.train.distance,saved.train.distance,"train holds final pose")
	check(art.get_node("AuthoredLocomotive").is_inside_tree(),"detailed train survives mission completion")
	finite_rig()

func test_scene_detachment_does_not_read_retired_skeleton_transforms() -> void:
	var parent := game.get_parent()
	parent.remove_child(game)
	# Actual scene replacement removes before deleting; modifier notifications
	# during this interval must be harmless (the runner captures engine errors).
	worker.pose_correction._process_modification()
	check(not game.is_inside_tree(),"old scene detached during replacement")
	check(is_instance_valid(worker.skeleton),"retired rig still exists until deletion")
	game.free()

func route_fixture(distance: float) -> void:
	game.train.distance = distance
	game.train._apply_positions(0)
	await physics_frames(3)
	var crew := game.train.get_node("CrewCar") as TrainCar
	game.player.teleport_to(crew.to_global(Vector3(-2,1.05,0)))
	await seconds(.5)

func snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(JourneySave.snapshot(game.journey)))

func finite_rig() -> void:
	for index in worker.skeleton.get_bone_count():
		check(worker.skeleton.get_bone_global_pose(index).is_finite(),"valid survivor bone "+str(index))
