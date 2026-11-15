class_name EnvironmentArt
extends Node3D
## Authored architecture and freight meshes. Existing collision/interaction nodes
## remain authoritative; windows are parented to their own cutaway wall.

const KIT := preload("res://assets/environment/factory_kit.glb")
const CONTAINER := preload("res://assets/environment/freight_container.glb")
const BOX_VAN := preload("res://assets/environment/parked_box_van.glb")
const HALL_ROOF := preload("res://assets/environment/waiting_hall_roof.glb")
const HOUSE_ROOF := preload("res://assets/environment/station_house_roof.glb")
const BENCH := preload("res://assets/environment/painted_wooden_bench.glb")
const WEED := preload("res://assets/environment/weed_plant_02.glb")
const DEBRIS := preload("res://assets/environment/broken_pallet.glb")
static var _shared_materials: Dictionary = {}

var _kit: Node3D
var _liner_mesh: Mesh
var _foliage_batches: Dictionary = {}
var _architecture_batches: Dictionary = {}
var replaced_containers := 0
var replaced_windows := 0

func build(station: Station) -> void:
	_kit = KIT.instantiate()
	_station_house(station.get_node("Background"))
	_waiting_hall(station.get_node("ExplorationDistrict"))
	for title in ["WarehouseA", "WarehouseB"]:
		_warehouse(station.get_node(title), title == "WarehouseB")
	_structural_steel(station)
	for title in ["FreightCarA", "FreightCarB"]:
		var car := station.get_node(title) as Node3D
		for part in car.get_children():
			if part is BoxPart:
				part.show_mesh = false
			elif part is MeshInstance3D or part.name in [&"Wheels", &"FreightCarDetails"]:
				part.hide()
		place(car, BOX_VAN, Vector3.ZERO, "AuthoredBoxVan")
	var district := station.get_node("ExplorationDistrict")
	for part in district.get_children():
		if part is BoxPart and String(part.name).begins_with("CargoContainer"):
			part.show_mesh = false
			place(district, CONTAINER, part.position-Vector3(0,1.35,0), "AuthoredContainer")
			replaced_containers += 1
		elif String(part.name).begins_with("ContainerFittings"):
			part.hide()
	# Sparse plants at wall feet and container edges. No transparency blending,
	# no physics, no per-frame updates, and small spatial visibility bounds.
	for x in range(31, 126, 3):
		_weed(Vector3(x,0.035,8.7+sin(x*1.7)*.18), .3+fposmod(x*.17,.25), x*.9)
	for x in range(103, 121, 2):
		_weed(Vector3(x,0.035,13.0+sin(x)*.2), .4, x)
	for x in [5.3, 9.1, 12.3, 26.6]:
		_weed(Vector3(x,0.03,7.7), .35, x)
	_flush_foliage()
	_flush_architecture()
	_kit.free()
	_kit = null

static func place(parent: Node3D, scene: PackedScene, at: Vector3, title: String, size := Vector3.ONE, yaw := 0.0) -> Node3D:
	var asset := scene.instantiate() as Node3D
	_apply_shared_materials(asset)
	asset.name = title
	asset.position = at
	asset.scale = size
	asset.rotation.y = yaw
	parent.add_child(asset, true)
	return asset

static func _apply_shared_materials(asset: Node3D) -> void:
	# Original meshes reference the existing scanned textures by material name.
	# The GLBs deliberately omit duplicate image payloads; every roof, van, locker
	# and container shares one GPU texture set instead of importing copies per GLB.
	var sources := {
		"Weathered red oxide steel": "environment_painted_steel",
		"Seasoned freight timber": "floor_wood",
		"Corroded roofing sheets": "roof_metal",
		"Weathered concrete coping": "platform_concrete",
		"Station gable brickwork": "wall_brick",
	}
	for mesh: MeshInstance3D in asset.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null or not sources.has(source.resource_name):
				continue
			if not _shared_materials.has(source.resource_name):
				var material := load("res://resources/materials/%s.tres" % sources[source.resource_name]).duplicate() as StandardMaterial3D
				material.resource_name = source.resource_name
				material.uv1_triplanar = false
				material.uv1_scale = Vector3.ONE
				if source.resource_name == "Station gable brickwork":
					material.cull_mode = BaseMaterial3D.CULL_DISABLED
				_shared_materials[source.resource_name] = material
			mesh.mesh.surface_set_material(surface,_shared_materials[source.resource_name])

