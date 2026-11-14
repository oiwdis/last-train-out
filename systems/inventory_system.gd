class_name InventorySystem
extends Node
## Owns the reusable backpack and train storage models.

signal inventory_changed(item_id: StringName, amount: int)

@export_range(6, 200) var storage_slots := 48
var backpack := InventoryModel.new(6)
var storage: InventoryModel
var _legacy_ids: Array[StringName] = []


func _ready() -> void:
	storage = InventoryModel.new(storage_slots, true)


## Compatibility for the Milestone 1 API; these supplies live in train storage.
func add_item(item_id: StringName, amount: int = 1) -> void:
	var item := ItemCatalog.find(&"coal_sack" if item_id == &"coal" else item_id)
	if storage.add(item, amount) > 0:
		if not _legacy_ids.has(item_id):
			_legacy_ids.append(item_id)
		inventory_changed.emit(item_id, get_amount(item_id))


func remove_item(item_id: StringName, amount: int = 1) -> int:
	var id := &"coal_sack" if item_id == &"coal" else item_id
	var removed := 0
	for i in storage.slot_count:
		var slot := storage.get_slot(i)
		if not slot.is_empty() and (slot.item as ItemDefinition).id == id:
			removed += storage.remove_at(i, amount - removed)
	if removed > 0:
		inventory_changed.emit(item_id, get_amount(item_id))
	return removed


func get_amount(item_id: StringName) -> int:
	return storage.count(&"coal_sack" if item_id == &"coal" else item_id)


func reset() -> void:
	backpack.clear()
	storage.clear()
	for id in _legacy_ids:
		inventory_changed.emit(id, 0)
	_legacy_ids.clear()
