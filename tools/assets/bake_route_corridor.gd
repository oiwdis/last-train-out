extends SceneTree
## godot --headless --path . --script res://tools/assets/bake_route_corridor.gd
## Save static draw batches and matching collision before the game is exported.
func _initialize() -> void:
	bake.call_deferred()

func bake() -> void:
	var route := JourneyDefinition.new().build_route()
	var builder := RouteTrack.new()
	builder.route = route
	root.add_child(builder)
	builder.generate_corridor()
	var corridor := Node3D.new()
	corridor.name = "BakedCorridor"
	corridor.set_meta("geometry_key",RouteTrack.geometry_key(route))
	root.add_child(corridor)
	for chunk in builder.chunks:
		chunk.reparent(corridor,false)
		own(chunk,corridor)
	var pack := PackedScene.new()
	var result := pack.pack(corridor)
	if result == OK:
		result = ResourceSaver.save(pack,"res://resources/journey/rail_corridor.scn",ResourceSaver.FLAG_COMPRESS)
	print("Baked ",corridor.get_child_count()," terrain/collision chunks, result ",error_string(result))
	corridor.free()
	builder.free()
	RouteVerge.clear_cache()
	FabricatedMesh.clear_cache()
	quit(result)

func own(node: Node, scene: Node) -> void:
	node.owner = scene
	for child in node.get_children():
		own(child,scene)
