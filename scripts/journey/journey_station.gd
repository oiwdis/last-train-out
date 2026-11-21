class_name JourneyStation
extends Node3D
## Station content is a reusable scene, separate from route/fog/mission authority.
@export var station_id := "ashford"
@export var title := "ASHFORD INDUSTRIAL DEPOT"
@export var industrial := true
var caches: Array[SearchContainer] = []
var buildings: Array[StationBuilding] = []
var note: SupplyInteractable
var boarding_point: Vector3
var site: StaticBody3D

func _ready() -> void:
	site = StaticBody3D.new()
	site.name = "StationStructure"
	add_child(site)
	var concrete := preload("res://resources/materials/platform_concrete.tres")
	var asphalt := preload("res://resources/materials/ground_asphalt.tres")
	if industrial:
		_box(site,Vector3(44,-.08,22),Vector3(218,.16,57),asphalt)
	else:
		_box(site,Vector3(51,-.10,58),Vector3(263,.16,7.2),asphalt)
	_box(site,Vector3(-12,0.5,4),Vector3(70,1,5),concrete)
	# Continuous shallow ramp from yard to platform; rail-side ladders remain usable.
	var ramp := _box(site,Vector3(-12,0.37,10),Vector3(8,0.25,8),concrete)
	ramp.rotation.x = deg_to_rad(7.1)
	boarding_point = Vector3(-12,1.02,2)
	var specs := [[Vector3(22,0,24),Vector3(24,5,14),"FREIGHT STORES"],
		[Vector3(122,0,38),Vector3(18,5,12),"MAINTENANCE"],
		[Vector3(-40,0,28),Vector3(12,4,10),"DEPOT OFFICE"]] if industrial else [
		[Vector3(12,0,22),Vector3(12,4,10),"BLACKWATER STATION"],
		[Vector3(82,0,38),Vector3(10,4,9),"EVACUATED · 04 NOV"],
		[Vector3(168,0,48),Vector3(14,4,10),"CROSSING STORES"],
		[Vector3(-65,0,32),Vector3(10,3.6,9),"TRACK CREW"]]
	for spec in specs:
		var building := StationBuilding.new()
		building.position = spec[0]
		building.dimensions = spec[1]
		building.industrial = industrial
		building.title = spec[2]
		building.name = "Building_%d" % buildings.size()
		add_child(building)
		buildings.append(building)
	var d := DetailBuilder.new(self)
	d.signboard(Vector3(-10,3.2,5.8),title,13,1.1)
	d.beam(Vector3(-17,0,5.8),Vector3(-17,4,5.8),0.18,DetailBuilder.INK)
	d.beam(Vector3(-3,0,5.8),Vector3(-3,4,5.8),0.18,DetailBuilder.INK)
	if industrial:
		var spur := Track.new()
		spur.name = "LoadingSiding"
		spur.position = Vector3(51.,-.08,-21.)
		spur.length = 28.
		add_child(spur)
		for x in [42,58,74]:
			_box(site,Vector3(x,1.6,-12),Vector3(12,3.2,3),preload("res://resources/materials/train_body.tres")).show_mesh = false
		for x in [-38,-22]:
			d.cylinder(Vector3(x,4,-17),2.4,8,Color("6b7168"))
		d.signboard(Vector3(-30,6,-13),"FUEL RESERVE",8,0.8)
		add_cache("coal_a",Vector3(-12,1.02,4.6),"Platform coal reserve","coal_sack",1)
		add_cache("coal_b",Vector3(22,0.05,25),"Freight coal sacks","coal_sack",2)
		add_cache("workshop",Vector3(122,0.05,38),"Workshop tool locker","tools",2)
		add_cache("components",Vector3(128,0.05,39),"Machine spares","machine_component",1)
		add_cache("medical",Vector3(-40,0.05,28),"Depot first aid","medicine",2)
		add_cache("rations",Vector3(16,0.05,24),"Freight rations","canned_food",3)
		add_cache("scrap",Vector3(115,0.05,38),"Repair stock","scrap_metal",4)
	else:
		_box(site,Vector3(48,-.01,0),Vector3(6.8,.08,130),asphalt)
		for z in [-8,9]:
			d.beam(Vector3(44,0,z),Vector3(44,4,z),0.15,DetailBuilder.INK)
			d.beam(Vector3(43,3,z),Vector3(45,4,z),0.16,DetailBuilder.PALE)
			d.beam(Vector3(43,4,z),Vector3(45,3,z),0.16,DetailBuilder.PALE)
		for x in [-30,32,94,145,190]:
			d.box(Vector3(x,0.3,57),Vector3(4,0.6,3),Color("3c4c3a"))
		add_cache("food",Vector3(12,0.05,22),"Evacuation rations","canned_food",3)
		add_cache("medicine",Vector3(82,0.05,38),"Abandoned medicine","medicine",2)
		add_cache("fuel",Vector3(-65,0.05,32),"Crossing coal reserve","coal_sack",1)
		add_cache("tools",Vector3(168,0.05,48),"Maintenance stores","tools",2)
		add_cache("bandages",Vector3(174,0.05,48),"Evacuation first aid","bandages",3)
		note = SupplyInteractable.new()
		note.name = "EvacuationNote"
		note.position = Vector3(163,0.05,49)
		note.prompt = "Read evacuation route"
		add_child(note)
		d.signboard(note.position + Vector3(0,1.3,0),"EVACUATION LOG",2.8,0.55)
		d.signboard(Vector3(170,2,55),"EASTBOUND ONLY · KEEP STEAM UP",7,0.65)
	d.finish()
	var art := JourneyStationArt.new()
	art.name = "AuthoredStationDetails"
	add_child(art)
	art.build_route_station(self)

## New permanent freight platforms, buildings and vehicles share the station's
## original static body. Dressing can be culled independently of this geometry.
func add_structure_collision(at: Vector3, size: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	collider.position = at
	site.add_child(collider)

func add_cache(suffix: String, at: Vector3, caption: String, item_id: String, amount: int) -> void:
	var cache := SearchContainer.new()
	cache.name = suffix
	cache.cache_id = station_id + "_" + suffix
	cache.title = caption
	cache.position = at
	cache.style = 2 if item_id == "coal_sack" else 1
	var table := LootTable.new()
	table.rolls = 1
	var entry := LootEntry.new()
	entry.item = ItemCatalog.find(item_id)
	entry.minimum = amount
	entry.maximum = amount
	table.entries.append(entry)
	cache.loot_table = table
	add_child(cache)
	caches.append(cache)

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> BoxPart:
	var block := BoxPart.new()
	block.position = at
	block.size = size
	block.material = material
	parent.add_child(block)
	return block
