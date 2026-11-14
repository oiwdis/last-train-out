class_name CameraRig
extends Node3D
## Side-on follow camera.
##
## Tracks a target with look-ahead, blends between [CameraProfile]s (outdoor,
## indoor, train departure) and can widen the framing to keep a point of
## interest - such as the departing train - on screen. The target always stays
## the anchor of the shot: the interest only shifts and widens it within limits.
##
## Runs on the physics tick so the camera, the player and the train are all
## interpolated between the same pair of physics states (no relative jitter).

@export var target: Node3D
@export var default_profile: CameraProfile
## The movement sandbox keeps its original diagnostic framing; the game uses full 3D.
@export var immersive_mode := false
var exploration: ExplorationCamera

@export_group("Smoothing")
## How quickly the framing settles horizontally (1/s).
@export var horizontal_follow_rate := 9.0
## How quickly the camera follows height changes (1/s). Lower = calmer jumps.
@export var vertical_follow_rate := 5.0
## How quickly the look-ahead swings around (1/s).
@export var look_ahead_rate := 2.4
## Target speed (m/s) at which the look-ahead is fully extended.
@export var look_ahead_full_speed := 6.0
## Seconds a change of framing (distance / FOV / pitch) takes to settle. The
## blend eases in and out, so zooms never start or stop abruptly.
@export var profile_blend_time := 0.55

@export_group("Interest framing")
## The point of interest is ignored when further away than this (m).
@export var interest_range := 36.0
## Largest shift of the focus toward the point of interest (m).
@export var interest_max_shift := 5.0
## Largest extra zoom-out used to keep the point of interest in frame (m).
@export var interest_max_zoom_out := 8.0
@export var interest_rate := 2.0

## A jump of the target larger than this in one tick is treated as a teleport.
const TELEPORT_DISTANCE := 3.0

var _camera: Camera3D
var _profiles: Dictionary = {}
var _profile_serial := 0
var _interest_source: Object

var _focus := Vector3.ZERO
var _look_ahead := 0.0
var _interest_shift := 0.0
var _interest_zoom := 0.0
var _distance := 20.0
var _fov := 38.0
var _pitch := -7.0
var _focus_height := 1.4
var _depth_follow := 0.5
var _previous_target_position := Vector3.ZERO
var _initialised := false
## Rates of change of the blended framing values (for the critically damped blend).
var _blend_velocity: Dictionary = {}


func _ready() -> void:
	add_to_group(&"camera_rigs")
	_camera = get_node_or_null(^"Camera3D") as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		add_child(_camera)
	_camera.current = true
	if default_profile == null:
		default_profile = CameraProfile.new()
	if immersive_mode and target is Player:
		exploration = ExplorationCamera.new()
		exploration.name = "ExplorationCamera"
		add_child(exploration)
		exploration.bind(target as Player, _camera)
		return
	snap_to_target()


func _physics_process(delta: float) -> void:
	if exploration != null:
		exploration.physics_tick(delta)
		return
	if target == null or not is_instance_valid(target):
		return
	if not _initialised:
		snap_to_target()
	var profile := get_active_profile()
	_distance = _ease_toward(&"distance", _distance, profile.distance, delta)
	_fov = _ease_toward(&"fov", _fov, profile.fov, delta)
	_pitch = _ease_toward(&"pitch", _pitch, profile.pitch_degrees, delta)
	_focus_height = _ease_toward(&"focus_height", _focus_height, profile.focus_height, delta)
	_depth_follow = _ease_toward(&"depth_follow", _depth_follow, profile.depth_follow, delta)

	var target_position := target.global_position
	var step := target_position - _previous_target_position
	var teleported := step.length() > TELEPORT_DISTANCE
	_previous_target_position = target_position
	var target_velocity := Vector3.ZERO if teleported or delta <= 0.0 else step / delta

	# Look ahead in the direction of travel.
	var wanted_look_ahead := clampf(target_velocity.x / look_ahead_full_speed, -1.0, 1.0) * profile.look_ahead
	_look_ahead = lerpf(_look_ahead, wanted_look_ahead, 1.0 - exp(-look_ahead_rate * delta))

	# Optionally lean toward / widen for a point of interest (the train).
	var wanted_shift := 0.0
	var wanted_zoom := 0.0
	if _interest_source != null and is_instance_valid(_interest_source):
		var point: Vector3 = _interest_source.call(&"get_camera_interest_point", target_position)
		var offset := point.x - target_position.x
		var gap := absf(offset)
		var weight := 1.0 - smoothstep(interest_range * 0.6, interest_range, gap)
		wanted_shift = clampf(offset * 0.35, -interest_max_shift, interest_max_shift) * weight
		wanted_zoom = clampf(gap * 0.3, 0.0, interest_max_zoom_out) * weight
	var interest_blend := 1.0 - exp(-interest_rate * delta)
	_interest_shift = lerpf(_interest_shift, wanted_shift, interest_blend)
	_interest_zoom = lerpf(_interest_zoom, wanted_zoom, interest_blend)

	# Follow. The target's own motion is fed forward so a fast, steady target
	# (riding the train) is tracked without lag; the rest is eased.
	var wanted_focus := Vector3(
		target_position.x + _look_ahead + _interest_shift,
		target_position.y,
		target_position.z * _depth_follow
	)
	if not teleported:
		_focus.x += step.x
	var horizontal_blend := 1.0 - exp(-horizontal_follow_rate * delta)
	_focus.x = lerpf(_focus.x, wanted_focus.x, horizontal_blend)
	_focus.z = lerpf(_focus.z, wanted_focus.z, horizontal_blend)
	_focus.y = lerpf(_focus.y, wanted_focus.y, 1.0 - exp(-vertical_follow_rate * delta))
	_apply()


