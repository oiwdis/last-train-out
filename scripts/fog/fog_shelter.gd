class_name FogShelter
extends Node3D
## Authored bounds follow their parent (including moving cars); roofs/platforms
## outside these bounds never inherit indoor protection.
@export var bounds := AABB(Vector3(-1, 0, -1), Vector3(2, 3, 2))
@export_enum("CAB", "PASSENGER", "BUILDING") var kind := 2
var doors: Array[WorldDoor] = []

func contains(point: Vector3) -> bool:
	return bounds.has_point(to_local(point))

func protection(config: FogConfig) -> float:
	if kind == 2:
		return config.protection_building
	for door in doors:
		if door.is_open:
			return config.protection_building
	return config.protection_cab if kind == 0 else config.protection_passenger

func title() -> String:
	if kind == 2:
		return "BUILDING · LEAKING"
	for door in doors:
		if door.is_open:
			return "OPEN CAB" if kind == 0 else "OPEN CREW CAR"
	return "CLOSED CAB" if kind == 0 else "CLOSED CREW CAR"
