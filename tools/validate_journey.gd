extends Node
## Continuous input-driven playthrough. Never edits train position, fog, fuel, inventory or mission.
var game: Game
var bot: RouteBot
var view: ExplorationCamera
var checks: Array = []
var failed := false
var finished := false
var source_commit := ""
var teleports := 0
var late_escape := false
var scenario := "journey"
var observations: Array = []
var output := "res://docs/validation/milestone35/gameplay"
var integration_tour := false
var quality := 0
var load_restores := 0

func _ready() -> void:
	var revision: Array = []
	if OS.execute("git",["rev-parse","HEAD"],revision) == 0 and not revision.is_empty():
		source_commit = str(revision[0]).strip_edges()
	for arg in OS.get_cmdline_user_args():
		if arg == "--late-escape": late_escape = true
		if arg == "--fuel-shortage": scenario = "fuel-shortage"
		if arg == "--stranded": scenario = "stranded"
		if arg == "--save-ui-only": scenario = "save-ui"
		if arg == "--integration-tour": integration_tour = true
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		if arg.begins_with("--quality="): quality = clampi(int(arg.trim_prefix("--quality=")),0,2)
	DirAccess.make_dir_recursive_absolute(output)
	_run.call_deferred()

func _run() -> void:
	game = preload("res://scenes/missions/harlow_escape.tscn").instantiate()
	# The driver survives reloads as a separate root node. Continue Game reloads
	# the actual shipped scene, exactly as in the exported app.
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	await game.graphics.wait_for_render_ready()
	await seconds(0.3)
	bot = RouteBot.new(game.player)
	view = game.camera_rig.exploration
	game.player.teleported.connect(func(_at: Vector3,_facing: Vector3) -> void: teleports += 1)
	game.graphics.set_preset(quality)
	await game.graphics.wait_for_render_ready()
	view.request_perspective(0)
	if scenario == "save-ui":
		await save_and_continue()
		finish()
		return
	await shot("01_harlow_departure")
	if integration_tour:
		await walk(Vector3(13,1,1.2))
		await search("platform_luggage")
		await walk(Vector3(13,1,.4))
		await walk(Vector3(27.2,1,.4))
		await walk(Vector3(27.2,1,1.1))
		await search("platform_locker")
		await walk(Vector3(27.2,1,.4))
		await walk(Vector3(30,1,.4))
		key(KEY_V)
		await seconds(.5)
		view.aim_at(Vector3(20,2,.4))
		await seconds(2)
		await shot("00_harlow_character")
		check(view.perspective == 1,"V selects detailed third-person survivor")
		view.aim_at(Vector3(44,2,3))
		await seconds(2)
		await shot("00_harlow_architecture")
		await walk(Vector3(13,1,.4))
	await walk(Vector3(5,1,1.2))
	await search("harlow_departure_coal")
	await pickup_cargo()
	if integration_tour:
		key(KEY_V)
		await seconds(.8)
		await shot("01_harlow_carry")
	await walk(Vector3(5,1,0))
	await walk(Vector3(5,1,-0.8))
	await deposit()
	await board()
	if scenario == "fuel-shortage":
		await natural_fuel_shortage()
		finish()
		return
	if scenario == "stranded":
		await natural_stranding()
		finish()
		return
	await stoke()
	await depart()
	await travel("ashford")
	await shot("02_ashford_arrival")
	await disembark()
	var station := game.journey.stations[0]
	await walk(station.to_global(Vector3(-12,1,3.4)))
	await search("ashford_coal_a")
	await pickup_cargo()
	await walk(station.to_global(Vector3(-10,1,2)))
	await deposit()
	await walk(station.to_global(Vector3(-12,1,6)))
	await walk(station.to_global(Vector3(-12,0,15)))
	await walk(station.to_global(Vector3(22,0,33)))
	await walk(station.to_global(Vector3(22,0,26.4)))
	await search("ashford_coal_b")
	await pickup_cargo()
	await shot("03_ashford_heavy_cargo")
	await walk(station.to_global(Vector3(22,0,33)))
	await walk(station.to_global(Vector3(-12,0,15)))
	await walk(station.to_global(Vector3(-12,1,6)))
	await walk(station.to_global(Vector3(-10,1,2)))
	await deposit()
	await board()
	if late_escape:
		# Optional mechanical salvage: a long heavy return with a naturally approaching front.
		await disembark()
		await walk(station.to_global(Vector3(-12,1,6)))
		await walk(station.to_global(Vector3(-12,0,15)))
		await walk(station.to_global(Vector3(-12,0,35)))
		await walk(station.to_global(Vector3(122,0,46)))
		await walk(station.to_global(Vector3(122,0,42)))
		await walk(station.to_global(Vector3(122,0,39.3)))
		await search("ashford_workshop")
		await walk(station.to_global(Vector3(122,0,42)))
		await walk(station.to_global(Vector3(126.7,0,39)))
		await search("ashford_components")
		await pickup_cargo(&"machine_component")
		game.hud.show_message("VALIDATION · waiting for the actual fog before returning with heavy workshop spares",12)
		while game.fog_system.players.local.exposure.progress-game.fog_system.simulation.front > 390 and not failed:
			await seconds(1)
		await shot("04_ashford_heavy_return")
		await walk(station.to_global(Vector3(122,0,42)))
		await walk(station.to_global(Vector3(122,0,46)))
		await walk(station.to_global(Vector3(65,0,36)))
		key(KEY_G)
		await seconds(0.3)
		check(game.scavenging.carried == null,"abandoned heavy spares using G as fog closes")
		game.hud.show_message("Leave the spares. Get back to the train.",8)
		await walk(station.to_global(Vector3(-12,0,36)))
		await walk(station.to_global(Vector3(-12,0,15)))
		await walk(station.to_global(Vector3(-12,1,6)))
		await walk(station.to_global(Vector3(-10,1,2)))
		await board()
		await shot("04_ashford_late_escape")
	await stoke()
	await stoke()
	await depart()
	await travel("blackwater")
	await shot("05_blackwater_arrival")
	await disembark()
	station = game.journey.stations[1]
	await walk(station.to_global(Vector3(-12,1,6)))
	await walk(station.to_global(Vector3(-12,0,15)))
	await walk(station.to_global(Vector3(12,0,29)))
	await walk(station.to_global(Vector3(12,0,23.3)))
	await search("blackwater_food")
	await walk(station.to_global(Vector3(12,0,29)))
	await walk(station.to_global(Vector3(82,0,45)))
	await walk(station.to_global(Vector3(82,0,39.3)))
	await search("blackwater_medicine")
	await walk(station.to_global(Vector3(82,0,45)))
	await walk(station.to_global(Vector3(168,0,55)))
	await walk(station.to_global(Vector3(168,0,50)))
	await walk(station.to_global(Vector3(164.2,0,49)))
	await interact(station.note,Vector3(0,0.65,0))
	check(game.journey.mission.note_read,"evacuation note read using E")
	await shot("06_blackwater_evacuation")
	await walk(station.to_global(Vector3(168,0,50)))
	await walk(station.to_global(Vector3(168,0,56)))
	await walk(station.to_global(Vector3(-12,0,56)))
	await walk(station.to_global(Vector3(-12,0,15)))
	await walk(station.to_global(Vector3(-12,1,6)))
	await walk(station.to_global(Vector3(-10,1,2)))
	await deposit()
	await board()
	if integration_tour:
		await save_and_continue()
	await depart()
	await travel("escape")
	check(game.journey.mission.status == "escaped","mission completed through normal objectives")
	check(teleports == 0,"zero player teleports across entire journey")
	await shot("07_results")
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(4.0,true).timeout
	finish()

