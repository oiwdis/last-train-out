extends SceneTree
func _initialize() -> void:
	var config := FogConfig.new()
	var sim := FogSimulation.new(config, preload("res://resources/fog/harlow_route.tres"))
	var actors: Array[FogExposure] = []
	for i in 4:
		actors.append(FogExposure.new())
	var started := Time.get_ticks_usec()
	for i in 100000:
		sim.step()
		for actor in actors:
			actor.health = 100
			actor.dead = false
			actor.tick(0.1, 10, 0.25, config)
	var elapsed := Time.get_ticks_usec() - started
	var report := {"processor": OS.get_processor_name(), "os": OS.get_name(), "godot": Engine.get_version_info().string,
		"ticks": 100000, "players": 4, "total_ms": elapsed / 1000.0, "microseconds_per_tick": elapsed / 100000.0,
		"includes": "simulation, seeded events and four exposure components; excludes route projection, rendering and scene integration"}
	FileAccess.open("res://docs/validation/milestone3/performance-simulation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	for actor in actors:
		actor.free()
	quit()
