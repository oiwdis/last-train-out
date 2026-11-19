extends TestSuite
## Authored environment integration must preserve the existing traversal volumes.

var game: Game

func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn", 8) as Game
	game.player.input.scripted = true
	game.player.input.clear()

func after_each() -> void:
	await free_spawned()

func test_container_art_keeps_roof_and_ladder_collision_dimensions() -> void:
	var district := game.station.get_node("ExplorationDistrict")
	var count := 0
	for part in district.get_children():
		if part is BoxPart and String(part.name).begins_with("CargoContainer"):
			count += 1
			check(not part.show_mesh, "container blockout is removed")
			check_eq((part.shape as BoxShape3D).size,Vector3(6,2.7,2.5),"roof and wall collision unchanged")
			check(not part.disabled,"container still blocks movement")
	check_eq(count,3,"all original container routes preserved")
	check_eq((game.station.get_node("EnvironmentArt") as EnvironmentArt).replaced_containers,3,"each container has its replacement")
	check_eq(district.find_children("ContainerLadder*","Ladder",true,false).size(),3,"all three climbing routes preserved")

func test_box_vans_preserve_climbable_roofs_and_do_not_add_mesh_collision() -> void:
	for name in ["FreightCarA","FreightCarB"]:
		var car := game.station.get_node(name)
		var body := car.get_node("Body") as BoxPart
		var roof := car.get_node("Roof") as BoxPart
		check(not body.show_mesh and not roof.show_mesh,"closed van uses authored geometry")
		check_eq((body.shape as BoxShape3D).size,Vector3(6.8,2.7,2.6),"body collision unchanged")
		check_near(roof.position.y+roof.size.y/2,3.8,.001,"climb destination stays 3.8 m")
		var art := car.get_node("AuthoredBoxVan")
		check_eq(art.find_children("*","CollisionObject3D",true,false).size(),0,"decoration cannot introduce collision instability")
		var mesh := art.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
		var triangles := 0
		for surface in mesh.mesh.get_surface_count():
			triangles += mesh.mesh.surface_get_array_index_len(surface)/3
		check_less(triangles,40000,"source van stays within its mesh budget before generated LODs")

func test_cutaway_keeps_replaced_blockouts_hidden_and_restores_authored_windows() -> void:
	var front := game.station.get_node("WarehouseB/FrontWall") as CutawayWall
	var old := front.get_node("Window1") as BoxVisual
	var imported := front.find_child("FacadeWindow",true,false)
	check(not old.visible,"old decorative pane is not resurrected during collection")
	var mesh := imported.find_children("*","MultiMeshInstance3D",true,false)[0] as MultiMeshInstance3D
	check_eq(mesh.multimesh.instance_count,10,"repeated window modules share a wall-local draw")
	check(mesh.visible,"new source window starts visible")
	front.request_cut(self)
	await seconds(.5)
	check(not mesh.visible,"replacement fades with its own wall")
	front.release_cut(self)
	await seconds(.5)
	check(mesh.visible,"new architecture returns")
	check(not old.visible,"old blockout stays hidden after a cutaway round trip")
	check(not (front.get_node("Wall") as BoxPart).disabled,"fade never removes original collision")

func test_thirteen_searchable_models_retain_identity_and_loot_actions() -> void:
	check_eq(game.scavenging.containers.size(),13,"cache count unchanged")
	for cache in game.scavenging.containers:
		var model := cache.get_node("SearchableProp")
		check_greater(model.find_children("*","MeshInstance3D",true,false).size(),0,"cache has actual imported model geometry")
		check(not cache.cache_id.is_empty(),"cache identity preserved")
		check(cache._indicator != null and cache._label != null,"search state remains readable")
		check(cache.complete(),"search transaction works with replacement presentation")
		check(not cache.complete(),"search completion remains idempotent")

func test_architecture_and_foliage_follow_material_and_distance_budgets() -> void:
	var art := game.station.get_node("EnvironmentArt") as EnvironmentArt
	check_greater(art.replaced_windows,4,"both warehouses use recessed source windows")
	for batch: MultiMeshInstance3D in art.get_children():
		check_less(batch.visibility_range_end,40,"verge plants do not render across the whole map")
		var material := batch.multimesh.mesh.surface_get_material(0) as StandardMaterial3D
		check_eq(material.transparency,BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,"leaves avoid sorted alpha blending")
	var window := game.station.get_node("Background/AuthoredStationHouse").find_child("FacadeWindow",true,false)
	var mesh := window.find_children("*","MultiMeshInstance3D",true,false)[0] as MultiMeshInstance3D
	check_eq(mesh.multimesh.instance_count,32,"four station facades share source geometry")
	var material := mesh.multimesh.mesh.surface_get_material(0) as StandardMaterial3D
	game.graphics.set_preset(2)
	check(material.albedo_texture != null and material.normal_enabled,"High uses source UV/PBR maps")
	game.graphics.set_preset(0)
	check(not material.normal_enabled,"Low applies to new architecture")
	game.graphics.set_preset(1)
	check(material.normal_enabled,"Medium restores source normals")
	var shared_paint: StandardMaterial3D
	var painted := 0
	var district := game.station.get_node("ExplorationDistrict")
	for container in district.find_children("AuthoredContainer*","Node3D",false,false):
		for piece: MeshInstance3D in container.find_children("*","MeshInstance3D",true,false):
			for surface in piece.mesh.get_surface_count():
				var paint := piece.mesh.surface_get_material(surface) as StandardMaterial3D
				if paint.resource_name == "Weathered red oxide steel":
					painted += 1
					check(paint.albedo_texture != null and paint.normal_texture != null,"geometry-only GLB resolves its external runtime PBR maps")
					check(paint.albedo_texture.resource_path.contains("rusty_painted_metal"),"paint uses the intended weathered metal scan")
					check(not paint.uv1_triplanar,"authored metre UVs avoid extra triplanar samples")
					if shared_paint != null:
						check(paint == shared_paint,"containers share one material/texture set")
					shared_paint = paint
	check_eq(painted,3,"all three fitted containers have shaded paint")