func _module(parent: Node3D, title: String, at: Vector3, size := Vector3.ONE, yaw := 0.0) -> void:
	var source := _kit.find_child(title + "_Root", true, false) as Node3D
	assert(source != null, "Missing factory module " + title)
	var key := "%d/%s" % [parent.get_instance_id(),title]
	if not _architecture_batches.has(key):
		_architecture_batches[key] = {"parent":parent,"source":source,"title":title,"poses":[]}
	_architecture_batches[key].poses.append(Transform3D(Basis(Vector3.UP,yaw).scaled_local(size),at))

func _flush_architecture() -> void:
	# Each wall owns its batches, so cutaways never affect another building.
	# Imported ArrayMesh LODs and single-material surfaces are retained verbatim.
	for key: String in _architecture_batches:
		var entry: Dictionary = _architecture_batches[key]
		var root := Node3D.new()
		root.name = entry.title
		entry.parent.add_child(root,true)
		for mesh: MeshInstance3D in entry.source.find_children("*","MeshInstance3D",true,false):
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.mesh = mesh.mesh
			if entry.parent.get_meta("damaged_glazing",false) and entry.title == "FacadeWindow" and mesh.mesh.surface_get_material(0).resource_name.contains("glass"):
				multi.mesh = _broken_glass(mesh.mesh)
			multi.instance_count = entry.poses.size()
			for index in multi.instance_count:
				multi.set_instance_transform(index,entry.poses[index]*mesh.transform)
			var batch := MultiMeshInstance3D.new()
			batch.name = mesh.name
			batch.multimesh = multi
			root.add_child(batch)
	_architecture_batches.clear()

func _station_house(background: Node3D) -> void:
	for child in background.get_children():
		if child is MeshInstance3D and (String(child.name).begins_with("StationHouse") or String(child.name).begins_with("StationWindow")):
			child.hide()
	# The old wall-sized block is replaced by a complete four-sided masonry shell.
	var house := Node3D.new()
	house.name = "AuthoredStationHouse"
	background.add_child(house)
	for side in [-1.0, 1.0]:
		for row in 2:
			for bay in 6:
				_module(house, "FacadeWindow", Vector3(4+(bay+.5)*16/6, row*4.2, -9.6+side*2.5), Vector3(16.0/18,1.4,1), 0 if side>0 else PI)
		for row in 2:
			for bay in 2:
				_module(house, "FacadeWindow", Vector3(12+side*8,row*4.2,-12.1+(bay+.5)*2.5), Vector3(2.5/3,1.4,1), side*PI/2)
	for y in [0.15,4.2,8.35]:
		for bay in 6:
			_module(house, "Plinth" if y<1 else "Cornice", Vector3(4+(bay+.5)*16/6,y,-7.09), Vector3(16.0/18,1,1))
	place(house,HOUSE_ROOF,Vector3(12,8.4,-9.6),"PitchedStationRoof")
	# Preserve the clock/sign, remove only obsolete strips around the old facade.
	# CityDetails is shared with distant scenery, so its existing clock stays.

func _waiting_hall(district: Node3D) -> void:
	for part in district.get_children():
		if part is BoxPart and (String(part.name).begins_with("PitchedRoof") or String(part.name).begins_with("RoofBeam") or String(part.name).begins_with("WaitingBench") or String(part.name).begins_with("BenchBack") or String(part.name).begins_with("BenchLeg") or String(part.name).begins_with("StoneMullion")):
			part.show_mesh = false
	place(district,HALL_ROOF,Vector3(16,4.08,12.5),"AuthoredHallRoof")
	for span in [[6.5,2.84],[9.5,2.84],[12.25,2.34],[18.25,3.34],[21.75,3.34],[25.25,3.34]]:
		_module(district,"Window",Vector3(span[0],1.95,7.82),Vector3(span[1]/2.22,1.7/1.744694,1),PI)
	for x in [8.0,12.0,24.0]:
		for z in [10.5,15.7]:
			# Fit the 1.165 m source bench to the existing 2.1 m seating volume.
			place(district,BENCH,Vector3(x,0.035,z),"AuthoredWaitingBench",Vector3(1.8,1.2,1.1),PI)
	for at in [Vector3(5.4,.02,16.5),Vector3(26.3,.02,16.3)]:
		place(district,DEBRIS,at,"AbandonedPallet",Vector3.ONE*.65)

