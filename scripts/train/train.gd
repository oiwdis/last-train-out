class_name Train
extends Node3D
## Drives the consist along a straight track.
##
## Motion is integrated on the physics tick and applied to each [TrainCar]
## (kinematic AnimatableBody3D) so collision, platform riding and rendering all
## agree. The script owns the authoritative distance/speed; it never reads them
## back from the nodes.

signal departure_started(mode: DepartureMode)
signal full_speed_reached
signal braking_started
signal stopped
signal mode_changed(mode: DepartureMode)
signal state_changed(state: State)
## Emitted right before the cars are teleported back to the station.
signal reset_started
signal reset_finished

enum State { STOPPED, ACCELERATING, CRUISING, BRAKING }

## Available departure profiles, in the order shown in the debug menu.
@export var departure_modes: Array[DepartureMode] = []
@export var default_mode_index := 1
## Cruising speed in m/s.
@export_range(0.5, 40.0, 0.1) var max_speed := 12.0:
	set(value):
		max_speed = clampf(value, 0.5, 40.0)
## Seconds to brake from full speed to a standstill.
@export var braking_time := 6.0
## Scales acceleration; later milestones lower it as the train gets heavier.
@export_range(0.1, 4.0, 0.05) var acceleration_modifier := 1.0
## Direction of travel in the train's local space.
@export var travel_direction := Vector3.RIGHT
## Usable track ahead of the station stop, in metres. The train brakes
## automatically so it stops before the end.
@export var track_length := 480.0
## How quickly a change of [member max_speed] is followed while moving (m/s^2).
@export var max_speed_change_rate := 4.0

## Optional supply gate; the motion integrator remains independent.
var departure_allowed: Callable
var state := State.STOPPED
## Current speed along the track in m/s.
var speed := 0.0
## Metres travelled from the station stop.
var distance := 0.0
var current_mode: DepartureMode

var _cars: Array[TrainCar] = []
var _rest_positions: Array[Vector3] = []
## Normalised time along the active speed profile (0 = standstill, 1 = full speed).
var _profile_time := 0.0
var _brake_profile := DepartureMode.new()
var _effective_max_speed := 12.0
var _pending_interpolation_reset := 0


func _ready() -> void:
	for child in get_children():
		if child is TrainCar:
			_cars.append(child)
			_rest_positions.append((child as TrainCar).position)
	if departure_modes.is_empty():
		departure_modes = [DepartureMode.new()]
	current_mode = departure_modes[clampi(default_mode_index, 0, departure_modes.size() - 1)]
	_effective_max_speed = max_speed


func _physics_process(delta: float) -> void:
	if _pending_interpolation_reset > 0:
		_pending_interpolation_reset -= 1
		if _pending_interpolation_reset == 0:
			for car in _cars:
				car.reset_physics_interpolation()
	if state == State.STOPPED:
		return
	advance(delta)
	_apply_positions(speed * delta)


# --- Controls ----------------------------------------------------------------

## Starts (or resumes) accelerating using the current departure mode.
## Returns false when the train cannot depart (it is at the end of the track).
func start() -> bool:
	if departure_allowed.is_valid() and not departure_allowed.call():
		return false
	if state == State.ACCELERATING or state == State.CRUISING:
		return true
	if is_at_end_of_track():
		return false
	# Resume from the current speed so restarting mid-brake stays smooth.
	_profile_time = current_mode.inverse_sample(_speed_fraction())
	_set_state(State.ACCELERATING)
	departure_started.emit(current_mode)
	return true


## Brakes smoothly to a standstill.
func stop() -> void:
	if state == State.STOPPED or state == State.BRAKING:
		return
	_profile_time = _brake_profile.inverse_sample(_speed_fraction())
	_set_state(State.BRAKING)
	braking_started.emit()


## Teleports the train back to the station stop, at rest.
func reset_to_station() -> void:
	reset_started.emit()
	var was_moving := state != State.STOPPED
	speed = 0.0
	distance = 0.0
	_profile_time = 0.0
	_effective_max_speed = max_speed
	_set_state(State.STOPPED)
	_apply_positions(0.0)
	# The bodies reach the new transform on the next physics step; snap the
	# render interpolation afterwards so the cars do not streak across the map.
	_pending_interpolation_reset = 2
	if was_moving:
		stopped.emit()
	reset_finished.emit()


