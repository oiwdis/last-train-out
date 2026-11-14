class_name PlayerMovementConfig
extends Resource
## Tunable movement values for the player. Stored as a Resource so designers can
## keep several tunings side by side and swap them on the Player node.

@export_group("Ground movement")
## Walking speed in m/s.
@export var walk_speed := 3.0
## Sprinting speed in m/s.
@export var sprint_speed := 6.0
## How quickly the player reaches the target speed on the ground (m/s^2).
@export var ground_acceleration := 45.0
## How quickly the player stops or turns around on the ground (m/s^2).
@export var ground_deceleration := 55.0
## Multiplier applied to movement along the depth (Z) axis.
@export_range(0.1, 1.0, 0.05) var depth_speed_scale := 0.8

@export_group("Air movement")
## Steering strength while airborne (m/s^2).
@export var air_acceleration := 24.0
## Horizontal slow-down while airborne with no input (m/s^2). Measured against
## the frame the player jumped from, so momentum inherited from a moving
## platform is never bled away.
@export var air_deceleration := 8.0

@export_group("Jump")
## Apex height of a full jump in metres.
@export var jump_height := 1.3
## Seconds from take-off to apex. Lower values feel snappier.
@export var jump_time_to_apex := 0.36
## Gravity multiplier while falling (and after an early jump release).
@export var fall_gravity_multiplier := 1.5
## Releasing the jump button early cuts the jump short: the player rises at
## most this much further (metres). Gives a controllable short hop.
@export var jump_release_rise := 0.3
@export var max_fall_speed := 28.0
## Grace period after walking off a ledge during which a jump is still allowed.
@export var coyote_time := 0.12
## A jump pressed this long before landing is executed on touchdown.
@export var jump_buffer_time := 0.12

@export_group("Climbing")
## Ladder climbing speed in m/s.
@export var climb_speed := 2.6
## Sideways speed while hanging from a railing in m/s.
@export var shimmy_speed := 1.6
## Seconds taken to settle onto a ladder or railing after grabbing it.
@export var grab_blend_time := 0.16
## Seconds taken to climb off the top of a ladder or over a railing.
@export var mount_time := 0.34
## Largest speed difference (m/s) at which a moving ladder or railing can still
## be caught. 0 disables the limit.
@export var max_grab_relative_speed := 10.0
## Horizontal push when jumping off a ladder or railing (m/s).
@export var detach_jump_speed := 3.5

@export_group("Interaction")
## An interact press is remembered this long so a grab can be timed slightly early.
@export var interact_buffer_time := 0.18
## After letting go, the same ladder/railing cannot be re-grabbed for this long.
@export var regrab_cooldown := 0.35

@export_group("Vault")
## Lowest obstacle (m) that triggers a vault instead of a plain step.
@export var vault_min_height := 0.3
## Tallest obstacle (m) the player can vault or mantle.
@export var vault_max_height := 1.25
## Obstacles thinner than this are vaulted over; deeper ones are climbed onto.
@export var vault_max_depth := 1.3
## How far in front of the player an obstacle is detected.
@export var vault_reach := 0.7
## Largest drop (m) accepted on the far side of a vaulted obstacle.
@export var vault_max_drop := 1.3
@export var vault_duration := 0.36
@export var mantle_duration := 0.42


func get_jump_velocity() -> float:
	return 2.0 * jump_height / jump_time_to_apex


func get_rise_gravity() -> float:
	return 2.0 * jump_height / (jump_time_to_apex * jump_time_to_apex)


## Upward speed the jump is clamped to when the button is released early.
func get_jump_release_velocity() -> float:
	return sqrt(2.0 * get_rise_gravity() * maxf(jump_release_rise, 0.0))


func get_fall_gravity() -> float:
	return get_rise_gravity() * fall_gravity_multiplier
