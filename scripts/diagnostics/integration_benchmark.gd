extends SceneTree
## Rendering fixtures, NOT gameplay evidence. Identical Harlow views can run on both source heads.
## Never use --fixed-fps for timing. Startup/preset preparation and sampling are reported separately.
var game: Node3D
var eye: Camera3D
var journey: Node
var fog: Node
var suite := "matrix"
var destination := "/tmp/lto-integration-benchmark.json"
var samples := 600
var warmup := 120
var rows: Array = []
var loading: Dictionary = {}
var output_dir := ""
var prepared: Array = []
var transitions: Array = []
var partial_report: FileAccess
var trace_stage := ""
var timeline: Node
const TIMELINE = preload("res://scripts/diagnostics/frame_timeline.gd")
const LOCATIONS := ["Harlow platform", "Warehouse A", "Warehouse B", "Locomotive cab", "Passenger car", "Curved railway", "Ashford Depot", "Ashford workshop", "Blackwater Crossing", "Near advancing fog", "Inside dangerous fog", "Mission completion"]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--suite="): suite = arg.trim_prefix("--suite=")
		if arg.begins_with("--out="): destination = arg.trim_prefix("--out=")
		if arg.begins_with("--samples="): samples = maxi(12,int(arg.trim_prefix("--samples=")))
		if arg.begins_with("--warmup="): warmup = maxi(8,int(arg.trim_prefix("--warmup=")))
		if arg.begins_with("--trace-stage="): trace_stage = arg.trim_prefix("--trace-stage=")
		if arg.begins_with("--shots="): output_dir = arg.trim_prefix("--shots=")
	run.call_deferred()

func run() -> void:
	partial_report = FileAccess.open(destination+".jsonl",FileAccess.WRITE)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	timeline = TIMELINE.new()
	root.add_child(timeline)
	var started := Time.get_ticks_msec()
	var mission := "res://scenes/missions/harlow_escape.tscn"
	game = load(mission if ResourceLoader.exists(mission) else "res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	loading.scene_construct_ms = Time.get_ticks_msec()-started
	await ready_render()
	await frames(2)
	loading.render_ready_ms = Time.get_ticks_msec()-started
	loading.pipelines = pipelines()
	journey = game.get("journey")
	fog = game.get("fog_system")
	game.player.input.scripted = true
	game.player.input.clear()
	game.player.set_physics_process(false)
	game.train.set_physics_process(false)
	if journey != null: journey.set_physics_process(false)
	if fog != null: fog.set_physics_process(false)
	game.camera_rig.set_physics_process(false)
	game.camera_rig.exploration.set_process(false)
	for trigger in game.find_children("*","CutawayTrigger",true,false): trigger.set_deferred("monitoring",false)
	eye = Camera3D.new()
	eye.fov = 78
	eye.near = 0.06
	eye.far = 350
	game.add_child(eye)
	eye.make_current()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var locations: Array = LOCATIONS if suite == "matrix" else LOCATIONS.slice(0,5)
	if suite == "ablations": locations = ["Harlow platform","Near advancing fog","Inside dangerous fog"]
	if not output_dir.is_empty(): DirAccess.make_dir_recursive_absolute(output_dir)
	for preset in 3:
		var before := Time.get_ticks_msec()
		game.graphics.set_preset(preset)
		await ready_render()
		prepared.append({"preset":preset,"milliseconds":Time.get_ticks_msec()-before,"pipelines":pipelines()})
		for location: String in locations:
			var transition_start := Time.get_ticks_usec()
			await place(location)
			transitions.append({"location":location,"preset":preset,"milliseconds":(Time.get_ticks_usec()-transition_start)/1000.0})
			# Capture initial entry frames separately, before settling at this view.
			await measure(location,preset,"entry",mini(samples,60))
			await frames(warmup)
			await measure(location,preset,"steady",samples)
			if not output_dir.is_empty():
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output_dir.path_join("%d-%s.png" % [preset,location.to_snake_case()]))
			if suite == "ablations":
				var actors := game.find_children("*","WorkerAnimator",true,false)
				for actor in actors: actor.process_mode = Node.PROCESS_MODE_DISABLED
				await frames(warmup)
				await measure(location,preset,"animation frozen",samples)
				for actor in actors: actor.process_mode = Node.PROCESS_MODE_INHERIT
				if journey != null:
					var presentation: Node3D = fog.presentation
					presentation.hide()
					presentation.set_process(false)
					var environment: Environment = presentation.environment
					var density := environment.fog_density
					environment.fog_density = presentation.base_density
					await frames(warmup)
					await measure(location,preset,"danger visuals off",samples)
					presentation.show()
					presentation.set_process(true)
					environment.fog_density = density
			paused = false
			if journey != null: journey.ui.panel.hide()
	var report := {"suite":suite,"fixture_only":true,"fixed_fps":false,"vsync":"disabled","resolution":str(root.size),"samples":samples,"warmup":warmup,
		"godot":Engine.get_version_info().string,"processor":OS.get_processor_name(),"processor_count":OS.get_processor_count(),"os":OS.get_name(),
		"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),
		"window_mode":DisplayServer.window_get_mode(),"loading":loading,"fixture_transitions":transitions,"preset_preparation":prepared,"results":rows,
		"static_memory_peak_bytes":OS.get_static_memory_peak_usage(),"total_memory_note":"process RSS sampled externally; static memory is not total RSS"}
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	game.queue_free()
	await process_frame
	await process_frame
	quit()

