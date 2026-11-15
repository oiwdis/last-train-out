class_name FogConfig
extends Resource
## Gameplay tuning only. Graphics settings must never write this resource.
@export var initial_distance := 210.0
@export var base_speed := 0.8
@export var escalation_per_minute := 0.08
@export var maximum_speed := 1.6
@export var difficulty := 1.0
@export var approach_distance := 130.0
@export var critical_distance := 45.0
@export var station_slow_radius := 55.0
@export var station_speed_factor := 0.85
@export var exposure_per_second := 3.0
@export var depth_scale := 35.0
@export var recovery_per_second := 5.0
@export var damage_per_second := 5.0
@export var damage_threshold := 15.0
@export var protection_cab := 0.72
@export var protection_passenger := 0.48
@export var protection_open := 0.12
@export var protection_building := 0.25
@export var visibility_density := 0.095
@export var audio_intensity := 0.7
@export var events_enabled := true
@export var event_interval_min := 50.0
@export var event_interval_max := 85.0
@export var event_warning_seconds := 10.0
@export var event_duration := 16.0
@export var surge_multiplier := 1.8
@export var calm_multiplier := 0.55
@export var initial_fuel := 75.0
@export var fuel_per_second := 0.65
@export var fuel_per_sack := 45.0
@export var fuel_capacity := 120.0

func signature() -> Dictionary:
	var values := {}
	for property in get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			values[property.name] = get(property.name)
	return values