func set_mode(mode: DepartureMode) -> void:
	if mode == null or mode == current_mode:
		return
	var fraction := _speed_fraction()
	current_mode = mode
	if state == State.ACCELERATING:
		_profile_time = current_mode.inverse_sample(fraction)
	mode_changed.emit(current_mode)


func set_mode_index(index: int) -> void:
	if index >= 0 and index < departure_modes.size():
		set_mode(departure_modes[index])


func get_mode_index() -> int:
	return departure_modes.find(current_mode)


# --- Queries -----------------------------------------------------------------

func is_moving() -> bool:
	return speed > 0.01


## True once the train has used up its track and has to be reset.
func is_at_end_of_track() -> bool:
	return distance >= track_length - 1.0


func get_cars() -> Array[TrainCar]:
	return _cars


func get_velocity() -> Vector3:
	return global_basis * (travel_direction.normalized() * speed)


## World transform [param car] has when the train is parked at the station.
func get_rest_transform(car: TrainCar) -> Transform3D:
	var index := _cars.find(car)
	if index < 0:
		return car.global_transform
	return global_transform * Transform3D(car.transform.basis, _rest_positions[index])


## Whether [param world_point] lies inside the space the parked train occupies.
func is_point_in_rest_footprint(world_point: Vector3, margin: float = 0.4) -> bool:
	var local := to_local(world_point)
	for i in _cars.size():
		var half_length := _cars[i].car_length * 0.5 + margin
		var rest := _rest_positions[i]
		if absf(local.x - rest.x) <= half_length and absf(local.z - rest.z) <= 1.3 + margin and local.y < 4.5:
			return true
	return false


## Closest point of the train to [param from], used by the camera to keep
## nearby cars in frame without the camera knowing about trains.
func get_camera_interest_point(from: Vector3) -> Vector3:
	if _cars.is_empty():
		return global_position
	var axis := (global_basis * travel_direction).normalized()
	var low := INF
	var high := -INF
	for car in _cars:
		var along := car.global_position.dot(axis)
		low = minf(low, along - car.car_length * 0.5)
		high = maxf(high, along + car.car_length * 0.5)
	var origin := _cars[0].global_position
	var t := clampf(from.dot(axis), low, high)
	return origin + axis * (t - origin.dot(axis))


## Metres needed to stop from the current speed with the brake profile.
func get_braking_distance() -> float:
	var t := _brake_profile.inverse_sample(_speed_fraction())
	# Integral of smoothstep from 0 to t.
	return _effective_max_speed * braking_time * (t * t * t - 0.5 * t * t * t * t)


# --- Simulation --------------------------------------------------------------

## Advances speed and distance by [param delta] seconds. Pure bookkeeping (no
## node access), so it can be unit-tested without a physics world.
func advance(delta: float) -> void:
	if state == State.STOPPED:
		return
	_effective_max_speed = move_toward(_effective_max_speed, max_speed, max_speed_change_rate * delta)
	match state:
		State.ACCELERATING:
			var duration := maxf(current_mode.time_to_full_speed / maxf(acceleration_modifier, 0.01), 0.01)
			_profile_time = minf(_profile_time + delta / duration, 1.0)
			speed = _effective_max_speed * current_mode.sample(_profile_time)
			if _profile_time >= 1.0:
				_set_state(State.CRUISING)
				full_speed_reached.emit()
		State.CRUISING:
			speed = _effective_max_speed
		State.BRAKING:
			_profile_time = maxf(_profile_time - delta / maxf(braking_time, 0.01), 0.0)
			speed = _effective_max_speed * _brake_profile.sample(_profile_time)
			if _profile_time <= 0.0:
				speed = 0.0
				_set_state(State.STOPPED)
				stopped.emit()
	distance += speed * delta
	# Brake automatically before running out of track.
	if state != State.BRAKING and state != State.STOPPED:
		if distance + get_braking_distance() >= track_length:
			stop()


func _speed_fraction() -> float:
	return clampf(speed / _effective_max_speed, 0.0, 1.0) if _effective_max_speed > 0.0 else 0.0


func _apply_positions(distance_delta: float) -> void:
	var offset := travel_direction.normalized() * distance
	for i in _cars.size():
		_cars[i].position = _rest_positions[i] + offset
		if distance_delta != 0.0:
			_cars[i].roll_wheels(distance_delta)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	state_changed.emit(state)
