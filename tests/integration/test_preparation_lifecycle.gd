extends TestSuite
## Also run windowed in the native stress gate. Headless checks ownership and
## ordering; only the rendered run exercises Vulkan pipelines and driver fences.
const MISSION := "res://scenes/missions/harlow_escape.tscn"
var game: Game

func before_each() -> void:
	JourneyController.pending_load = {}
	game = await spawn_scene(MISSION,16) as Game
	game.player.input.scripted = true
	await game.graphics.wait_for_render_ready()
	await physics_frames(3)

func after_each() -> void:
	get_tree().paused = false
	await free_spawned()

func test_scene_exit_during_preparation_releases_pause_and_controller() -> void:
	var controller: WeakRef = weakref(game.graphics)
	game.graphics._prepare_rendering()
	check(get_tree().paused,"preparation really started")
	game.queue_free()
	for frame in 5: await get_tree().process_frame
	check(not get_tree().paused,"removed scene cannot leave the application paused")
	check(controller.get_ref() == null,"preparation does not retain the removed controller")
	check_eq(get_tree().get_nodes_in_group("render_warmup_material").size(),0,"fog proxy source released")

func test_fog_danger_and_quality_reuse_materials_without_mutating_simulation() -> void:
	var visual := game.fog_system.presentation
	var materials: Array = visual.layers.map(func(layer: MeshInstance3D) -> int: return layer.material_override.get_instance_id())
	var shaders: Array = visual.layers.map(func(layer: MeshInstance3D) -> int: return (layer.material_override as ShaderMaterial).shader.get_instance_id())
	for state in 4:
		game.fog_system.set_state(state as FogSystem.FogState)
		for preset in 3:
			var before := game.fog_system.snapshot()
			game.graphics.set_preset(preset)
			check_eq(game.fog_system.snapshot(),before,"preset cannot alter exposure or seeded danger")
			check_eq(visual.layers.filter(func(layer: MeshInstance3D) -> bool: return layer.visible).size(),[2,4,6][preset],"preset layers preserved")
			for index in visual.layers.size():
				check_eq(visual.layers[index].material_override.get_instance_id(),materials[index],"danger reuses material")
				check_eq((visual.layers[index].material_override as ShaderMaterial).shader.get_instance_id(),shaders[index],"danger reuses shader")
			await game.graphics.wait_for_render_ready()

func test_rapid_preset_requests_finish_on_last_quality_without_orphan_preparation() -> void:
	var children := game.get_child_count()
	for preset in [0,1,2,0,2,1]: game.graphics.set_preset(preset)
	await game.graphics.wait_for_render_ready()
	check_eq(game.graphics.current_index,1,"last request wins")
	check(not game.graphics.is_preparing(),"no stale preparation request")
	check(not get_tree().paused,"gameplay released")
	check_eq(game.get_child_count(),children,"temporary render camera and overlay removed")
	check(game.journey.ready_to_play,"mission remains ready")

func test_continue_during_preset_preparation_restores_rider_and_cargo_together() -> void:
	game.journey.next_stop = 3
	game.train.distance = game.journey.route.stations.blackwater
	game.train._apply_positions(0)
	await physics_frames(3)
	var crew := game.train.get_node("CrewCar") as TrainCar
	game.player.teleport_to(crew.to_global(Vector3(-2,1.05,0)))
	await physics_frames(30)
	game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,game.player.global_position+Vector3(.8,0,0))
	await physics_frames(20)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(JourneySave.snapshot(game.journey)))
	check(saved.player.car != "" and saved.cargo[0].car != "","fixture has real car support")
	game.train.distance = 0
	game.train._apply_positions(0)
	await physics_frames(3)
	game.graphics.set_preset(2)
	# Direct entry also exercises the ordering on headless, where normal preset
	# changes intentionally skip rendering. Windowed changes may already be queued.
	if DisplayServer.get_name() == "headless": game.graphics._prepare_rendering()
	check(await JourneySave.apply(game.journey,saved),"Continue accepts the saved journey")
	await physics_frames(30)
	check(game.player.is_on_train(),"rider gets synchronized train support")
	check_less(game.player.global_position.distance_to(JourneySave.unpack(saved.player.position)),.2,"rider restored at Blackwater")
	check_eq(game.scavenging.world_items.size(),1,"one cargo owner")
	check_less(game.scavenging.world_items[0].global_position.distance_to(JourneySave.unpack(saved.cargo[0].position)),.2,"cargo restored with rider")