# --- Public API ----------------------------------------------------------------

func get_camera() -> Camera3D:
	return _camera


## Requests a framing. The highest priority request wins; ties go to the newest.
func push_profile(key: StringName, profile: CameraProfile, priority: int = 0) -> void:
	if profile == null:
		return
	_profile_serial += 1
	_profiles[key] = {"profile": profile, "priority": priority, "serial": _profile_serial}


func pop_profile(key: StringName) -> void:
	_profiles.erase(key)


func has_profile(key: StringName) -> bool:
	return _profiles.has(key)


func get_active_profile() -> CameraProfile:
	var best: CameraProfile = default_profile
	var best_priority := -1000000
	var best_serial := -1
	for key: StringName in _profiles:
		var entry: Dictionary = _profiles[key]
		var priority: int = entry["priority"]
		var serial: int = entry["serial"]
		if priority > best_priority or (priority == best_priority and serial > best_serial):
			best = entry["profile"]
			best_priority = priority
			best_serial = serial
	return best


## [param source] must implement get_camera_interest_point(from: Vector3) -> Vector3.
## Pass null to stop framing it.
func set_interest_source(source: Object) -> void:
	_interest_source = source


## Current framing values (for tests and debugging).
func get_framing() -> Dictionary:
	if exploration != null:
		return {"distance": exploration._collision_distance, "fov": _camera.fov,
			"pitch": rad_to_deg(exploration.pitch), "focus": target.global_position + Vector3.UP * ExplorationCamera.EYE_HEIGHT}
	return {"distance": _distance + _interest_zoom, "fov": _fov, "pitch": _pitch, "focus": _focus}


## Cuts straight to the target (only used on start-up).
func snap_to_target() -> void:
	if exploration != null:
		exploration.snap_to_target()
		return
	if target == null or not is_instance_valid(target) or _camera == null:
		return
	var profile := get_active_profile()
	_distance = profile.distance
	_fov = profile.fov
	_pitch = profile.pitch_degrees
	_focus_height = profile.focus_height
	_depth_follow = profile.depth_follow
	_look_ahead = 0.0
	_interest_shift = 0.0
	_interest_zoom = 0.0
	_blend_velocity.clear()
	_previous_target_position = target.global_position
	_focus = Vector3(_previous_target_position.x, _previous_target_position.y, _previous_target_position.z * _depth_follow)
	_initialised = true
	_apply()
	_camera.reset_physics_interpolation()


# --- Camera zones (called through the "camera_rigs" group) -------------------

func on_camera_zone_entered(zone: CameraZone, body: Node3D) -> void:
	if body == target:
		push_profile(_zone_key(zone), zone.profile, zone.camera_priority)


func on_camera_zone_exited(zone: CameraZone, body: Node3D) -> void:
	if body == target:
		pop_profile(_zone_key(zone))


## Critically damped spring toward [param target]: starts and ends with zero
## speed, never overshoots.
func _ease_toward(key: StringName, current: float, target: float, delta: float) -> float:
	var omega := 2.0 / maxf(profile_blend_time, 0.01)
	var x := omega * delta
	var decay := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var velocity: float = _blend_velocity.get(key, 0.0)
	var change := current - target
	var temp := (velocity + omega * change) * delta
	_blend_velocity[key] = (velocity - omega * temp) * decay
	return target + (change + temp) * decay


func _zone_key(zone: CameraZone) -> StringName:
	return StringName("zone_%d" % zone.get_instance_id())


func _apply() -> void:
	var camera_basis := Basis(Vector3.RIGHT, deg_to_rad(_pitch))
	var look_point := _focus + Vector3.UP * _focus_height
	_camera.global_transform = Transform3D(camera_basis, look_point + camera_basis.z * (_distance + _interest_zoom))
	_camera.fov = _fov
