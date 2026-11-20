extends SceneTree
## Exercise the optional GI composition path with a lit room, then re-enable it.
var out: String
var environment := Environment.new()
var world := Node3D.new()

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	run.call_deferred()

func box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if at.x < -1.0:
		material.emission_enabled = true
		material.emission = Color(0.9, 0.04, 0.02)
		material.emission_energy_multiplier = 8.0
	mesh.mesh = shape
	mesh.material_override = material
	mesh.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	world.add_child(mesh)
	mesh.position = at

func run() -> void:
	var env := WorldEnvironment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.05, 0.06)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.17, 0.16, 0.15)
	environment.sdfgi_cascades = 4
	environment.sdfgi_min_cell_size = 0.2
	environment.sdfgi_energy = 5.0
	environment.sdfgi_read_sky_light = false
	env.environment = environment
	environment.ambient_light_energy = 0.05
	root.add_child(world)
	world.add_child(env)
	box(Vector3(0,-0.1,0), Vector3(6,0.2,6), Color(0.62,0.64,0.67))
	box(Vector3(-2,1.3,0), Vector3(0.2,3,5), Color(0.82,0.12,0.07))
	box(Vector3(0,1,-2), Vector3(5,2,0.2), Color(0.60,0.62,0.57))
	box(Vector3(0,0.5,0), Vector3.ONE, Color(0.75,0.71,0.48))
	var light := OmniLight3D.new()
	light.light_bake_mode = Light3D.BAKE_STATIC
	light.light_energy = 2.0
	light.omni_range = 8.0
	world.add_child(light)
	light.position = Vector3(-0.7,2,0.6)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(2.7,1.9,3.1)
	camera.look_at(Vector3(0,0.7,0))
	camera.make_current()
	DirAccess.make_dir_recursive_absolute(out)
	var frames := []
	for stage in ["off", "enabled", "off-again", "enabled-again"]:
		environment.sdfgi_enabled = stage.begins_with("enabled")
		for i in 60: await RenderingServer.frame_post_draw
		print(stage, " env=", camera.get_world_3d().environment == environment, " sdfgi=", environment.sdfgi_enabled, " pipelines=", Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION), " draws=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		var img := root.get_texture().get_image()
		if img == null or img.is_empty() or img.save_png(out.path_join(stage+".png")) != OK:
			quit(1)
			return
		var digest := HashingContext.new()
		digest.start(HashingContext.HASH_SHA256)
		digest.update(img.get_data())
		frames.append({"stage":stage, "rgba_sha256":digest.finish().hex_encode(),
			"sdfgi":environment.sdfgi_enabled, "active_environment":camera.get_world_3d().environment == environment})
	FileAccess.open(out.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"driver":RenderingServer.get_current_rendering_driver_name(), "binary":OS.get_executable_path().get_file(),"stages":frames}))
	world.free()
	for i in 3: await process_frame
	quit()
