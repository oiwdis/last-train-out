class_name PropLight
extends Node3D
## A lamp prop whose light can be tuned per instance without opening the scene.
## Expects a child Light3D named "Light".

## Shadows cost performance: enable them only on a few key lamps.
@export var shadows := false
## Multiplier on the light's authored energy.
@export_range(0.0, 4.0, 0.05) var energy_scale := 1.0


func _ready() -> void:
	var light := get_node_or_null(^"Light") as Light3D
	if light == null:
		return
	light.shadow_enabled = shadows
	light.light_energy *= energy_scale