func _warehouse(building: Node3D, damaged: bool) -> void:
	var length := 30.0 if damaged else 25.0
	var height := 5.5 if damaged else 7.4
	var front := building.get_node("FrontWall") as CutawayWall
	front.set_meta("damaged_glazing",damaged)
	for child in front.get_children():
		if child is BoxPart:
			child.show_mesh = false
		elif child is Node3D:
			child.hide()
	var bays := 10 if damaged else 8
	for row in 2:
		for bay in bays:
			_module(front,"FacadeWindow" if row == 1 else "FacadeSolid",Vector3((bay+.5)*length/bays,row*height/2,4.88),Vector3(length/bays/3,height/6,1))
	for bay in bays:
		_module(front,"Cornice",Vector3((bay+.5)*length/bays,height,4.88),Vector3(length/bays/3,1,1))
	# One recessed loading bay sits over a solid collision span, outside all doors.
	_module(front,"LoadingBay",Vector3(length*.5,0.02,4.91),Vector3(1,.92,1))
	var sign := DetailBuilder.new(front,"WarehouseIdentification")
	sign.signboard(Vector3(length*.5,height-.55,5.02),"B / TRANSFER HALL" if damaged else "A / BONDED STORES",7,.65,DetailBuilder.PALE)
	sign.finish()
	var back := building.get_node("BackWall") as CutawayWall
	for part in back.get_children():
		if part is BoxPart and String(part.name).begins_with("WallSeg"):
			part.material = preload("res://resources/materials/wall_brick.tres")
		if (part is BoxPart or part is BoxVisual) and (String(part.name).begins_with("Glass") or String(part.name).begins_with("Window")):
			var at: Vector3 = part.position
			var size: Vector3 = part.size
			if part is BoxPart:
				part.show_mesh = false
			else:
				part.hide()
			at.z = -1.12
			_module(back,"BrokenWindow" if damaged else "Window",at,Vector3(size.x/2.22,size.y/1.744694,1))
			replaced_windows += 1
	# Weathered timber fragments lie against closed end walls, not in route gaps.
	for x in [1.1,length-1.1]:
		place(building,DEBRIS,Vector3(x,.035,4.25),"WarehouseDebris",Vector3(.7,.7,.7),x)
	if damaged:
		place(building,DEBRIS,Vector3(16.8,.035,4.1),"BrokenLoadingPallet",Vector3.ONE,.2)
		_deterioration(building)

func _structural_steel(station: Station) -> void:
	var steel := preload("res://resources/materials/environment_painted_steel.tres")
	for part in station.find_children("*Pillar*", "BoxPart", true, false):
		part.show_mesh = false
		var column := MeshInstance3D.new()
		column.name = "BoltedSteelColumn"
		column.mesh = FabricatedMesh.steel_column(part.size, steel)
		part.add_child(column)
	var yard := station.get_node("FreightYard")
	for part in yard.get_children():
		if part is BoxVisual and String(part.name).begins_with("GantryLeg"):
			part.mesh = FabricatedMesh.steel_column(part.size, steel)
	var deck := yard.get_node("GantryDeck") as BoxPart
	deck.show_mesh = false
	var d := DetailBuilder.new(deck,"WeldedGratingAndRails")
	for x in range(18):
		d.box(Vector3(-.8+x*.094,.085,0),Vector3(.018,.03,1.98),DetailBuilder.STEEL)
	for z in range(12):
		d.box(Vector3(0,.055,-.96+z*.175),Vector3(1.68,.04,.016),DetailBuilder.STEEL)
	for side in [-1.0,1.0]:
		d.box(Vector3(side*.82,-.035,0),Vector3(.06,.16,2.0),DetailBuilder.INK)
		for z in [-.96,.96]:
			d.cylinder(Vector3(side*.81,.58,z),.024,1.0,DetailBuilder.AMBER)
		for y in [.55,1.08]:
			d.beam(Vector3(side*.81,y,-.96),Vector3(side*.81,y,.96),.038,DetailBuilder.STEEL)
	for y in [.55,1.08]:
		d.beam(Vector3(-.81,y,-.96),Vector3(.81,y,-.96),.038,DetailBuilder.STEEL)
	# The ladder-facing end stays open at its existing exit; no new colliders.
	d.finish()

