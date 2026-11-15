class_name ExplorationDistrict
extends StaticBody3D
## Ground-level spaces around the original warehouse routes. X follows the railway.

var doors: Array[WorldDoor] = []


func _ready() -> void:
	name = "ExplorationDistrict"
	collision_layer = 1
	collision_mask = 0
	_waiting_hall()
	_yard_routes()
	for data in [[35.0, 1.1], [60.0, 1.1], [70.0, 1.1], [100.0, 1.7]]:
		_door(Vector3(data[0], 0.03, data[1]), PI / 2, 1.65)
	var stairs := Stairs.new()
	stairs.name = "PlatformApproach"
	stairs.position = Vector3(22.5, 0, 6.1)
	stairs.rotation.y = PI / 2
	stairs.run = 3.2
	stairs.rise = 1.0
	stairs.width = 1.9
	stairs.step_count = 8
	stairs.material = preload("res://resources/materials/platform_concrete.tres")
	add_child(stairs)


func _part(title: String, at: Vector3, size: Vector3, material_name: String, solid: bool = true) -> BoxPart:
	var part := BoxPart.new()
	part.name = title
	part.position = at
	part.size = size
	part.solid = solid
	part.material = load("res://resources/materials/%s.tres" % material_name)
	add_child(part, true)
	return part


func _door(at: Vector3, yaw: float, width: float) -> WorldDoor:
	var door := WorldDoor.new()
	var host := StaticBody3D.new()
	host.name = "DoorFrame"
	host.position = at
	host.rotation.y = yaw
	add_child(host)
	door.width = width
	door.height = 2.7 if width > 2 else 2.2
	host.add_child(door)
	door.add_to_group(&"station_resettable")
	doors.append(door)
	return door


func _waiting_hall() -> void:
	_part("WaitingHallFloor", Vector3(16, -0.06, 12.5), Vector3(22, 0.16, 9), "floor_interior")
	_part("RearWall", Vector3(16, 2.1, 17), Vector3(22, 4.2, 0.3), "wall_brick")
	for x in [5.0, 27.0]:
		_part("SideWall", Vector3(x, 2.1, 12.5), Vector3(0.3, 4.2, 9), "wall_brick")
	# The front is divided into real windows and an open double-width doorway.
	for span in [[9.25, 8.5], [21.75, 10.5]]:
		_part("WindowSill", Vector3(span[0], 0.55, 8), Vector3(span[1], 1.1, 0.3), "wall_brick")
		_part("WindowLintel", Vector3(span[0], 3.5, 8), Vector3(span[1], 1.4, 0.3), "wall_brick")
	for x in [5.0, 8.0, 11.0, 13.5, 16.5, 20.0, 23.5, 27.0]:
		_part("StoneMullion", Vector3(x, 1.95, 8), Vector3(0.16, 1.7, 0.36), "platform_edge")
	_part("EntryLintel", Vector3(15, 3.5, 8), Vector3(3, 1.4, 0.3), "wall_brick")
	var door := _door(Vector3(15, 0.03, 8), 0, 2.7)
	door.height = 2.7
	for side in [-1.0, 1.0]:
		var roof := _part("PitchedRoof", Vector3(16, 4.55, 12.5 + side * 2.4), Vector3(23.2, 0.18, 5.1), "roof_metal")
		roof.rotation.x = side * 0.22
	for x in [6.0, 11.0, 16.0, 21.0, 26.0]:
		_part("RoofBeam", Vector3(x, 4.05, 12.5), Vector3(0.16, 0.2, 9), "floor_wood", false)
	for x in [8.0, 12.0, 24.0]:
		for z in [10.5, 15.7]:
			_part("WaitingBench", Vector3(x, 0.52, z), Vector3(2.1, 0.14, 0.55), "floor_wood")
			_part("BenchBack", Vector3(x, 0.9, z + 0.24), Vector3(2.1, 0.6, 0.09), "floor_wood")
			for side in [-0.8, 0.8]:
				_part("BenchLeg", Vector3(x + side, 0.24, z), Vector3(0.09, 0.48, 0.4), "metal_dark")
	_part("TicketCounter", Vector3(20, 0.55, 14.5), Vector3(3.3, 1.1, 0.65), "floor_wood")
	_part("CounterTop", Vector3(20, 1.14, 14.5), Vector3(3.5, 0.1, 0.85), "metal_dark")
	var d := DetailBuilder.new(self, "HallFittings")
	d.signboard(Vector3(15, 3.35, 7.8), "HARLOW JUNCTION", 5.3, 0.65,DetailBuilder.AMBER,PI)
	d.signboard(Vector3(20, 2.4, 16.78), "TICKETS  /  ALL SERVICES SUSPENDED", 4.8, 0.5,DetailBuilder.AMBER,PI)
	d.signboard(Vector3(9, 2.4, 16.78), "EVACUATE TO PLATFORM 01", 4, 0.5,DetailBuilder.AMBER,PI)
	for i in 7:
		d.box(Vector3(17.9 + i * 0.31, 1.23, 14.5), Vector3(0.22, 0.018, 0.3), Color("a9a291"), Vector3(0, i * 0.5, 0))
	d.finish()
	for x in [10.0, 21.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 3.6, 12.5)
		light.light_color = Color(1, 0.73, 0.43)
		light.light_energy = 1.5
		light.omni_range = 7
		light.shadow_enabled = false
		add_child(light)


func _yard_routes() -> void:
	_part("ServiceWalk", Vector3(76, 0.015, 7.3), Vector3(93, 0.03, 2.4), "platform_concrete")
	_part("TracksideWalk", Vector3(67, 0.015, -7), Vector3(130, 0.03, 2.2), "ground_asphalt")
	for x in [34.0, 65.0, 102.0, 123.0]:
		_part("Crossing", Vector3(x, 0.02, -3.5), Vector3(2.4, 0.04, 8), "floor_wood")
	# Containers create two ground routes and an optional elevated return route.
	for spec in [Vector3(107, 0, 11.5), Vector3(117, 0, 11.5), Vector3(108, 0, -12)]:
		_part("CargoContainer", spec + Vector3(0, 1.35, 0), Vector3(6, 2.7, 2.5), "freight_body")
		var details := DetailBuilder.new(self, "ContainerFittings")
		for i in 20:
			for side in [-1.0, 1.0]:
				details.box(spec + Vector3(-2.85 + i * 0.3, 1.35, side * 1.27), Vector3(0.05, 2.6, 0.06), DetailBuilder.STEEL)
		details.signboard(spec + Vector3(0, 1.7, 1.3), "HJ  /  RELIEF SUPPLIES", 3.4, 0.5)
		details.finish()
		var ladder := Ladder.new()
		ladder.name = "ContainerLadder"
		ladder.position = spec + Vector3(2.3, 0, 1.32)
		ladder.height = 2.7
		ladder.material = preload("res://resources/materials/interact_yellow.tres")
		add_child(ladder, true)
	for x in [40.0, 56.0, 78.0, 96.0]:
		_part("LoadingPallet", Vector3(x, 0.12, 10.7), Vector3(1.8, 0.24, 1.3), "crate_wood")
		_part("PackedSupplies", Vector3(x, 0.7, 10.7), Vector3(1.5, 0.9, 1.1), "crate_dark")
