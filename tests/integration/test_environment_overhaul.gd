extends TestSuite
## Inspect the exported mission, including the packaged route resources and physics.
var game: Game

func before_each() -> void:
	JourneyController.pending_load = {}
	game = await spawn_scene("res://scenes/missions/harlow_escape.tscn",10) as Game

func after_each() -> void:
	await free_spawned()

func test_harlow_running_head_web_sleepers_and_ballast_have_their_authored_materials() -> void:
	var track := game.station.get_node("MainLine") as Track
	var rails := track._visual_root.get_node("RunningRails").mesh as Mesh
	check_eq(rails.surface_get_material(0),RailFormation.WEB,"web and foot use oxidized steel")
	check_eq(rails.surface_get_material(1),track.rail_material,"polished head uses authored steel")
	check(track.sleeper_material.albedo_texture != null,"sleepers have a wood scan")
	check(track.ballast_material.albedo_texture != null,"ballast has a gravel scan")
	check(absf(track.global_position.x+track.length-game.journey.route.sample(RouteTrack.RAIL_START).x)<.01,"straight and swept line share their endpoint")
	var route_rails: Mesh = game.get_node("RouteTrack/BakedCorridor/Track_280/RunningRails").mesh
	check_eq(route_rails.surface_get_material(1),track.rail_material,"steel continues onto the swept line")

func test_bonded_stores_and_transfer_hall_have_closed_masonry_returns_and_open_doors() -> void:
	for name_of_building in ["WarehouseA","WarehouseB"]:
		var building := game.station.get_node(name_of_building) as Node3D
		var lining: MeshInstance3D = building.get_node("FrontWall/MasonryInnerLeaf")
		var footprint := lining.mesh.get_aabb()
		var left: BoxPart = building.get_node("Shell/LeftWallSeg3")
		var end := left.position.z + left.size.z*.5
		check(absf(footprint.position.z-end)<.002,"masonry begins at the end of the green wall")
		check(footprint.end.z>4.87,"return reaches the outer facade")
		check(left.square_edges,"side walls have square structural joints")
		var inside := Vector3(.10,1.8,4.4)
		var outside := Vector3(.10,1.8,5.0)
		var faces := lining.mesh.get_faces()
		var h := 7.4 if name_of_building == "WarehouseA" else 5.5
		var mid_bay := 25./16. if name_of_building == "WarehouseA" else 1.5
		var glass_center := Vector3(mid_bay,h*.5+h/6.*1.47,4.4)
		var glass_clear := true
		var faces_in := 0
		var faces_out := 0
		for n in range(0,faces.size(),3):
			if Geometry3D.segment_intersects_triangle(glass_center,glass_center+Vector3.BACK*.7,faces[n],faces[n+1],faces[n+2])!=null:
				glass_clear = false
			if Geometry3D.segment_intersects_triangle(inside,outside,faces[n],faces[n+1],faces[n+2])!=null:
				faces_in += 1
			if Geometry3D.segment_intersects_triangle(outside,inside,faces[n],faces[n+1],faces[n+2])!=null:
				faces_out += 1
		check(glass_clear,"masonry leaves the kit window clear")
		check(faces_in>0 and faces_out>0,"both viewpoints intersect closed geometry")
		var opening := building.to_global(Vector3(-.45,1.3,1.1))
		var query := PhysicsRayQueryParameters3D.create(opening,opening+Vector3.RIGHT*.8,1)
		query.exclude = [game.player.get_rid()]
		var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
		check(hit.is_empty() or hit.collider != left.get_parent(),"the authored side-door aperture stays open")

func test_curve_mesh_collision_and_neighboring_chunks_share_the_same_terrain() -> void:
	var track := game.get_node("RouteTrack") as RouteTrack
	check(track.has_node("BakedCorridor"),"the threaded mission loaded the static baked geometry")
	var count := RouteLandscape.OFFSETS.size()
	for i in range(1,track.chunks.size()):
		var left: PackedVector3Array = track.chunks[i-1].get_node("Ground").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var right: PackedVector3Array = track.chunks[i].get_node("Ground").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for col in count:
			check(left[left.size()-count+col].distance_to(right[col])<.003,"neighboring ground rims coincide")
	for along in [823.,849.,882.,2402.,2637.]:
		var frame := RouteTrack.frame(track.route,along)
		for side in [-75.,-17.,0.,14.,86.]:
			var sample := RouteLandscape.point(frame,along,side,track.route)
			var ray := PhysicsRayQueryParameters3D.create(sample+Vector3.UP*15.,sample-Vector3.UP*15.,1)
			var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
			check(not hit.is_empty(),"ground collision on both sides of every inspected curve")
			if not hit.is_empty():
				check(absf(hit.position.y-sample.y)<1.9 and hit.normal.y>.55,"ground follows the authored profile")
	var grounded := 0
	var worst_air := -INF
	for chunk in track.chunks:
		for batch in chunk.get_children():
			if not String(batch.name).begins_with("Copse"): continue
			var data: PackedFloat32Array = batch.multimesh.buffer
			for instance: int in batch.multimesh.instance_count:
				var n := instance*12
				var origin := Vector3(data[n+3],data[n+7],data[n+11])
				var query := PhysicsRayQueryParameters3D.create(origin+Vector3.UP*.35,origin-Vector3.UP*.35,1)
				var floor_hit := game.get_world_3d().direct_space_state.intersect_ray(query)
				if not floor_hit.is_empty():
					var separation: float = origin.y-floor_hit.position.y
					worst_air = maxf(worst_air,separation)
					if absf(separation+.045)<.018: grounded += 1
				check(not floor_hit.is_empty() and absf(origin.y-floor_hit.position.y+.045)<.018,
					"tree or scrub root meets its terrain triangle")
	check(grounded>1000,"route-wide foliage contact was inspected")
	note("Grounded %d roots, highest offset from ground %.3f m" % [grounded,worst_air])
	var ties: MultiMesh = track.get_node("BakedCorridor/Track_760/Ties").multimesh
	check(ties.instance_count>=170,"curved sleepers remain batched")
	check(ties.custom_aabb.size.x>80.,"saved culling bounds cover the chunk")
	var poses := ties.buffer
	check_eq(poses.size(),12*ties.instance_count,"every baked transform is present")
	if poses.size()>=12:
		check(poses[poses.size()-9]-poses[3]>80.,"baked sleepers extend along the actual rail")

func test_atmospheric_banks_and_station_landmarks_are_in_the_playable_mission() -> void:
	# Save validation may instantiate and discard a station without entering
	# the tree. A detached station must own no unparented physics objects.
	for scene in game.journey.definition.station_scenes:
		var unused := scene.instantiate() as JourneyStation
		check(unused.site == null,"an unused station allocates no physics body")
		unused.free()
	for station in game.journey.stations:
		check(station.site.get_parent() == station,"the occupied station owns its structural collider")
	var presentation := game.fog_system.presentation
	for layer in presentation.layers:
		check(layer.mesh.get_aabb().size.z>8.,"fog bank has depth across the valley")
		check(layer.material_override.get_shader_parameter("density_field") is Texture2D,"density field is assigned")
	check(game.journey.stations[0].has_node("AuthoredStationDetails/CoalTipple"),"Ashford coal landmark")
	check(game.journey.stations[1].has_node("AuthoredStationDetails/CrossingStoresFront"),"Blackwater evacuation stores")