func place(location: String) -> void:
	var at := Vector3(12,1.05,0.4)
	var camera := Vector3(26,2.6,0.5)
	var target := Vector3(23,2.1,-3.5)
	game.train.distance = 0
	game.train.set_physics_process(false)
	game.player.set_physics_process(false)
	game.train.speed = 0
	game.train.state = 0
	if location == "Curved railway": game.train.distance = 850.0
	if location == "Mission completion": game.train.distance = journey.route.length()
	game.train._apply_positions(0)
	# AnimatableBody3D synchronizes on physics ticks. Read car-local positions
	# only after that synchronization, just as the save system does.
	for tick in 3: await physics_frame
	if journey != null:
		fog.simulation.front = -1050.0
		fog.presentation._blend = 0.0
		journey.mission.status = "active"
	match location:
		"Warehouse A":
			at = Vector3(44,0.05,1); camera = Vector3(38,1.6,3); target = Vector3(47,1.6,2)
		"Warehouse B":
			at = Vector3(80.5,0.05,1); camera = Vector3(74,1.6,3); target = Vector3(83,1.6,2)
		"Locomotive cab":
			at = game.train.get_node("Locomotive").to_global(Vector3(-2.7,1.05,0))
			camera = at+Vector3.UP*1.6; target = camera+Vector3(2,-0.3,-0.4)
		"Passenger car":
			at = game.train.get_node("CrewCar").to_global(Vector3(-2.5,1.05,0))
			camera = at+Vector3.UP*1.6; target = camera+Vector3(7,0,0)
		"Curved railway":
			at = game.train.get_node("CrewCar").to_global(Vector3(0,1.05,0))
			camera = at+Vector3(-9,6,14); target = at+Vector3(5,0,0)
		"Ashford Depot", "Ashford workshop", "Blackwater Crossing":
			var station: Node3D = journey.stations[1 if location == "Blackwater Crossing" else 0]
			at = station.to_global(Vector3(-12,1.05,3))
			# Face the occupied yard and building entrances, including their props
			# and signs, rather than measuring only the plain rear walls.
			camera = station.to_global(Vector3(-4,4,47)); target = station.to_global(Vector3(22,2,24))
			if location == "Blackwater Crossing":
				camera = station.to_global(Vector3(-6,3.1,40)); target = station.to_global(Vector3(12,1.8,22))
			if location == "Ashford workshop":
				at = station.to_global(Vector3(122,.05,41)); camera = at+Vector3(3,1.6,0); target = station.to_global(Vector3(119,1.6,35))
		"Near advancing fog", "Inside dangerous fog":
			fog.simulation.front = -65.0 if location == "Near advancing fog" else 40.0
			camera = Vector3(18,3.2,6); target = Vector3(-35,2,-3.5)
			fog.presentation._blend = 0.7 if location == "Near advancing fog" else 1.0
		"Mission completion":
			at = game.train.get_node("CrewCar").to_global(Vector3(0,1.05,0))
			camera = at+Vector3(-9,6,14); target = at
			journey.mission.status = "escaped"
			journey.ui.show_results()
	game.player.teleport_to(at,Vector3.RIGHT)
	var track := game.get_node_or_null("RouteTrack")
	if track != null: track._update_visibility()
	if location != "Mission completion":
		# Establish real floor/car support before freezing this static fixture.
		# Keep the measurement camera at its previous view until settling ends,
		# so the new view's first draw remains in the entry-frame samples.
		game.player.set_physics_process(true)
		for tick in 10: await physics_frame
		game.player.set_physics_process(false)
	if journey != null:
		fog.train_progress = game.train.distance
		fog.players.local.exposure.progress = journey.route.project(at)
		fog.set_state(int(fog.simulation.danger(fog.players.local.exposure.progress)))
	eye.global_position = camera
	eye.look_at(target)
	# Cab/car views sit at eye height. The fixture camera bypasses the normal
	# rig's visibility update, so apply its first-person body rule explicitly;
	# otherwise these measurements render the inside of the survivor's head.
	var first_person := location in ["Locomotive cab", "Passenger car"]
	game.camera_rig.exploration.request_perspective(0 if first_person else 1)
	game.player.visual.visible = not first_person
	game.hud._refresh_context()
	if location == "Curved railway":
		game.train.start()
		game.train.set_physics_process(true)
		game.player.set_physics_process(true)