func natural_fuel_shortage() -> void:
	# Keep the collected Harlow sack in storage until the initial boiler burns dry.
	await depart()
	var elapsed := 0
	while game.train.is_moving() and elapsed < 300 and not failed:
		await seconds(1)
		elapsed += 1
		if elapsed % 30 == 0: observe("initial fuel burning")
	check(game.fog_system.fuel.amount <= 0.001,"starting fuel exhausted through real train operation")
	check(game.train.state == Train.State.STOPPED,"empty boiler stops the moving train")
	check(game.train.distance > 1000 and game.train.distance < game.journey.route.stations.ashford,"stranded between Harlow and Ashford")
	check(game.player.is_on_train(),"rider remains aboard after fuel stop")
	await walk(game.train.get_node("Locomotive").to_global(Vector3(-2.7,1,0)))
	await interact(game.train.get_node("Locomotive").interior.controls[0],Vector3.ZERO)
	check(game.train.state == Train.State.STOPPED,"physical regulator cannot depart on an empty boiler")
	check(game.inventory_system.storage.count(&"coal_sack") == 1,"collected coal survives travel in storage")
	observe("out of fuel")
	await stoke()
	check(game.inventory_system.storage.count(&"coal_sack") == 0,"refueling consumes the one collected sack")
	await depart()
	await travel("ashford")
	observe("arrived after refueling")
	check(teleports == 0,"zero teleports during fuel-shortage recovery")

