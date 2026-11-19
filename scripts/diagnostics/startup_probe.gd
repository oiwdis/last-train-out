extends SceneTree
## Starts with no Game-typed member/preload: loading the mission is measured,
## unlike the exported mechanics self-test's own parsing/fixture overhead.
var destination := "/tmp/lto-startup.json"
var events: Array = []
var settle_frames := 30

func mark(label: String) -> void:
	var row := {"phase":label,"ticks_ms":Time.get_ticks_msec(),"static_bytes":OS.get_static_memory_usage(),
		"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
	events.append(row)
	print("[startup] ",JSON.stringify(row))

func _initialize() -> void:
	mark("script_initialized")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): destination = arg.trim_prefix("--out=")
	run.call_deferred()

func run() -> void:
	mark("load_begin")
	var packed: PackedScene = load("res://scenes/missions/harlow_escape.tscn")
	mark("load_end")
	var game: Node = packed.instantiate()
	mark("instantiate_end")
	root.add_child(game)
	mark("add_child_end")
	var graphics: Node = game.get("graphics")
	await graphics.call("wait_for_render_ready")
	for i in 3: await physics_frame
	mark("mission_ready")
	for i in settle_frames:
		if DisplayServer.get_name() == "headless": await process_frame
		else: await RenderingServer.frame_post_draw
	var report := {"events":events,"godot":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),
		"headless":DisplayServer.get_name()=="headless","mission_ready":bool(game.get("journey").get("ready_to_play")),
		"user_data_directory":OS.get_user_data_dir(),
		"phases":PerformanceTrace.events}
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	game.queue_free()
	await process_frame
	await process_frame
	packed = null
	quit()
