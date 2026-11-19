extends SceneTree
## Matched real-time samples. Fixture repositioning is only for profiling, never gameplay footage.
var mission := false
var output := "/tmp/journey-performance.json"
var game: Node3D
var samples := 24
var results: Array = []
var travel := false
var near_front := false
var started := 0
var loading_ms := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--mission": mission = true
		elif arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		elif arg.begins_with("--samples="): samples = int(arg.trim_prefix("--samples="))
	run.call_deferred()

func run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	started = Time.get_ticks_msec()
	game = load("res://scenes/missions/harlow_escape.tscn" if mission else "res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	await frames(8)
	loading_ms = Time.get_ticks_msec()-started
	game.player.input.scripted = true
	game.camera_rig.set_physics_process(false)
	game.camera_rig.exploration.set_process(false)
	game.fog_system.set_physics_process(false)
	if mission: game.journey.set_physics_process(false)
	var views := ["Harlow platform","Harlow warehouse"]
	if mission: views.append_array(["Curve travel","Ashford yard","Ashford workshop","Blackwater crossing","Blackwater stores"])
	for title in views:
		var gaps := [210.0,8.0] if title.begins_with("Harlow") else [8.0] if title == "Ashford workshop" else [210.0]
		for gap in gaps:
			for preset in 3:
				setup_view(title,gap)
				game.graphics.set_preset(preset)
				await frames(10)
				var times: Array[float] = []
				var calls := 0.0
				var process_ms := 0.0
				var physics_ms := 0.0
				var last := Time.get_ticks_usec()
				for i in samples:
					await RenderingServer.frame_post_draw
					var now := Time.get_ticks_usec()
					times.append((now-last)/1000.0)
					last = now
					calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)/samples
					process_ms += Performance.get_monitor(Performance.TIME_PROCESS)*1000/samples
					physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000/samples
				var mean := 0.0
				for value in times: mean += value/times.size()
				times.sort()
				var row := {"view":title,"preset":["Low","Medium","High"][preset],"fog_gap":gap,"samples":times.size(),
					"mean_ms":mean,"median_ms":times[times.size()/2],"p95_ms":times[ceili(times.size()*0.95)-1],"max_ms":times.back(),
					"draw_calls":calls,"process_ms":process_ms,"physics_ms":physics_ms,"engine_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,
					"peak_engine_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1048576,"rss_mb":rss_mb(),"render_scale":root.scaling_3d_scale}
				results.append(row)
				print("[journey-benchmark] ",JSON.stringify(row))
				if mission and preset == 1 and title in ["Ashford yard","Ashford workshop","Blackwater crossing","Blackwater stores"]:
					root.get_texture().get_image().save_png("res://docs/validation/milestone3-finalization/"+title.to_lower().replace(" ","-")+".png")
	var report := {"mission":mission,"godot":Engine.get_version_info().string,"cpu":OS.get_processor_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(root.size),"fixed_fps":false,"warmup_frames":10,"startup_to_8_frames_ms":loading_ms,"world_setup_ms":game.journey.load_milliseconds if mission else null,"results":results}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	travel = false
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	quit()

func setup_view(title: String, gap: float) -> void:
	travel = title == "Curve travel"
	near_front = gap < 20
	game.train.set_physics_process(travel)
	var feet := Vector3(13,1.05,0.4)
	var eye := Vector3(26,2.6,0.5)
	var target := Vector3(23,2.1,-3.5)
	match title:
		"Harlow warehouse":
			feet = Vector3(80.5,0.05,1)
			eye = Vector3(74,1.6,3)
			target = Vector3(83,1.6,2)
		"Curve travel":
			game.train.distance = 850
			game.train.speed = 8
			game.train.state = Train.State.CRUISING
			game.train._effective_max_speed = 8
			game.train._apply_positions(0)
			feet = game.fog_system.route.sample(850)+Vector3(0,1.05,0)
		"Ashford yard":
			var origin: Vector3 = game.fog_system.route.sample(game.fog_system.route.stations.ashford)
			feet = origin+Vector3(-25,0.05,14)
			eye = feet+Vector3.UP*1.6
			target = origin+Vector3(24,2,24)
		"Ashford workshop":
			var origin: Vector3 = game.fog_system.route.sample(game.fog_system.route.stations.ashford)
			feet = origin+Vector3(122,0.05,42)
			eye = feet+Vector3.UP*1.6
			target = origin+Vector3(126,1.6,35)
		"Blackwater crossing":
			var origin: Vector3 = game.fog_system.route.sample(game.fog_system.route.stations.blackwater)
			feet = origin+Vector3(46,0.05,14)
			eye = feet+Vector3.UP*1.6
			target = origin+Vector3(74,2,38)
		"Blackwater stores":
			var origin: Vector3 = game.fog_system.route.sample(game.fog_system.route.stations.blackwater)
			feet = origin+Vector3(168,0.05,51)
			eye = feet+Vector3.UP*1.6
			target = origin+Vector3(172,1.6,46)
	game.player.teleport_to(feet)
	game.fog_system.simulation.front = game.fog_system.route.project(feet)-gap
	game.fog_system._update_players(0)
	game.camera_rig.get_camera().global_position = eye
	game.camera_rig.get_camera().look_at(target)
	game.camera_rig.get_camera().fov = 78

func _process(_delta: float) -> bool:
	if travel and game != null:
		var car := game.train.get_node("CrewCar") as TrainCar
		game.camera_rig.get_camera().global_position = car.to_global(Vector3(4,4,8))
		game.camera_rig.get_camera().look_at(car.global_position+Vector3.UP)
	return false

func frames(count: int) -> void:
	for i in count: await RenderingServer.frame_post_draw

func rss_mb() -> float:
	var values: Array = []
	if OS.execute("ps",["-o","rss=","-p",str(OS.get_process_id())],values) == 0 and not values.is_empty():
		return float(str(values[0]).strip_edges())/1024.0
	return 0
