class_name ItemCatalog
extends RefCounted

const IDS: Array[StringName] = [&"canned_food", &"bandages", &"medicine", &"scrap_metal",
	&"tools", &"lantern_oil", &"coal_sack", &"fuel_drum", &"machine_component"]


static func find(id: StringName) -> ItemDefinition:
	if not IDS.has(id):
		return null
	return load("res://resources/items/%s.tres" % id) as ItemDefinition
