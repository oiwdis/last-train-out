class_name FogSystem
extends Node
## Placeholder for the advancing fog (planned for Week 3).
##
## Only the public surface exists so other systems can already connect to it:
## the signals, a state value and a surge trigger that reports to the log.
## There is deliberately no fog movement, damage or timing logic here yet.

signal fog_state_changed(state: FogState)
## Emitted when a surge starts. [param intensity] is a 0..1 placeholder value.
signal surge_triggered(intensity: float)

enum FogState { DORMANT, ADVANCING, SURGING }

var state := FogState.DORMANT
var surge_count := 0


func set_state(new_state: FogState) -> void:
	if new_state == state:
		return
	state = new_state
	fog_state_changed.emit(state)


## Debug hook: announces a surge without simulating one.
func trigger_surge(intensity: float = 1.0) -> void:
	surge_count += 1
	print("[FogSystem] Fog surge #%d triggered (placeholder - fog behaviour arrives in Week 3)." % surge_count)
	surge_triggered.emit(clampf(intensity, 0.0, 1.0))


func reset() -> void:
	surge_count = 0
	set_state(FogState.DORMANT)
