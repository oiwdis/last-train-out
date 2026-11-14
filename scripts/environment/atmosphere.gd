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
	environment.volumetric_fog_enabled = use_volumetric_fog and _volumetric_fog_is_supported()


## Volumetric fog needs the Forward+ renderer and a GPU that can use 32-bit
## integer textures as atomic storage. Some GPUs (virtual machines among them)
## cannot, and Godot crashes rather than degrading, so check before enabling.
func _volumetric_fog_is_supported() -> bool:
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		return false
	var device := RenderingServer.get_rendering_device()
	if device == null:
		return false
	return device.texture_is_format_supported_for_usage(
		RenderingDevice.DATA_FORMAT_R32_UINT, RenderingDevice.TEXTURE_USAGE_STORAGE_ATOMIC_BIT)


func get_environment() -> Environment:
	return _world_environment.environment
