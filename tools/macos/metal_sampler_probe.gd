extends SceneTree
## First reproduce on a lone camera. Only then add a deterministic textured
## surface to compare every output pixel across independent Metal processes.
var output := ""
var variant := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
	run.call_deferred()

func draw() -> void:
	for frame in 5: await RenderingServer.frame_post_draw

func apply_scale(value: float) -> void:
	root.scaling_3d_scale = value


func run() -> void:
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	await draw()
	print("[probe] camera only, scale 1.0")
	apply_scale(0.65)
	await draw()
	print("[probe] camera only, scale 0.65 complete")
	if variant == "explicit-invalid":
		var device := RenderingServer.get_rendering_device()
		var sampler := RDSamplerState.new()
		sampler.lod_bias = -0.5
		var rid := device.sampler_create(sampler)
		device.free_rid(rid)
	var image := Image.create_empty(256, 256, true, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			image.set_pixel(x, y, Color.WHITE if (x / 4 + y / 4) % 2 == 0 else Color(0.15,0.25,0.45))
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.uv1_scale = Vector3(8, 8, 1)
	var quad := MeshInstance3D.new()
	quad.mesh = QuadMesh.new()
	quad.material_override = material
	root.add_child(quad)
	quad.position = Vector3(0, 0, -1)
	quad.rotation.y = 0.52
	var frames := []
	for scale: float in [0.65, 0.85, 1.0, 720.0 / 1800, 1080.0 / 1512, 0.65]:
		apply_scale(scale)
		await draw()
		var capture := root.get_texture().get_image()
		if capture == null or capture.is_empty() or capture.get_size() != root.size:
			quit(1)
			return
		var name := "%d.png" % frames.size()
		if capture.save_png(output.path_join(name)) != OK:
			quit(1)
			return
		frames.append({"file":name,"scale":root.scaling_3d_scale,"bias":root.texture_mipmap_bias})
	var report := {"frames":frames,"variant":variant,"method":RenderingServer.get_current_rendering_method(),
		"driver":RenderingServer.get_current_rendering_driver_name(),"adapter":RenderingServer.get_video_adapter_name()}
	FileAccess.open(output.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	quad.free()
	camera.free()
	quit()
