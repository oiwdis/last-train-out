extends SceneTree
## Standalone diagnostic. The runner supplies a tiny project containing this script
## and the game's fog shader. No gameplay scene, autoload, imported prop or audio.
var variant := "control"
var out := ""
var stage_file: FileAccess
var world := Node3D.new()
var objects := Node3D.new()
var camera := Camera3D.new()
var images: Array[Image] = []
var textures: Array[ImageTexture] = []
var intervals: Array[float] = []
var last_tick := 0
var high := true

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	high = variant != "medium"
	stage_file = FileAccess.open(out + ".jsonl", FileAccess.WRITE)
	run.call_deferred()

func mark(label: String) -> void:
	stage_file.store_line(JSON.stringify({"phase":label, "us":Time.get_ticks_usec(),
		"textures":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"pipelines":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW),
		"specializations":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)}))
	stage_file.flush()

func frames(count: int) -> void:
	for frame in count:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		intervals.append((now - last_tick) / 1000.0)
		last_tick = now

func readback() -> bool:
	var image := root.get_texture().get_image()
	return image != null and not image.is_empty()

func upload() -> void:
	for image in images:
		textures.append(ImageTexture.create_from_image(image))
	mark("uploaded")

func add_surface(index: int) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = textures[index]
	mat.metallic = index * 0.25
	mat.roughness = 0.65
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.material_override = mat
	mesh.position.x = (index - 1) * 1.2
	objects.add_child(mesh)

func run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.msaa_3d = Viewport.MSAA_2X if high else Viewport.MSAA_DISABLED
	root.scaling_3d_scale = 1.0 if high else 0.85
	root.add_child(world)
	world.add_child(camera)
	camera.position = Vector3(0, 1, 5)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -35, 0)
	light.shadow_enabled = true
	world.add_child(light)
	for index in 3:
		var image := Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
		image.fill(Color.from_hsv(index / 3.0, 0.6, 0.8))
		images.append(image)
	if variant == "preupload": upload()
	last_tick = Time.get_ticks_usec()
	await frames(3)
	if variant == "sync-before" and not readback():
		quit(2)
		return
	if variant != "preupload": upload()
	world.add_child(objects)
	if variant != "no-fog":
		var fog := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(5, 2)
		fog.mesh = quad
		var material := ShaderMaterial.new()
		material.shader = load("res://fog_front.gdshader")
		fog.material_override = material
		fog.position.z = 0.8
		objects.add_child(fog)
	mark("activation")
	if variant != "sync-before" and not readback():
		quit(2)
		return
	# Equal numbers of presented frames. Only the schedule of object admission
	# changes in the batched case. Removal can intersect the preparation workload.
	for index in 3:
		if variant == "batch":
			if index == 0:
				for surface in 3: add_surface(surface)
		else: add_surface(index)
		if variant != "no-preparation":
			camera.position.x = (index - 1) * 1.5
			camera.look_at(Vector3.ZERO)
		await frames(2)
		if index == 1 and variant == "early-retire":
			# Retire submitted surfaces while the next one is still pending.
			for child in objects.get_children(): child.queue_free()
	camera.position.x = 0
	camera.look_at(Vector3.ZERO)
	await frames(12)
	mark("steady")
	objects.queue_free()
	await frames(3)
	var report := {"complete":true, "variant":variant, "frames_ms":intervals,
		"user_data_directory":OS.get_user_data_dir(), "resolution":str(root.size),
		"actual_method":RenderingServer.get_current_rendering_method(),
		"actual_driver":RenderingServer.get_current_rendering_driver_name(),
		"adapter":RenderingServer.get_video_adapter_name(), "ready_ms":Time.get_ticks_msec()}
	FileAccess.open(out, FileAccess.WRITE).store_string(JSON.stringify(report))
	world.queue_free()
	await frames(3)
	quit()
