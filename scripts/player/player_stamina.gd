class_name PlayerStamina
extends Node
## Sprint stamina: drains while sprinting, regenerates after a short delay.
##
## Running the bar to zero leaves the player exhausted; sprinting is locked out
## until stamina climbs back above [member exhausted_recovery_threshold].

signal changed(current: float, maximum: float)
signal exhausted
signal recovered

@export var max_stamina := 100.0
## Stamina lost per second of sprinting.
@export var drain_per_second := 13.0
## Stamina gained per second once regeneration has started.
@export var regen_per_second := 24.0
## Seconds after the last sprint before regeneration starts.
@export var regen_delay := 0.9
## Stamina needed to sprint again after being exhausted.
@export var exhausted_recovery_threshold := 25.0

var current := 100.0
var is_exhausted := false

var _regen_cooldown := 0.0


func _ready() -> void:
	current = max_stamina


func can_sprint() -> bool:
	return not is_exhausted and current > 0.0


## Advances the simulation. [param sprinting] is whether the player is
## spending stamina this tick.
func tick(delta: float, sprinting: bool) -> void:
	var before := current
	if sprinting and can_sprint():
		current = maxf(current - drain_per_second * delta, 0.0)
		_regen_cooldown = regen_delay
		if current <= 0.0:
			is_exhausted = true
			exhausted.emit()
	elif _regen_cooldown > 0.0:
		_regen_cooldown -= delta
	else:
		current = minf(current + regen_per_second * delta, max_stamina)
		if is_exhausted and current >= exhausted_recovery_threshold:
			is_exhausted = false
			recovered.emit()
	if not is_equal_approx(before, current):
		changed.emit(current, max_stamina)


func get_fraction() -> float:
	return current / max_stamina if max_stamina > 0.0 else 0.0


func reset() -> void:
	current = max_stamina
	_regen_cooldown = 0.0
	if is_exhausted:
		is_exhausted = false
		recovered.emit()
	changed.emit(current, max_stamina)