func save_and_continue() -> void:
	view.request_perspective(0)
	await seconds(.5)
	key(KEY_J)
	for frame in 3: await get_tree().process_frame
	check(game.journey.ui.panel.visible and get_tree().paused,"J opens actual save ledger")
	click_button("Save Game")
	for frame in 3: await get_tree().process_frame
	var saved := JourneySave.read_file()
	check(JourneySave.valid(game.journey,saved),"Save Game button writes the played world")
	if failed: return
	FileAccess.open(output.path_join("played-blackwater-save.json"),FileAccess.WRITE).store_string(JSON.stringify(saved,"  "))
	await shot("06_blackwater_saved")
	click_button("Continue Game")
	await get_tree().scene_changed
	game = get_tree().current_scene as Game
	game.player.teleported.connect(func(_at: Vector3,_facing: Vector3) -> void: load_restores += 1,CONNECT_ONE_SHOT)
	await game.graphics.wait_for_render_ready()
	await seconds(.4)
	view = game.camera_rig.exploration
	bot = RouteBot.new(game.player)
	game.player.teleported.connect(func(_at: Vector3,_facing: Vector3) -> void: teleports += 1)
	check(absf(game.train.distance-float(saved.train.distance)) < .2,"Continue restores actual "+game.journey.current_station().capitalize()+" stop")
	check(view.perspective == int(saved.camera.perspective),"saved camera perspective recovered")
	check(game.player.is_on_train() if saved.player.car != "" else game.player.is_grounded(),"saved player support recovered")
	var restored_storage: Array = JSON.parse_string(JSON.stringify(JourneySave.inventory(game.inventory_system.storage)))
	check(restored_storage == saved.storage,"collected supplies survive Continue")
	check(game.journey.mission.note_read == saved.mission.note,"evacuation note progress restored")
	check(game.scavenging.world_items.size() == saved.cargo.size(),"Continue preserves cargo count without duplication")
	await shot("06_blackwater_resumed")

func click_button(caption: String) -> void:
	for button: Button in game.journey.ui.panel.find_children("*","Button",true,false):
		if button.text == caption:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = button.get_global_rect().get_center()
			event.global_position = event.position
			event.pressed = true
			get_viewport().push_input(event,true)
			event = event.duplicate()
			event.pressed = false
			get_viewport().push_input(event,true)
			return
	check(false,"missing ledger button "+caption)

func natural_stranding() -> void:
	# Remain in the stationary cab. Do not move the front or alter exposure.
	var elapsed := 0
	var saw_damage := false
	var initial_front := game.fog_system.simulation.front
	while not game.fog_system.players.local.exposure.dead and elapsed < 1200 and not failed:
		await seconds(1)
		elapsed += 1
		if game.fog_system.players.local.exposure.health < 100: saw_damage = true
		if elapsed % 60 == 0: observe("waiting in stationary cab")
	observe("stranded outcome")
	check(game.train.distance < 0.1,"train stayed at Harlow throughout the wait")
	check(game.fog_system.simulation.front > initial_front + 1000,"fog advanced naturally from its initial position")
	check(saw_damage,"stationary cab occupant takes real exposure damage")
	check(game.fog_system.players.local.exposure.dead,"cab shelter only delays lethal fog")
	check(game.journey.mission.status == "failed","natural fog death produces mission failure")
	check(teleports == 0,"zero teleports during natural fog catch")

func observe(label: String) -> void:
	var sample := {"label":label,"time":game.fog_system.simulation.elapsed,"distance":game.train.distance,
		"fuel":game.fog_system.fuel.amount,"front":game.fog_system.simulation.front,
		"health":game.fog_system.players.local.exposure.health,"exposure":game.fog_system.players.local.exposure.exposure}
	observations.append(sample)
	print("[journey-observation] ",JSON.stringify(sample))

func walk(at: Vector3) -> void:
	if failed: return
	view.aim_at(at+Vector3.UP*1.5)
	var ok := await bot.run([{"to":at,"timeout":120,"radius":0.2}])
	check(ok,"walk: "+(str(at.snappedf(0.1)) if ok else bot.failure))

func search(id: String) -> void:
	if failed: return
	for cache in game.scavenging.containers:
		if cache.cache_id == id:
			await interact(cache,Vector3.UP*0.65)
			await seconds(cache.search_seconds+0.4)
			check(cache.is_searched,"search "+id)
			return
	check(false,"cache missing "+id)

func pickup_cargo(item_id: StringName = &"coal_sack") -> void:
	if failed: return
	var closest: WorldItem
	for item in game.scavenging.world_items:
		if is_instance_valid(item) and item.available and item.item.id == item_id:
			if closest == null or item.global_position.distance_to(game.player.global_position) < closest.global_position.distance_to(game.player.global_position):
				closest = item
	if closest == null:
		check(false,"cargo revealed")
		return
	await interact(closest.interaction,Vector3.UP*0.45)
	check(game.scavenging.carried == closest,"physical heavy pickup: " + str(item_id))

