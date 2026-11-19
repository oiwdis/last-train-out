extends Node
## Continuous input-driven playthrough. Never edits train position, fog, fuel, inventory or mission.
var game: Game
var bot: RouteBot
var view: ExplorationCamera
var checks: Array = []
var failed := false
var finished := false
var teleports := 0
var late_escape := false
var output := "res://docs/validation/milestone3-finalization"

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--late-escape": late_escape = true
	_run.call_deferred()

func _run() -> void:
	game = preload("res://scenes/missions/harlow_escape.tscn").instantiate()
	add_child(game)
	await seconds(0.3)
	bot = RouteBot.new(game.player)
	view = game.camera_rig.exploration
	game.player.teleported.connect(func(_at: Vector3,_facing: Vector3) -> void: teleports += 1)
	game.graphics.set_preset(0)
	view.request_perspective(0)
	await shot("01_harlow_departure")
	await walk(Vector3(5,1,1.2))
	await search("harlow_departure_coal")
	await pickup_coal()
	await walk(Vector3(5,1,0))
	await walk(Vector3(5,1,-0.8))
	await deposit()
	await board()
	await stoke()
	await depart()
	await travel("ashford")
	await shot("02_ashford_arrival")
	await disembark()
	var station := game.journey.stations[0]
	await walk(station.to_global(Vector3(-12,1,3.4)))
	await search("ashford_coal_a")
	await pickup_coal()
	await walk(station.to_global(Vector3(-10,1,2)))
	await deposit()
	await walk(station.to_global(Vector3(-12,1,6)))
	await walk(station.to_global(Vector3(-12,0,15)))
	await walk(station.to_global(Vector3(22,0,33)))
	await walk(station.to_global(Vector3(22,0,26.4)))
	await search("ashford_coal_b")
	await pickup_coal()
	await shot("03_ashford_heavy_cargo")
	await walk(station.to_global(Vector3(22,0,33)))
	await walk(station.to_global(Vector3(-12,0,15)))
	await walk(station.to_global(Vector3(-12,1,6)))
	await walk(station.to_global(Vector3(-10,1,2)))
	await deposit()
	await board()
	await stoke()
	await stoke()
	if late_escape:
		game.hud.show_message("VALIDATION · waiting for the advancing fog before the Ashford escape",12)
		while game.train.distance-game.fog_system.simulation.front > 140:
			await seconds(1)
		await shot("04_ashford_late_escape")
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
	await depart()
	await travel("escape")
	check(game.journey.mission.status == "escaped","mission completed through normal objectives")
	check(teleports == 0,"zero player teleports across entire journey")
	await shot("07_results")
	finish()

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

func pickup_coal() -> void:
	if failed: return
	var closest: WorldItem
	for item in game.scavenging.world_items:
		if is_instance_valid(item) and item.available and item.item.id == &"coal_sack":
			if closest == null or item.global_position.distance_to(game.player.global_position) < closest.global_position.distance_to(game.player.global_position):
				closest = item
	if closest == null:
		check(false,"coal revealed")
		return
	await interact(closest.interaction,Vector3.UP*0.45)
	check(game.scavenging.carried == closest,"physical heavy coal pickup")

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
	view.request_perspective(0)
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
	var report := {"checks":checks,"failed":failed,"teleports":teleports,"late_escape":late_escape,
		"results":game.journey.mission.results(game.fog_system.simulation.elapsed,game.train.distance)}
	FileAccess.open(output.path_join("continuous-journey.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	get_tree().quit(1 if failed else 0)