func measure(location: String, preset: int, stage: String, count: int) -> void:
	if not trace_stage.is_empty():
		FileAccess.open(trace_stage,FileAccess.WRITE).store_string(JSON.stringify({"phase":["Low","Medium","High"][preset]+"/"+location+"/"+stage,"ticks_ms":Time.get_ticks_msec()}))
	var values: Array[float] = []
	var frame_timeline: Array = []
	var pipeline_samples: Array = []
	var sums := {"draw_calls":0.0,"primitives":0.0,"process_ms":0.0,"physics_ms":0.0,"render_cpu_ms":0.0,"render_gpu_ms":0.0,"texture_bytes":0.0,"static_memory_bytes":0.0}
	var before := pipelines()
	var last := Time.get_ticks_usec()
	for i in count:
		if location == "Curved railway":
			fog.train_progress = game.train.distance
			var car: Node3D = game.train.get_node("Locomotive")
			eye.global_position = car.global_position+Vector3(-9,6,14)
			eye.look_at(car.global_position+Vector3.UP)
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		values.append((now-last)/1000.0)
		last = now
		frame_timeline.append(timeline.latest.duplicate())
		pipeline_samples.append(pipelines())
		sums.primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		sums.draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		sums.process_ms += Performance.get_monitor(Performance.TIME_PROCESS)*1000
		sums.physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
		sums.render_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
		sums.render_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		sums.texture_bytes += Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
		sums.static_memory_bytes += OS.get_static_memory_usage()
	var mean := 0.0
	for value in values: mean += value/values.size()
	var sorted := values.duplicate()
	sorted.sort()
	var delta := pipelines()
	for key in delta: delta[key] -= before[key]
	var row := {"location":location,"preset":["Low","Medium","High"][preset],"stage":stage,"samples":count,"mean_ms":mean,"fps_from_mean":1000.0/mean,
		"p50_ms":percentile(sorted,0.5),"p95_ms":percentile(sorted,0.95),"p99_ms":percentile(sorted,0.99),"worst_ms":sorted[-1],"frames_ms":values,
		"pipeline_delta":delta,"render_scale":root.scaling_3d_scale,"timeline":frame_timeline,"pipeline_samples":pipeline_samples,
		"frames_over_33_3_ms":values.filter(func(v):return v>33.3).size(),"frames_over_50_ms":values.filter(func(v):return v>50.0).size(),"frames_over_100_ms":values.filter(func(v):return v>100.0).size()}
	for key in sums: row[key] = sums[key]/count
	rows.append(row)
	if partial_report != null:
		partial_report.store_line(JSON.stringify(row))
		partial_report.flush()
	print("[integration-benchmark] ",location," / ",row.preset," / ",stage," mean=",mean," p99=",row.p99_ms," pipelines=",delta)

func percentile(values: Array, fraction: float) -> float:
	return values[mini(ceili(values.size()*fraction)-1,values.size()-1)]

func ready_render() -> void:
	if game.graphics.has_method("wait_for_render_ready"): await game.graphics.wait_for_render_ready()

func frames(count: int) -> void:
	for i in count: await RenderingServer.frame_post_draw

func pipelines() -> Dictionary:
	return {"draw":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW),"surface":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE),"specialization":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)}
