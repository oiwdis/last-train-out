class_name FogSimulation
extends RefCounted
## Server-ready fixed-step authority. No nodes, clocks, rendering or player singleton.
signal event_announced(kind: String)
signal event_started(kind: String)
const STEP := 0.1
enum Danger { DISTANT, APPROACHING, CRITICAL, ENGULFED }
const EVENTS := ["surge", "calm", "dense", "disturbance"]
var config: FogConfig
var route: FogRoute
var front := 0.0
var elapsed := 0.0
var speed := 0.0
var remainder := 0.0
var station_id := "harlow"
var event := ""
var pending_event := ""
var warning_left := 0.0
var event_left := 0.0
var next_event := 0.0
var rng := RandomNumberGenerator.new()
var seed_value := 3001

func _init(tuning: FogConfig = null, railway: FogRoute = null, scenario_seed: int = 3001) -> void:
	config = tuning if tuning != null else FogConfig.new()
	route = railway
	seed_value = scenario_seed
	reset()

func reset() -> void:
	front = -config.initial_distance
	elapsed = 0
	remainder = 0
	event = ""
	pending_event = ""
	warning_left = 0
	event_left = 0
	station_id = "harlow"
	rng.seed = seed_value
	_schedule_event()
	speed = current_speed()

func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0:
		return
	remainder += delta
	while remainder + 0.00000001 >= STEP:
		remainder = maxf(0, remainder - STEP)
		step()

func step() -> void:
	elapsed += STEP
	if pending_event != "":
		warning_left = maxf(0, warning_left - STEP)
		if warning_left <= 0.00001:
			event = pending_event
			pending_event = ""
			event_left = config.event_duration
			event_started.emit(event)
	elif event != "":
		event_left = maxf(0, event_left - STEP)
		if event_left <= 0.00001:
			event = ""
			_schedule_event()
	elif config.events_enabled and elapsed >= next_event:
		request_event(EVENTS[rng.randi_range(0, EVENTS.size() - 1)])
	speed = current_speed()
	front += speed * STEP

func current_speed() -> float:
	var value := minf(config.maximum_speed, config.base_speed + elapsed / 60.0 * config.escalation_per_minute) * maxf(0.1, config.difficulty)
	if route != null and route.stations.has(station_id):
		var gap := float(route.stations[station_id]) - front
		if gap > 0 and gap < config.station_slow_radius:
			value *= config.station_speed_factor
	if event == "surge":
		value *= config.surge_multiplier
	elif event == "calm":
		value *= config.calm_multiplier
	return maxf(value, 0)

func danger(progress: float) -> Danger:
	var gap := progress - front
	if gap <= 0:
		return Danger.ENGULFED
	if gap <= config.critical_distance:
		return Danger.CRITICAL
	if gap <= config.approach_distance:
		return Danger.APPROACHING
	return Danger.DISTANT

## Conservative estimate assumes the maximum possible warned surge speed.
func seconds_to_danger(progress: float) -> float:
	var maximum := config.maximum_speed * maxf(0.1, config.difficulty) * config.surge_multiplier
	return maxf(0, progress - front) / maxf(0.01, maximum)

func request_event(kind: String) -> bool:
	if kind not in EVENTS or event != "" or pending_event != "":
		return false
	pending_event = kind
	warning_left = config.event_warning_seconds
	event_announced.emit(kind)
	return true

func enter_station(id: String) -> bool:
	if route == null or not route.stations.has(id):
		return false
	station_id = id
	return true

func _schedule_event() -> void:
	next_event = elapsed + rng.randf_range(config.event_interval_min, config.event_interval_max)

func snapshot() -> Dictionary:
	return {"version": 1, "route": route.signature() if route != null else "", "config": config.signature(),
		"front": front, "elapsed": elapsed, "remainder": remainder, "station": station_id,
		"event": event, "pending": pending_event, "warning": warning_left, "remaining": event_left,
		"next": next_event, "seed": str(seed_value), "rng": str(rng.state)}

## Reject incompatible/malformed saves atomically. Large RNG integers remain decimal strings in JSON.
func restore(data: Dictionary) -> bool:
	var expected := snapshot()
	for key in expected:
		if not data.has(key):
			return false
	if not (data.version is int or data.version is float) or not data.route is String or not data.config is Dictionary:
		return false
	if data.version != 1 or data.route != expected.route or data.config != expected.config:
		return false
	for key in ["front", "elapsed", "remainder", "warning", "remaining", "next"]:
		if not (data[key] is float or data[key] is int) or not is_finite(float(data[key])):
			return false
	if data.elapsed < 0 or data.remainder < 0 or data.remainder >= STEP or data.warning < 0 or data.remaining < 0:
		return false
	if not data.event is String or not data.pending is String or not data.station is String:
		return false
	if data.event not in EVENTS + [""] or data.pending not in EVENTS + [""]:
		return false
	if route != null and not route.stations.has(data.station):
		return false
	if not str(data.rng).is_valid_int() or not str(data.seed).is_valid_int():
		return false
	front = data.front
	elapsed = data.elapsed
	remainder = data.remainder
	station_id = data.station
	event = data.event
	pending_event = data.pending
	warning_left = data.warning
	event_left = data.remaining
	next_event = data.next
	seed_value = int(data.seed)
	rng.state = int(data.rng)
	speed = current_speed()
	return true
