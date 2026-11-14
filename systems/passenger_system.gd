class_name PassengerSystem
extends Node
## Placeholder for passengers (recruitment, relationships, AI - later milestones).
##
## Tracks nothing more than an id -> state table and announces changes, which is
## enough for UI and other systems to be wired against the final signal names.

signal passenger_registered(passenger_id: StringName)
signal passenger_state_changed(passenger_id: StringName, state: PassengerState)

enum PassengerState { WAITING, FOLLOWING, ABOARD, LOST }

var _passengers: Dictionary = {}


func register_passenger(passenger_id: StringName, state: PassengerState = PassengerState.WAITING) -> void:
	if _passengers.has(passenger_id):
		return
	_passengers[passenger_id] = state
	passenger_registered.emit(passenger_id)


func set_passenger_state(passenger_id: StringName, state: PassengerState) -> void:
	if not _passengers.has(passenger_id) or _passengers[passenger_id] == state:
		return
	_passengers[passenger_id] = state
	passenger_state_changed.emit(passenger_id, state)


func get_passenger_state(passenger_id: StringName) -> PassengerState:
	return _passengers.get(passenger_id, PassengerState.LOST)


func get_passenger_count() -> int:
	return _passengers.size()


func reset() -> void:
	_passengers.clear()