func _deterioration(building: Node3D) -> void:
	var d := DetailBuilder.new(building,"TransferHallDamage")
	# A failed roof bay and its debris share the same end-wall footprint. Keep
	# the middle aisle and all cache approaches clear of art and collision.
	for x in [1.0,2.15,3.3]:
		d.beam(Vector3(x,5.12,3.8),Vector3(x+.18,4.05,4.6),.055,DetailBuilder.RUST)
	for x in [5.8,14.5]:
		var sheet := MeshInstance3D.new()
		sheet.name = "BuckledCeilingLiner"
		sheet.mesh = _buckled_sheet()
		sheet.position = Vector3(x,5.35,4.64)
		building.add_child(sheet,true)
	place(building,DEBRIS,Vector3(6.1,.035,4.42),"FallenLinerDebris",Vector3(.65,.65,.45),.7)
	for index in 9:
		var x := 1.0+index*.23
		d.box(Vector3(x,.055+fposmod(index*.017,.06),4.35),Vector3(.4,.055,.16),Color("5f5042"),Vector3(.1,index*.63,.07))
	d.signboard(Vector3(4.2,1.65,4.62),"ROOF UNSAFE  /  BAY CLOSED",2.4,.28,Color("baa270"),PI)
	for at in [Vector3(1.2,.07,4.2),Vector3(28.8,.07,4.3)]:
		AssetDressing.place(building,"oil_can",at,Vector3.ONE*.8)
	# Broken conduit hangs above the route, paired with the intact wall fixtures.
	d.beam(Vector3(17,4.1,-.91),Vector3(18.6,3.85,-.88),.025,DetailBuilder.INK)
	d.beam(Vector3(18.6,3.85,-.88),Vector3(18.9,3.1,-.66),.025,DetailBuilder.INK)
	d.finish()

func _buckled_sheet() -> Mesh:
	if _liner_mesh != null:
		return _liner_mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := FabricatedMesh.planar_material(preload("res://resources/materials/roof_metal.tres")).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	for x in 24:
		for y in 10:
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
				var u: float = (x+corner.x)/24.0
				var v: float = (y+corner.y)/10.0
				# Folded corrugations, a sagging free edge and an irregular tear.
				var drop: float = v*v*(.7+.18*sin(u*9))
				var edge: float = .15*sin(u*27)*v*v
				var point := Vector3((u-.5)*2.2,-drop+sin(u*TAU*12)*.025,-v*.85+edge)
				surface.set_uv(Vector2(u*1.1,v*.5))
				surface.add_vertex(point)
	surface.generate_normals()
	surface.generate_tangents()
	surface.index()
	_liner_mesh = surface.commit()
	return _liner_mesh

func _broken_glass(source: Mesh) -> Mesh:
	var arrays := source.surface_get_arrays(0).duplicate()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	for triangle in range(0,indices.size(),3):
		var centre := (vertices[indices[triangle]]+vertices[indices[triangle+1]]+vertices[indices[triangle+2]])/3
		if centre.x > -.35 and centre.y < 1.71:
			for corner in 3:
				kept.append(indices[triangle+corner])
	arrays[Mesh.ARRAY_INDEX] = kept
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,source.surface_get_material(0))
	return mesh

func _weed(at: Vector3, size: float, yaw: float) -> void:
	var key := floori(at.x/20)
	if not _foliage_batches.has(key):
		_foliage_batches[key] = []
	_foliage_batches[key].append(Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3.ONE*size*6),at-Vector3(key*20,0,0)))

func _flush_foliage() -> void:
	var source := WEED.instantiate()
	var template := source.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	for material_index in template.mesh.get_surface_count():
		var material := template.mesh.surface_get_material(material_index) as StandardMaterial3D
		if material != null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = .45
	for key: int in _foliage_batches:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = template.mesh
		multi.instance_count = _foliage_batches[key].size()
		for index in multi.instance_count:
			multi.set_instance_transform(index,_foliage_batches[key][index]*template.transform)
		var batch := MultiMeshInstance3D.new()
		batch.name = "VergePlants%d" % key
		batch.multimesh = multi
		batch.position.x = key*20
		batch.visibility_range_end = 35
		batch.visibility_range_end_margin = 5
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(batch)
	source.free()
	_foliage_batches.clear()
