class_name JourneyStationArt
extends AssetDressing
## Reuses Harlow's licensed props and scanned materials. Visual-only additions;
## modular shells, doors, shelters, cache ownership and walking routes stay intact.

var station: JourneyStation
var _structure_palette := {}

func structural_details(title: String) -> DetailBuilder:
	return DetailBuilder.new(self,title,true,_structure_palette)

func build_route_station(owner_station: JourneyStation) -> void:
	station = owner_station
	var steel := preload("res://resources/materials/metal_dark.tres")
	var roof := preload("res://resources/materials/roof_metal.tres")
	for building in station.buildings:
		var at := building.position
		var size := building.dimensions
		# Shared bevel geometry and metre-scaled PBR, no extra physics bodies.
		for side in [-1,1]:
			trim(at+Vector3(side*(size.x/2+.13),size.y/2,size.z/2),Vector3(.18,size.y,.18),steel)
			trim(at+Vector3(side*(size.x/2+.13),size.y/2,-size.z/2),Vector3(.18,size.y,.18),steel)
			trim(at+Vector3(side*(size.x/2+.2),size.y+.12,0),Vector3(.12,.22,size.z+.8),steel)
			trim(at+Vector3(side*1.4,1.6,size.z/2+.2),Vector3(.14,3.2,.18),steel)
		trim(at+Vector3(0,3.25,size.z/2+.55),Vector3(3.2,.12,1.0),roof)
		trim(at+Vector3(0,size.y+.16,-size.z/2-.2),Vector3(size.x+.7,.2,.15),steel)
		# Back corners are outside cache approaches and the 2.6 m open doorway.
		prop("shelf" if station.industrial else "rack",at+Vector3(-size.x/2+1,.02,-size.z/2+.5),0)
		prop("military_crate" if station.industrial else "suitcase",at+Vector3(size.x/2-1.2,.02,-size.z/2+1),.15)
		prop("sconce",at+Vector3(2.3,2.8,size.z/2+.25),PI)
		prop("pendant",at+Vector3(0,size.y-.35,0),0)
	if station.industrial:
		for entry in [["cart",Vector3(116,.02,34)],["drill",Vector3(116,1.43,34)],["oil_can",Vector3(116.6,1.43,34)],["hand_truck",Vector3(129,.02,34)],["barrel",Vector3(28,.02,19)],["barrel",Vector3(29,.02,19)]]:
			prop(entry[0],entry[1],0)
	else:
		for entry in [["suitcase",Vector3(8,.02,19)],["military_crate",Vector3(171,.02,44)],["hand_truck",Vector3(164,.02,44)],["barrel",Vector3(-68,.02,29)]]:
			prop(entry[0],entry[1],0)
	if station.industrial:
		DepotYard.build(self)
	else:
		CrossingVillage.build(self)
	_flush()
	warm_view(Vector3(-20,3.2,9),Vector3(22,2,24))
	warm_view(Vector3(125,1.65,41),Vector3(119,1.6,34)) if station.industrial else warm_view(Vector3(169,1.65,51),Vector3(164,1.6,44))

func prop(asset: String, at: Vector3, yaw: float) -> void:
	_batch(asset,Transform3D(Basis(Vector3.UP,yaw),at))

func trim(at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = FabricatedMesh.box(size,material)
	mesh.position = at
	mesh.visibility_range_end = 100
	mesh.visibility_range_end_margin = 8
	add_child(mesh)

func warm_view(at: Vector3, target: Vector3) -> void:
	var marker := Marker3D.new()
	add_child(marker)
	marker.position = at
	marker.look_at(to_global(target))
	marker.add_to_group("render_warmup_view")
