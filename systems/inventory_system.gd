class_name InventorySystem
extends Node
## Placeholder for supplies and loot (later milestones).
##
## A plain item-id -> amount table with a change signal. No loot sources, item
## definitions, weight or UI exist yet.

signal inventory_changed(item_id: StringName, amount: int)

var _items: Dictionary = {}


func add_item(item_id: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return
	_items[item_id] = get_amount(item_id) + amount
	inventory_changed.emit(item_id, _items[item_id])


## Removes up to [param amount]; returns how many were actually removed.
func remove_item(item_id: StringName, amount: int = 1) -> int:
	var removed := mini(amount, get_amount(item_id))
	if removed <= 0:
		return 0
	_items[item_id] = get_amount(item_id) - removed
	inventory_changed.emit(item_id, _items[item_id])
	return removed


func get_amount(item_id: StringName) -> int:
	return _items.get(item_id, 0)


func reset() -> void:
	var ids := _items.keys()
	_items.clear()
	for item_id: StringName in ids:
		inventory_changed.emit(item_id, 0)
