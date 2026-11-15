class_name LootEntry
extends Resource

@export var item: ItemDefinition
@export_range(0.0, 100.0) var weight := 1.0
@export_range(1, 99) var minimum := 1
@export_range(1, 99) var maximum := 1
