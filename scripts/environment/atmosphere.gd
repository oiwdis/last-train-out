class_name Atmosphere
extends Node3D
## Station atmosphere: world environment and moonlight.
##
## The gentle blue-grey haze here is purely decorative. It is deliberately
## thin and cool-coloured so that the dangerous advancing fog planned for a
## later milestone (dense, pale, with its own visuals) reads as something else.

## Volumetric fog only exists in the Forward+ renderer; other renderers keep
## the cheaper depth fog configured in the Environment resource.
@export var use_volumetric_fog := true

@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	var environment := _world_environment.environment
	if environment == null:
		return
	var supported := RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.volumetric_fog_enabled = use_volumetric_fog and supported


func get_environment() -> Environment:
	return _world_environment.environment
