class_name DepartureMode
extends Resource
## How the train pulls away from a station.

@export var id: StringName = &"normal"
@export var display_name := "Normal"
## Seconds from standstill to maximum speed (before acceleration modifiers).
@export_range(0.5, 120.0, 0.1, "or_greater") var time_to_full_speed := 10.0
## Optional speed profile: X is normalised time (0..1), Y is the fraction of
## maximum speed (0..1). It should rise monotonically from 0 to 1. Leave empty
## for a smoothstep ease-in/ease-out.
@export var acceleration_curve: Curve


## Fraction of maximum speed after normalised time [param t] (0..1).
func sample(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	if acceleration_curve != null:
		return clampf(acceleration_curve.sample_baked(t), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Normalised time at which the profile reaches [param fraction] of full speed.
func inverse_sample(fraction: float) -> float:
	fraction = clampf(fraction, 0.0, 1.0)
	var low := 0.0
	var high := 1.0
	for i in 24:
		var mid := (low + high) * 0.5
		if sample(mid) < fraction:
			low = mid
		else:
			high = mid
	return (low + high) * 0.5
