class_name TrainInterior
extends Node3D
## Hollow car structure and controls. All collision remains on the original TrainCar.

var car: TrainCar
var doors: Array[WorldDoor] = []
var controls: Array[TrainConsole] = []
var _speed: Label3D
var _refresh := 0.0


func build(body: TrainCar) -> void:
	car = body
	if car.name == "FlatCar":
		_part("GangwayFront", Vector3(4.45, 0.97, 0), Vector3(0.4, 0.06, 1.3))
		return
	var crew := car.name == "CrewCar"
	var centre := 0.0 if crew else -2.6
	var length := 6.8 if crew else 3.2
	# Replace the solid shell with continuous sill/lintel bands and window posts.
	for side in [-1.0, 1.0]:
		_part("Sill", Vector3(centre, 1.44, side * 1.26), Vector3(length, 0.88, 0.12))
		_part("Lintel", Vector3(centre, 3.2, side * 1.26), Vector3(length, 0.6, 0.12))
		var count := 5 if crew else 3
		for index in count:
			var x := centre - length / 2 + 0.07 + (length - 0.14) * index / (count - 1)
			_part("WindowPost", Vector3(x, 2.39, side * 1.26), Vector3(0.12, 1.02, 0.12))
		# Glass is physically solid, visually clear; it never fades away with a room.
		var glass := _part("WindowGlass", Vector3(centre, 2.39, side * 1.26), Vector3(length, 1.02, 0.035))
		glass.material = _glass()
	for end in [-1.0, 1.0]:
		var x: float = centre + end * length / 2
		if not crew and end > 0:
			_part("CabBulkhead", Vector3(x, 2.25, 0), Vector3(0.12, 2.5, 2.6))
			continue
		for side in [-1.0, 1.0]:
			_part("DoorJamb", Vector3(x, 2.1, side * 0.98), Vector3(0.12, 2.2, 0.64))
		_part("DoorLintel", Vector3(x, 3.36, 0), Vector3(0.12, 0.28, 2.6))
		var door := WorldDoor.new()
		door.name = "EndDoorFront" if end > 0 else "EndDoorRear"
		door.width = 1.32
		door.height = 2.2
		door.position = Vector3(x, 1.0, 0)
		door.rotation.y = PI / 2
		car.add_child(door)
		doors.append(door)
	for end in [-1.0, 1.0]:
		if crew or end < 0:
			_part("Gangway", Vector3(end * 4.45, 0.97, 0), Vector3(0.4, 0.06, 1.3))
	if crew:
		for side in [-1.0, 1.0]:
			for x in [-1.8, 1.8]:
				_part("Bench", Vector3(x, 1.43, side * 0.95), Vector3(1.65, 0.13, 0.48), "floor_wood")
				_part("SeatBack", Vector3(x, 1.73, side * 1.15), Vector3(1.65, 0.55, 0.08), "floor_wood")
				for leg in [-0.65, 0.65]:
					_part("SeatLeg", Vector3(x + leg, 1.2, side * 0.95), Vector3(0.06, 0.4, 0.4), "metal_dark")
		var fittings := DetailBuilder.new(self, "LuggageRacks")
		for side in [-1.0, 1.0]:
			for x in range(-3, 4):
				fittings.beam(Vector3(x, 2.86, side * 1.22), Vector3(x, 2.86, side * 0.85), 0.025, DetailBuilder.STEEL)
			fittings.cylinder(Vector3(0, 2.86, side * 0.85), 0.025, 6.2, DetailBuilder.STEEL, Vector3(0, 0, PI / 2))
		fittings.finish()
	else:
		_build_controls()
	for node in car.get_children():
		if node is OmniLight3D:
			node.position = Vector3(centre + (0.9 if node.name == "WindowGlowB" else -0.5), 3.13, 0)
			node.omni_range = 4.0
			node.light_energy = 1.0


func _part(title: String, at: Vector3, size: Vector3, material_name: String = "train_body") -> BoxPart:
	var part := BoxPart.new()
	part.name = title
	part.position = at
	part.size = size
	part.show_mesh = title not in ["Sill", "Lintel", "WindowPost", "WindowGlass", "DoorJamb", "DoorLintel", "CabBulkhead", "ControlDesk", "Bench", "SeatBack", "SeatLeg"]
	part.material = load("res://resources/materials/%s.tres" % material_name)
	car.add_child(part)
	return part


func _glass() -> StandardMaterial3D:
	return preload("res://resources/materials/train_glass.tres")


func _build_controls() -> void:
	_part("ControlDesk", Vector3(-1.35, 1.6, 0), Vector3(0.4, 1.2, 2.2), "metal_dark")
	var details := DetailBuilder.new(self, "CabFittings")
	for z in [-0.63, 0.0, 0.63]:
		details.cylinder(Vector3(-1.64, 2.52, z), 0.14, 0.06, DetailBuilder.AMBER, Vector3(0, 0, PI / 2))
		details.cylinder(Vector3(-1.68, 2.52, z), 0.115, 0.012, DetailBuilder.PALE, Vector3(0, 0, PI / 2))
		details.beam(Vector3(-1.69, 2.52, z), Vector3(-1.69, 2.59, z - 0.04), 0.012, DetailBuilder.INK)
		for mark in 12:
			var a := mark * TAU / 12
			details.box(Vector3(-1.69, 2.52 + cos(a) * 0.095, z + sin(a) * 0.095), Vector3(0.01, 0.012, 0.012), DetailBuilder.INK)
	for z in [-1.05, 1.05]:
		details.cylinder(Vector3(-1.6, 2.55, z), 0.035, 1.7, DetailBuilder.AMBER)
		details.cylinder(Vector3(-1.6, 1.78, z), 0.08, 0.08, DetailBuilder.STEEL, Vector3(0, 0, PI / 2))
	details.cylinder(Vector3(-1.62, 1.5, 0), 0.28, 0.06, DetailBuilder.INK, Vector3(0, 0, PI / 2))
	details.finish()
	details.root.hide() # Replaced by the fitted, detailed cab mesh.
	for index in 3:
		var control := TrainConsole.new()
		control.name = ["Regulator", "Brake", "DepartureSelector"][index]
		control.command = index
		control.train = car.get_parent() as Train
		control.position = Vector3(-1.61, 2.1, -0.65 + index * 0.65)
		car.add_child(control)
		controls.append(control)
	_speed = Label3D.new()
	_speed.position = Vector3(-1.62, 2.7, 0)
	_speed.rotation.y = -PI / 2
	_speed.pixel_size = 0.00085
	_speed.font_size = 36
	_speed.modulate = Color("efcf8f")
	car.add_child(_speed)
	_part("CoalBunker", Vector3(-3.5, 1.3, -0.9), Vector3(0.8, 0.6, 0.6), "metal_dark")


func _process(delta: float) -> void:
	if _speed == null:
		return
	_refresh -= delta
	if _refresh <= 0:
		_refresh = 0.1
		var train := car.get_parent() as Train
		_speed.text = "%02d km/h\nREGULATOR · BRAKE · MODE" % roundi(train.speed * 3.6)
