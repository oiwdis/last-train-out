extends SceneTree
## Two actual processes: a moving-world save fixture, followed by a cold load.
const SAVE := "/tmp/lto-m3-process-save.json"
const REPORT := "res://docs/validation/milestone3-finalization/process-resume.json"
var phase := "write"
var checks: Array = []
var game: Game

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--phase="): phase = argument.trim_prefix("--phase=")
	run.call_deferred()

func run() -> void:
	var saved := JourneySave.read_file(SAVE) if phase == "read" else {}
	if phase == "read":
		JourneyController.pending_load = saved
		JourneyController.next_seed = int(saved.seed)
		JourneyController.next_difficulty = float(saved.difficulty)
	game = load("res://scenes/missions/harlow_escape.tscn").instantiate()
	root.add_child(game)
	game.player.input.scripted = true
	await frames(20)
	if phase == "write":
		# Deliberate fixture setup, not footage or a claimed playthrough.
		game.train.distance = 2500
		game.journey.next_stop = 2
		game.journey.mission.visited.append("ashford")
		game.fog_system.enter_station("ashford")
		game.train._apply_positions(0)
		await frames(3)
		var crew := game.train.get_node("CrewCar") as TrainCar
		game.player.teleport_to(crew.to_global(Vector3(-2,1.05,0)))
		await frames(30)
		game.inventory_system.storage.add(ItemCatalog.find(&"coal_sack"),2)
		var cargo := game.scavenging.spawn_world(ItemCatalog.find(&"machine_component"),1,game.player.global_position)
		game.scavenging._hold(cargo)
		game.journey.stations[1].caches[0].complete()
		game.journey.stations[1].caches[0].contents.clear()
		game.journey.mission.note_read = true
		game.fog_system.players.local.exposure.health = 73
		game.fog_system.simulation.advance(650)
		game.train.start()
		await frames(420)
		check(JourneySave.write_file(game.journey,SAVE).begins_with("Game saved"),"moving save written to disk")
	else:
		check(not saved.is_empty(),"previous process file exists")
		check(absf(game.train.distance-float(saved.train.distance)) < 3,"moving train resumes at saved route position")
		check(game.player.is_on_train(),"saved rider restored aboard")
		check(absf(game.fog_system.simulation.elapsed-float(saved.fog.simulation.elapsed)) < 0.5,"fog time continues without reset")
		check(str(game.fog_system.simulation.rng.state) == saved.fog.simulation.rng,"event RNG survives process restart")
		check(game.inventory_system.storage.count(&"coal_sack") == 2,"storage preserved")
		check(game.inventory_system.backpack.count(&"bandages") == 1,"backpack preserved")
		check(game.scavenging.carried != null and game.scavenging.carried.item.id == &"machine_component","held cargo preserved")
		check(game.scavenging.world_items.size() == 1,"cargo not duplicated")
		check(game.journey.stations[1].caches[0].contents.used_slots() == 0,"searched station remains depleted")
		check(game.journey.mission.note_read,"mission note preserved")
		check(game.fog_system.players.local.exposure.health == 73,"health preserved")
		var start := game.train.distance
		await frames(180)
		check(game.train.distance > start+20 and game.player.is_on_train(),"journey continues after cold load")
	var ok := true
	for item in checks: ok = ok and bool(item.passed)
	if phase == "read":
		FileAccess.open(REPORT,FileAccess.WRITE).store_string(JSON.stringify({"phase":phase,"passed":ok,"checks":checks},"  "))
	quit(0 if ok else 1)

func frames(count: int) -> void:
	for i in count: await physics_frame

func check(ok: bool, caption: String) -> void:
	checks.append({"passed":ok,"check":caption})
	print("[resume] ","PASS " if ok else "FAIL ",caption)
