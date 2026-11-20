extends TestSuite
var game: Game
var journey: JourneyController

func before_each() -> void:
	JourneyController.pending_load = {}
	JourneyController.next_difficulty = 1.0
	game = await spawn_scene("res://scenes/missions/harlow_escape.tscn",12) as Game
	journey = game.journey
	game.player.input.scripted = true

func after_each() -> void:
	get_tree().paused = false
	await free_spawned()

func test_three_station_content_is_resident_and_unique() -> void:
	check(journey.ready_to_play,"mission binding finished")
	check_eq(journey.stations.size(),2,"two new station scenes")
	var seen := {}
	for cache in game.scavenging.containers:
		check(not seen.has(cache.cache_id),"unique cache "+cache.cache_id)
		seen[cache.cache_id] = true
		check(cache.contents.used_slots() > 0,"supplies present")
	check_greater(game.scavenging.containers.size(),24,"Harlow and both depots have real loot")
	check_greater(game.fog_system.shelters.size(),8,"building protection registered")

func test_modular_buildings_have_passable_doorways_and_solid_walls() -> void:
	for station in journey.stations:
		for building in station.buildings:
			var d := building.dimensions.z/2
			var start := building.to_global(Vector3(0,1.3,d+2))
			var end := building.to_global(Vector3(0,1.3,0))
			var query := PhysicsRayQueryParameters3D.create(start,end,1)
			check(game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"open door "+building.title)
			query.from = building.to_global(Vector3(building.dimensions.x/2+2,1.3,0))
			check(not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"wall collides "+building.title)

func test_save_restores_backpack_storage_and_searched_containers_without_duplication() -> void:
	game.inventory_system.storage.add(ItemCatalog.find(&"coal_sack"),2)
	var cache := journey.stations[0].caches[0]
	cache.complete()
	cache.contents.clear()
	var saved := roundtrip()
	check(JourneySave.valid(journey,saved),"whole save validates")
	game.inventory_system.storage.clear()
	for i in 2:
		check(await JourneySave.apply(journey,saved),"restore accepted")
		check_eq(game.inventory_system.storage.count(&"coal_sack"),2,"same supply restored, never appended")
		check(cache.is_searched and cache.contents.used_slots()==0,"emptied cache remains empty")
		for slot in game.inventory_system.backpack.slot_count:
			var actual: Dictionary = JourneySave.inventory(game.inventory_system.backpack)[slot]
			check_eq(actual.get("item"),saved.backpack[slot].get("item"),"item restored to same slot")
			check_eq(actual.get("amount"),saved.backpack[slot].get("amount"),"amount restored")

func test_save_preserves_held_and_loose_heavy_cargo() -> void:
	var coal := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,game.player.global_position)
	game.scavenging._hold(coal)
	game.scavenging.spawn_world(ItemCatalog.find(&"machine_component"),1,Vector3(9,1.05,2))
	var saved := roundtrip()
	check_eq(saved.cargo.size(),2,"held ownership included")
	check(await JourneySave.apply(journey,saved),"restore held and loose")
	check(game.scavenging.carried != null and game.player.carrying_heavy,"carry penalty restored")
	check_eq(game.scavenging.world_items.size(),2,"only restored objects remain")

func test_malformed_save_is_rejected_before_any_mutation() -> void:
	var original := roundtrip()
	for field in ["cargo","fog","train","containers","player","doors"]:
		var bad := original.duplicate(true)
		bad[field] = "invalid"
		check(not await JourneySave.apply(journey,bad),field+" rejected")
		check_eq(game.train.distance,original.train.distance,"train unchanged")
		check_eq(game.inventory_system.storage.totals(),{},"storage unchanged")
	var bad := original.duplicate(true)
	bad.backpack[0].amount = 500
	check(not JourneySave.valid(journey,bad),"stack overflow rejected")
	bad = original.duplicate(true)
	bad.route = "changed-layout"
	check(not JourneySave.valid(journey,bad),"layout mismatch rejected")

