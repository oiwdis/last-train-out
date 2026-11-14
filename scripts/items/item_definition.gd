class_name ItemDefinition
extends Resource
## Immutable authoring data. Quantities belong to inventories or world items.

enum Category { FOOD, MEDICAL, MATERIAL, EQUIPMENT, FUEL, UPGRADE }

@export var id: StringName
@export var display_name := "Supply"
@export_multiline var description := ""
@export var category := Category.MATERIAL
@export_range(1, 99) var stack_limit := 1
@export_range(0.0, 1000.0) var weight := 1.0
@export var heavy := false
@export var icon: Texture2D
@export var world_scene: PackedScene
@export var tint := Color("b8c1b6")
@export var future_use: Dictionary = {}


func tooltip() -> String:
	return "%s\n%s\n%s · %.1f kg each · %s" % [display_name, description,
		Category.keys()[category].capitalize(), weight,
		"two hands required" if heavy else "stack of %d" % stack_limit]
