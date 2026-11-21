extends "res://scripts/diagnostics/integration_benchmark.gd"
## Apply one temporary change at a time to the packaged game's real grass material.
## Positions, scene, lighting and hazard state come from the shared review fixture.
func run() -> void:
	suite = "environment"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = load("res://scenes/missions/harlow_escape.tscn").instantiate()
	root.add_child(game)
	await ready_render()
	journey = game.journey
	fog = game.fog_system
	game.player.input.scripted = true
	for node: Node in [game.player,game.train,journey,fog,game.camera_rig]:
		node.set_physics_process(false)
	game.camera_rig.exploration.set_process(false)
	eye = Camera3D.new()
	eye.fov = 78
	eye.near = .06
	eye.far = 350
	game.add_child(eye)
	eye.make_current()
	game.graphics.set_preset(0)
	await ready_render()
	game.graphics.set_preset(1)
	await ready_render()
	var grass := load("res://resources/materials/railway_verge.tres") as StandardMaterial3D
	var env: Environment = game.graphics._atmosphere.get_environment()
	var light := game.find_children("*","DirectionalLight3D",true,false)[0] as DirectionalLight3D
	var flat := Image.create(8,8,false,Image.FORMAT_RGB8)
	flat.fill(Color(.5,.5,1))
	var neutral := ImageTexture.create_from_image(flat)
	var controls := [
		["control",grass,"normal_enabled",true], ["no_normal",grass,"normal_enabled",false],
		["neutral_normal",grass,"normal_texture",neutral], ["no_albedo_map",grass,"albedo_texture",null],
		["no_vertex_tint",grass,"vertex_color_use_as_albedo",false],
		["no_anisotropy",grass,"texture_filter",BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS],
		["flat_lighting",grass,"shading_mode",BaseMaterial3D.SHADING_MODE_UNSHADED],
		["no_sun_shadow",light,"shadow_enabled",false], ["no_glow",env,"glow_enabled",false],
		["native_scale",root,"scaling_3d_scale",1.], ["msaa_2x",root,"msaa_3d",Viewport.MSAA_2X],
		["no_atmospheric_fog",env,"fog_enabled",false], ["control_repeat",grass,"normal_enabled",true]]
	var measurements := []
	for location in ["Curved embankment","Crossing Stores"]:
		await place(location)
		for test in controls:
			var previous: Variant = test[1].get(test[2])
			test[1].set(test[2],test[3])
			await frames(32)
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			var basename: String = location.to_snake_case()+"-"+str(test[0])
			shot.save_png(output_dir.path_join(basename+".png"))
			shot.resize(240,135,Image.INTERPOLATE_NEAREST)
			var count := 0
			for y in shot.get_height():
				for x in shot.get_width():
					var color := shot.get_pixel(x,y)
					if maxf(color.r,maxf(color.g,color.b))<6./255.: count+=1
			measurements.append({"view":location,"control":test[0],"near_black_percent":100.*count/(240*135)})
			test[1].set(test[2],previous)
		FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(measurements,"  "))
	await DiagnosticSceneRetirement.release(game)
	quit()
