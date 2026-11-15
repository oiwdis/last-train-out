class_name InventoryModel
extends RefCounted
## Slot-based inventory independent of nodes, UI and physics. Mutations are synchronous.
## Both sides of a transfer commit before either signal fires; reentrant writes are rejected.

signal changed

var slot_count: int
var allows_heavy: bool
var _slots: Array[Dictionary] = []
var _busy := false


func _init(capacity: int = 6, heavy_allowed: bool = false) -> void:
	slot_count = maxi(capacity, 1)
	allows_heavy = heavy_allowed
	for i in slot_count:
		_slots.append({})


func get_slot(index: int) -> Dictionary:
	return _slots[index].duplicate() if index >= 0 and index < slot_count else {}


func count(id: StringName) -> int:
	var total := 0
	for slot in _slots:
		if not slot.is_empty() and (slot.item as ItemDefinition).id == id:
			total += slot.amount
	return total


func totals() -> Dictionary:
	var result := {}
	for slot in _slots:
		if not slot.is_empty():
			var id := (slot.item as ItemDefinition).id
			result[id] = int(result.get(id, 0)) + int(slot.amount)
	return result


func used_slots() -> int:
	return _slots.filter(func(slot: Dictionary) -> bool: return not slot.is_empty()).size()


func total_weight() -> float:
	var result := 0.0
	for slot in _slots:
		if not slot.is_empty():
			result += (slot.item as ItemDefinition).weight * int(slot.amount)
	return result


func room_for(item: ItemDefinition) -> int:
	if item == null or item.id.is_empty() or item.stack_limit < 1 or (item.heavy and not allows_heavy):
		return 0
	var room := 0
	for slot in _slots:
		if slot.is_empty():
			room += item.stack_limit
		elif (slot.item as ItemDefinition).id == item.id:
			room += maxi(item.stack_limit - int(slot.amount), 0)
	return room


## Returns the accepted quantity. Unaccepted items remain the caller's property.
func add(item: ItemDefinition, amount: int) -> int:
	if _busy or amount <= 0:
		return 0
	var accepted := mini(amount, room_for(item))
	if accepted == 0:
		return 0
	_busy = true
	_add_unchecked(item, accepted)
	changed.emit()
	_busy = false
	return accepted


func remove_at(index: int, amount: int) -> int:
	if _busy or amount <= 0 or index < 0 or index >= slot_count or _slots[index].is_empty():
		return 0
	_busy = true
	var removed := mini(amount, int(_slots[index].amount))
	_remove_unchecked(index, removed)
	changed.emit()
	_busy = false
	return removed


## Atomic transfer, including partial stacks. No await and no intermediate observable state.
func transfer_to(destination: InventoryModel, index: int, amount: int = 2147483647) -> int:
	if destination == null or destination == self or _busy or destination._busy or amount <= 0:
		return 0
	var slot := get_slot(index)
	if slot.is_empty():
		return 0
	var moved := mini(mini(amount, int(slot.amount)), destination.room_for(slot.item))
	if moved <= 0:
		return 0
	_busy = true
	destination._busy = true
	_remove_unchecked(index, moved)
	destination._add_unchecked(slot.item, moved)
	changed.emit()
	destination.changed.emit()
	destination._busy = false
	_busy = false
	return moved


func clear() -> void:
	if _busy:
		return
	_busy = true
	for i in slot_count:
		_slots[i] = {}
	changed.emit()
	_busy = false


func _remove_unchecked(index: int, amount: int) -> void:
	_slots[index].amount -= amount
	if _slots[index].amount == 0:
		_slots[index] = {}


func _add_unchecked(item: ItemDefinition, amount: int) -> void:
	var remaining := amount
	for slot in _slots:
		if slot.is_empty() or (slot.item as ItemDefinition).id != item.id:
			continue
		var accepted := mini(remaining, item.stack_limit - int(slot.amount))
		slot.amount += accepted
		remaining -= accepted
	for i in slot_count:
		if remaining == 0:
			break
		if _slots[i].is_empty():
			var accepted := mini(remaining, item.stack_limit)
			_slots[i] = {"item": item, "amount": accepted}
			remaining -= accepted