func deposit() -> void:
	if failed: return
	await interact(game.scavenging.storage_point,Vector3.UP*0.65)
	check(game.supply_ui.is_open(),"storage opened using E")
	key(KEY_R)
	await seconds(0.25)
	key(KEY_ESCAPE)
	await seconds(0.25)
	check(game.scavenging.carried == null,"coal deposited using R")

func board() -> void:
	if failed: return
	var flat := game.train.get_node("FlatCar") as TrainCar
	await walk(flat.to_global(Vector3(0.6,1,2.0)))
	await walk(flat.to_global(Vector3(0.6,1,0.6)))
	await walk(flat.to_global(Vector3(3.7,1,0.6)))
	await walk(flat.to_global(Vector3(4.2,1,0)))
	var crew := game.train.get_node("CrewCar") as TrainCar
	await walk(crew.to_global(Vector3(-2.6,1,0)))
	await walk(crew.to_global(Vector3(2.8,1,0)))
	var loco := game.train.get_node("Locomotive") as TrainCar
	await walk(loco.to_global(Vector3(-2.7,1,0)))
	check(game.player.is_on_train(),"walked aboard and through cars to cab")

func disembark() -> void:
	if failed: return
	var crew := game.train.get_node("CrewCar") as TrainCar
	await walk(crew.to_global(Vector3(-2,1,0)))
	var flat := game.train.get_node("FlatCar") as TrainCar
	await walk(flat.to_global(Vector3(4.2,1,0)))
	await walk(flat.to_global(Vector3(3.7,1,0.6)))
	await walk(flat.to_global(Vector3(0.6,1,0.6)))
	await walk(flat.to_global(Vector3(0.6,1,2.0)))

func stoke() -> void:
	if failed: return
	var before := game.fog_system.fuel.amount
	await interact(game.fog_system.fuel.bunker,Vector3.UP*0.2)
	check(game.fog_system.fuel.amount > before,"stored coal stokes boiler")

func depart() -> void:
	if failed: return
	var loco := game.train.get_node("Locomotive") as TrainCar
	await interact(loco.interior.controls[0],Vector3.ZERO)
	check(game.train.is_moving(),"physical regulator starts departure")
	view.request_perspective(1)
	view.aim_at(loco.global_position+Vector3(0,2,12))

func travel(id: String) -> void:
	if failed: return
	var previous := game.train.distance
	var frames := 0
	while game.train.distance < float(game.journey.route.stations[id])-3 or game.train.state != Train.State.STOPPED:
		await get_tree().physics_frame
		frames += 1
		if frames % 600 == 0:
			print("[journey-travel] ",id," distance=",game.train.distance," fuel=",game.fog_system.fuel.amount," fog=",game.fog_system.simulation.front," hp=",game.fog_system.players.local.exposure.health)
			if not game.player.is_on_train() or game.fog_system.players.local.exposure.dead or frames > 24000:
				check(false,"travel failed "+id)
				return
		if game.train.distance < previous or game.train.distance-previous > 0.3:
			check(false,"discontinuous train movement")
			return
		previous = game.train.distance
		if game.journey.mission.status != "active": break
	await seconds(0.3)
	check(game.train.distance >= float(game.journey.route.stations[id])-3,"continuous arrival "+id)
	view.request_perspective(0)

func interact(target: Node3D, offset: Vector3) -> void:
	if failed: return
	if view.perspective != ExplorationCamera.Perspective.FIRST_PERSON:
		view.request_perspective(0)
		# Let the shoulder boom retract before solving the reticle direction.
		await seconds(0.75)
	view.aim_at(target.global_position+offset)
	await seconds(0.25)
	var selected := game.player.interactor.find_interactable()
	check(selected == target,"reticle selects "+str(target.name)+" (got "+str(selected)+")")
	game.player.input.script_interact()
	await seconds(0.3)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func seconds(value: float) -> void:
	for tick in ceili(value*Engine.physics_ticks_per_second):
		await get_tree().physics_frame

func shot(title: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(title+".png"))

func check(ok: bool, caption: String) -> void:
	if finished: return
	checks.append({"passed":ok,"check":caption})
	print("[journey] ","PASS " if ok else "FAIL ",caption)
	if not ok:
		failed = true
		finish()

func finish() -> void:
	if finished: return
	finished = true
	var report := {"source_commit":source_commit,"checks":checks,"failed":failed,"teleports":teleports,"save_restore_repositions":load_restores,"integration_tour":integration_tour,"graphics_preset":quality,"late_escape":late_escape,"scenario":scenario,"observations":observations,
		"results":game.journey.mission.results(game.fog_system.simulation.elapsed,game.train.distance)}
	var filename := "continuous-journey.json" if scenario == "journey" else scenario+"-gameplay.json"
	FileAccess.open(output.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	get_tree().quit(1 if failed else 0)