func test_file_save_round_trip_and_missing_file() -> void:
	check(JourneySave.write_file(journey,"user://journey_test.json").begins_with("Game saved"),"atomic disk save")
	check(JourneySave.valid(journey,JourneySave.read_file("user://journey_test.json")),"disk data validates")
	check_eq(JourneySave.read_file("user://does_not_exist.json"),{},"missing file handled")

func test_fog_rng_and_warning_continue_after_restore() -> void:
	game.fog_system.simulation.request_event("surge")
	var saved := roundtrip()
	var expected := FogSimulation.new(game.fog_system.config,journey.route,3001)
	check(expected.restore(saved.fog.simulation),"reference restored")
	check(await JourneySave.apply(journey,saved),"world restored")
	game.fog_system.set_physics_process(false)
	game.fog_system.simulation.advance(92.3)
	expected.advance(92.3)
	check_eq(game.fog_system.simulation.snapshot(),expected.snapshot(),"future events and front match exactly")

func test_train_rides_curve_and_grade_with_passenger_and_loose_cargo() -> void:
	await place_on_route(720)
	var crew := game.train.get_node("CrewCar") as TrainCar
	var loose := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,crew.to_global(Vector3(1,1.05,0.4)))
	await seconds(0.6)
	var before := crew.to_local(game.player.global_position)
	game.train.start()
	await seconds(35)
	check(game.player.is_on_train(),"passenger stays aboard through curve")
	check_near(crew.to_local(game.player.global_position).y,1,0.07,"stable floor height on grade")
	check_less(crew.to_local(game.player.global_position).distance_to(before),0.4,"no sideways platform slip")
	check_less(crew.to_local(loose.global_position).length(),4,"loose cargo follows curve")
	check_near(game.fog_system.train_progress,game.train.distance,0.15,"fog uses same route metres")

func test_walk_and_switch_cameras_on_curved_moving_train() -> void:
	await place_on_route(850)
	var crew := game.train.get_node("CrewCar") as TrainCar
	game.train.start()
	await seconds(6)
	var start := crew.to_local(game.player.global_position)
	var direction := crew.global_basis.x
	game.player.input.script_move(direction.x,direction.z)
	await seconds(0.7)
	game.player.input.clear()
	game.camera_rig.exploration.request_perspective(0)
	await seconds(0.3)
	game.camera_rig.exploration.request_perspective(1)
	check(game.player.is_on_train(),"perspectives retain riding")
	check_greater(crew.to_local(game.player.global_position).x,start.x+1.5,"can walk inside curve")

func test_save_and_resume_moving_train_retains_rider_and_fuel() -> void:
	await place_on_route(830)
	game.train.start()
	await seconds(7)
	var saved := roundtrip()
	check(await JourneySave.apply(journey,saved),"moving save restored")
	check_near(game.train.distance,saved.train.distance,0.15,"position restored")
	check_near(game.fog_system.fuel.amount,saved.fog.fuel,0.04,"fuel retained")
	await seconds(5)
	check(game.player.is_on_train(),"no catapult after motion resumes")
	check_greater(game.train.distance,saved.train.distance+25,"normal travel resumes")

func test_automatic_arrival_and_departure_never_reset_fog_or_inventory() -> void:
	await place_on_route(journey.route.stations.ashford-90)
	game.inventory_system.storage.add(ItemCatalog.find(&"tools"),2)
	var elapsed := game.fog_system.simulation.elapsed
	game.train.start()
	await seconds(22)
	check_eq(journey.next_stop,2,"Ashford arrived once")
	check_eq(game.train.state,Train.State.STOPPED,"service brake stops at platform")
	check_near(game.train.distance,journey.route.stations.ashford,1,"accurate station stop")
	check_greater(game.fog_system.simulation.elapsed,elapsed+20,"fog continued during arrival")
	check_eq(game.inventory_system.storage.count(&"tools"),2,"hold retained")
	game.train.start()
	await seconds(8)
	check_greater(game.train.distance,journey.route.stations.ashford+20,"departing does not rebrake at same platform")

