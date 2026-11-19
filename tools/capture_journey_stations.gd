extends SceneTree
## Clearly separate authored-world overview stills; not part of the gameplay video.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game := load("res://scenes/missions/harlow_escape.tscn").instantiate() as Game
	root.add_child(game)
	for tick in 12: await physics_frame
	game.journey.ui.toggle(true)
	for tick in 4: await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/validation/milestone3-finalization/route-save-menu.png")
	game.journey.ui.toggle(false)
	game.player.input.scripted = true
	game.player.set_physics_process(false)
	game.camera_rig.set_physics_process(false)
	game.camera_rig.exploration.set_process(false)
	game.fog_system.set_physics_process(false)
	game.journey.set_physics_process(false)
	game.graphics.set_preset(1)
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	for station in game.journey.stations:
		game.player.teleport_to(station.to_global(Vector3(0,0.05,55)))
		game.player.visual.hide()
		var camera := game.camera_rig.get_camera()
		camera.global_position = station.to_global(Vector3(-18,8,64) if station.industrial else Vector3(22,7,77))
		camera.look_at(station.to_global(Vector3(32,2,22) if station.industrial else Vector3(82,2,33)))
		camera.fov = 78
		for tick in 15: await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/validation/milestone3-finalization/"+station.station_id+"-overview.png")
	game.queue_free()
	await process_frame
	await process_frame
	quit()
