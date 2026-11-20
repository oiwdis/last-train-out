extends SceneTree
## Bounded rendering/lifetime fixtures, not continuous-gameplay evidence.
## The launch harness supplies an isolated user directory; never use an owner save.
var game: Game
var destination := "/tmp/lto-preparation-stress.json"
var scenario := "cycles"
var checks: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): destination = arg.trim_prefix("--out=")
		if arg.begins_with("--scenario="): scenario = arg.trim_prefix("--scenario=")
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks.append({"check":label,"passed":value,"ticks_ms":Time.get_ticks_msec()})
	print("[preparation-stress] ","PASS " if value else "FAIL ",label)
	# Retain progress even if the next GPU command loses the device.
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify({
		"scenario":scenario,"checks":checks,"complete":false},"  "))

func run() -> void:
	game = load("res://scenes/missions/harlow_escape.tscn").instantiate() as Game
	root.add_child(game)
	current_scene = game
	if scenario == "exit-during-preparation":
		for frame in 30:
			await process_frame
			if game.has_node("RenderPreparation"): break
		if DisplayServer.get_name() == "headless": game.graphics._prepare_rendering()
		check(game.has_node("RenderPreparation"),"exit intersects an active preparation job")
		var owner: WeakRef = weakref(game.graphics)
		await DiagnosticSceneRetirement.release(game)
		check(owner.get_ref() == null,"cancelled preparation releases its controller")
		check(not paused,"cancelled preparation releases the pause")
	else:
		await ready_game()
		for cycle in 3:
			for preset in [0,1,2,0]:
				var before := game.fog_system.snapshot()
				game.graphics.set_preset(preset)
				check(game.fog_system.snapshot() == before,"preset preserves fog simulation")
				await process_frame
				game.fog_system.set_state(((cycle+preset)%4) as FogSystem.FogState)
				await game.graphics.wait_for_render_ready()
				check(not paused and not game.graphics.is_preparing(),"preset/fog preparation finishes")
			# A real saved scene reload, using the same buttons as gameplay. This
			# fixture stays at Harlow; the continuous tour covers earned travel.
			game.journey.ui.toggle(true)
			await process_frame
			click_button("Save Game")
			await process_frame
			var saved := JourneySave.read_file()
			check(JourneySave.valid(game.journey,saved),"Save button writes a valid fixture")
			click_button("Continue Game")
			await scene_changed
			game = current_scene as Game
			await ready_game()
			check(game.player.global_position.distance_to(JourneySave.unpack(saved.player.position)) < .2,"Continue restores player position")
			check(game.scavenging.world_items.size() == saved.cargo.size(),"Continue preserves cargo ownership")
		game.journey.ui.toggle(true)
		await process_frame
		click_button("Restart Mission")
		await scene_changed
		game = current_scene as Game
		await ready_game()
		check(game.journey.mission.status == "active","Restart returns a ready mission")
		await DiagnosticSceneRetirement.release(game)
		check(not paused,"final scene retirement leaves no preparation pause")
	var failed := checks.filter(func(row: Dictionary) -> bool: return not row.passed).size()
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify({
		"scenario":scenario,"checks":checks,"complete":true,"failed":failed,
		"runtime_binary":OS.get_executable_path().get_file(),"engine_build":Engine.get_version_info().build,"renderer":RenderingServer.get_current_rendering_method(),
		"driver":RenderingServer.get_current_rendering_driver_name(),
		"user_data_directory":OS.get_user_data_dir()},"  "))
	quit(1 if failed else 0)

func ready_game() -> void:
	game.player.input.scripted = true
	await game.graphics.wait_for_render_ready()
	while not game.journey.ready_to_play: await process_frame
	for frame in 12: await physics_frame

func click_button(caption: String) -> void:
	for button: Button in game.journey.ui.panel.find_children("*","Button",true,false):
		if button.text != caption: continue
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.pressed = true
		root.push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		root.push_input(event,true)
		return
	check(false,"missing ledger button "+caption)