func test_fuel_shortage_stops_train_and_stored_coal_restores_departure() -> void:
	await place_on_route(400)
	game.fog_system.fuel.amount = 0.4
	game.train.start()
	await seconds(10)
	check_eq(game.train.state,Train.State.STOPPED,"empty boiler brakes to stop")
	check(not game.train.start(),"cannot restart without fuel")
	game.inventory_system.storage.add(ItemCatalog.find(&"coal_sack"),1)
	check(game.fog_system.fuel.refuel(),"stored coal consumed")
	check_eq(game.inventory_system.storage.count(&"coal_sack"),0,"single owner after refueling")
	check(game.train.start(),"can resume journey")

func test_fog_catches_stranded_train_and_records_failure() -> void:
	await place_on_route(700)
	game.fog_system.simulation.front = 760
	await seconds(65)
	check(game.fog_system.players.local.exposure.dead,"cab only delays lethal exposure")
	check_eq(journey.mission.status,"failed","mission failure shown")

func test_presets_do_not_change_route_or_survival_state() -> void:
	var signature := journey.route.signature()
	var fuel := game.fog_system.fuel.amount
	for preset in 3:
		game.graphics.set_preset(preset)
		check_eq(journey.route.signature(),signature,"preset preserves geometry authority")
		check_eq(game.fog_system.fuel.amount,fuel,"preset preserves fuel")
	journey.ui.toggle(true)
	await get_tree().process_frame
	await get_tree().process_frame
	var screen := get_viewport().get_visible_rect()
	check(screen.encloses(journey.ui.panel.get_global_rect()),"save/results panel fits the viewport")
	check(screen.encloses(journey.ui.return_button.get_global_rect()),"mission actions stay on screen")
	check_near(journey.ui.panel.get_global_rect().get_center().x,screen.get_center().x,1,"ledger centered horizontally")
	check_near(journey.ui.panel.get_global_rect().get_center().y,screen.get_center().y,1,"ledger centered vertically")
	journey.ui.toggle(false)

func test_reloading_scene_creates_clean_mission_without_duplicate_cache_ownership() -> void:
	journey.mission.note_read = true
	var count := game.scavenging.containers.size()
	await free_spawned()
	game = await spawn_scene("res://scenes/missions/harlow_escape.tscn",10) as Game
	journey = game.journey
	check(not journey.mission.note_read,"new run clears objective state")
	check_eq(game.scavenging.containers.size(),count,"no old station registrations")
	check_eq(game.train.distance,0.0,"new train at Harlow")
	check_near(game.fog_system.simulation.elapsed,10.0/60,0.2,"new run restarts fog")

func test_save_from_another_seed_restores_cache_layout_atomically() -> void:
	game.scavenging.loot_seed = 92713
	game.scavenging.reset_world()
	game.fog_system.simulation.seed_value = 92713
	game.fog_system.simulation.reset()
	var saved := roundtrip()
	game.scavenging.loot_seed = 3001
	game.scavenging.reset_world()
	check(JourneySave.valid(journey,saved),"saved seed determines cache capacities")
	check(await JourneySave.apply(journey,saved),"cross-seed restore succeeds")
	check_eq(game.scavenging.loot_seed,92713,"loot seed restored")
	check_eq(game.fog_system.simulation.seed_value,92713,"event seed restored")

func test_save_restores_door_ids_and_future_item_ownership() -> void:
	var all := JourneySave.doors(game)
	var id: String = all.keys()[0]
	var door: WorldDoor = all[id]
	door.is_open = false
	game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,Vector3(12,1.05,2))
	var saved := roundtrip()
	check(await JourneySave.apply(journey,saved),"stable door and cargo IDs restored")
	check(not door.is_open,"closed shelter remains closed")
	var old_id := game.scavenging.world_items[0].persistent_id
	var new_item := game.scavenging.spawn_world(ItemCatalog.find(&"coal_sack"),1,Vector3(13,1.05,2))
	check(old_id != new_item.persistent_id,"new drops cannot reuse restored IDs")

func test_heavy_collection_counts_pickup_once_and_not_revealed_abandoned_sacks() -> void:
	var cache: SearchContainer = game.scavenging.containers.back()
	game.player.teleport_to(cache.global_position+Vector3(0,0,-1.2))
	await seconds(0.4)
	cache.complete()
	game.scavenging.collect_container(cache)
	check_eq(journey.mission.collected.get("harlow/coal_sack",0),0,"revealing cargo is not collecting it")
	var coal: WorldItem = game.scavenging.world_items.back()
	check(game.scavenging.pick_up(game.player,coal),"pick up revealed coal")
	check_eq(journey.mission.collected.get("harlow/coal_sack",0),1,"pickup recorded once")
	game.scavenging.drop_heavy()
	await seconds(0.3)
	check(game.scavenging.pick_up(game.player,coal),"recover dropped coal")
	check_eq(journey.mission.collected.get("harlow/coal_sack",0),1,"recovery cannot inflate mission statistics")

func test_falling_out_of_route_fails_without_teleporting_to_harlow() -> void:
	game.player.teleport_to(Vector3(1000,-30,0))
	await physics_frames(3)
	check_eq(journey.mission.status,"failed","fall ends run")
	check_greater(game.player.global_position.x,900,"no normal-gameplay teleport to Harlow")

func test_walk_between_all_three_cars_on_a_live_curve() -> void:
	await place_on_route(950)
	var flat := game.train.get_node("FlatCar") as TrainCar
	var loco := game.train.get_node("Locomotive") as TrainCar
	game.player.teleport_to(flat.to_global(Vector3(4.0,1.05,0)))
	await seconds(0.3)
	game.train.start()
	var fell := false
	for tick in 420:
		var target := loco.to_global(Vector3(-2.7,1,0))
		var offset := target-game.player.global_position
		if Vector2(offset.x,offset.z).length() < 0.3:
			break
		var heading := Vector2(offset.x,offset.z/game.player.config.depth_speed_scale).normalized()
		game.player.input.script_move(heading.x,heading.y)
		await physics_frames(1)
		if game.player.global_position.y < journey.route.sample(game.train.distance).y+0.8:
			fell = true
	game.player.input.clear()
	check(not fell,"curve gangways keep a continuous walking floor")
	check_eq(game.player.get_ride_body(),loco,"walked from flatcar through crew car into moving cab")

func test_aimed_boarding_and_ladder_climb_during_curved_departure() -> void:
	await place_on_route(900)
	var crew := game.train.get_node("CrewCar") as TrainCar
	var ladder := crew.get_node("RoofLadder") as Ladder
	var at := ladder.global_position+crew.global_basis.x*2.0+crew.global_basis.z*0.6
	at.y = journey.route.sample(journey.route.project(at)).y+0.05
	game.player.teleport_to(at)
	game.camera_rig.exploration.request_perspective(0)
	await seconds(0.5)
	game.train.start()
	var grabbed := false
	for tick in 480:
		game.camera_rig.exploration.aim_at(ladder.global_position+Vector3.UP)
		await physics_frames(1)
		if game.player.interactor.find_interactable() == ladder:
			game.player.input.script_interact()
			await physics_frames(4)
			grabbed = game.player.state == Player.State.CLIMB
			if grabbed: break
	check(grabbed,"look ray and E grab the ladder while departing on a curve")
	game.player.input.script_move(0,-1)
	var mounted := false
	for tick in 300:
		await physics_frames(1)
		if game.player.state == Player.State.MOUNT:
			mounted = true
		if mounted and game.player.is_grounded():
			break
	game.player.input.clear()
	check(mounted,"ladder reaches the roof exit")
	game.camera_rig.exploration.request_perspective(1)
	await seconds(0.5)
	check(game.player.is_on_train(),"ladder rider remains attached through curve")
	check_near(crew.to_local(game.player.global_position).y,3.62,0.12,"climbed onto the moving roof")

func place_on_route(progress: float) -> void:
	# Explicit test fixture only. Gameplay validation uses no repositioning.
	game.train.distance = progress
	game.train._apply_positions(0)
	await physics_frames(3)
	var crew := game.train.get_node("CrewCar") as TrainCar
	game.player.teleport_to(crew.to_global(Vector3(-2,1.05,0)))
	await seconds(0.4)

func roundtrip() -> Dictionary:
	return JSON.parse_string(JSON.stringify(JourneySave.snapshot(journey)))
