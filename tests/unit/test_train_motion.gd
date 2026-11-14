extends TestSuite
## Train speed profile, departure modes, stop and reset - pure simulation
## (Train.advance()), independent of rendering and physics.

const DELTA := 1.0 / 60.0
const MODE_PATHS: Array[String] = [
	"res://resources/train/departure_emergency.tres",
	"res://resources/train/departure_normal.tres",
	"res://resources/train/departure_slow.tres",
]

var train: Train


func before_each() -> void:
	train = Train.new()
	var modes: Array[DepartureMode] = []
	for path in MODE_PATHS:
		modes.append(load(path) as DepartureMode)
	train.departure_modes = modes
	train.track_length = 100000.0
	add_child(train)
	train.set_physics_process(false)  # The tests drive advance() themselves.


func after_each() -> void:
	train.queue_free()


## Runs the simulation until [param state] is reached; returns elapsed seconds.
func _run_until(state: Train.State, limit: float = 60.0) -> float:
	var elapsed := 0.0
	while train.state != state and elapsed < limit:
		train.advance(DELTA)
		elapsed += DELTA
	return elapsed


func _check_mode(index: int, expected_time: float) -> void:
	train.set_mode_index(index)
	train.start()
	check_eq(train.state, Train.State.ACCELERATING, "train is accelerating after start()")
	var elapsed := 0.0
	var previous_speed := 0.0
	var peak_acceleration := 0.0
	var monotonic := true
	var first_tick_speed := -1.0
	while train.state == Train.State.ACCELERATING and elapsed < 60.0:
		train.advance(DELTA)
		elapsed += DELTA
		if first_tick_speed < 0.0:
			first_tick_speed = train.speed
		if train.speed < previous_speed - 0.00001:
			monotonic = false
		peak_acceleration = maxf(peak_acceleration, (train.speed - previous_speed) / DELTA)
		previous_speed = train.speed
	note("%s: full speed after %.2f s, peak acceleration %.2f m/s^2, %.1f m travelled" % [
		train.current_mode.display_name, elapsed, peak_acceleration, train.distance])
	check_near(elapsed, expected_time, 0.05, "%s reaches full speed on time" % train.current_mode.display_name)
	check_eq(train.state, Train.State.CRUISING, "train cruises after accelerating")
	check_near(train.speed, train.max_speed, 0.001, "train is at maximum speed")
	check(monotonic, "speed never decreases while accelerating")
	check_less(first_tick_speed, 0.01, "acceleration eases in from a standstill")
	# Smoothstep peaks at 1.5x the average acceleration; anything higher is a jolt.
	check_less(peak_acceleration, 1.5 * train.max_speed / expected_time * 1.03, "acceleration stays smooth")
	check_near(train.distance, 0.5 * train.max_speed * expected_time, 0.3, "distance covered matches the profile")


func test_emergency_steam_mode() -> void:
	_check_mode(0, 6.0)


func test_normal_mode() -> void:
	_check_mode(1, 10.0)


func test_slow_departure_mode() -> void:
	_check_mode(2, 16.0)


func test_default_mode_is_normal() -> void:
	check_eq(train.current_mode.id, &"normal", "the default departure mode is Normal")
	check_eq(train.state, Train.State.STOPPED, "train starts parked")
	check_near(train.speed, 0.0, 0.0001, "train starts at rest")


func test_acceleration_modifier_scales_time() -> void:
	train.acceleration_modifier = 0.5  # Heavier train: half the acceleration.
	train.set_mode_index(0)
	train.start()
	var elapsed := _run_until(Train.State.CRUISING)
	check_near(elapsed, 12.0, 0.05, "half the acceleration doubles the time to full speed")


func test_max_speed_is_configurable() -> void:
	train.max_speed = 20.0
	train.set_mode_index(0)
	train.start()
	_run_until(Train.State.CRUISING)
	check_near(train.speed, 20.0, 0.001, "train cruises at the configured maximum speed")


func test_max_speed_change_is_eased_while_moving() -> void:
	train.set_mode_index(0)
	train.start()
	_run_until(Train.State.CRUISING)
	train.max_speed = 20.0
	var previous := train.speed
	var worst_step := 0.0
	for i in 300:
		train.advance(DELTA)
		worst_step = maxf(worst_step, absf(train.speed - previous))
		previous = train.speed
	check_near(train.speed, 20.0, 0.001, "train settles on the new maximum speed")
	check_less(worst_step, train.max_speed_change_rate * DELTA * 1.05, "speed changes gradually, without a jump")


func test_stop_brakes_smoothly_to_standstill() -> void:
	var stopped_events := [0]
	train.stopped.connect(func() -> void: stopped_events[0] += 1)
	train.set_mode_index(0)
	train.start()
	_run_until(Train.State.CRUISING)
	train.stop()
	check_eq(train.state, Train.State.BRAKING, "train is braking after stop()")
	var previous := train.speed
	var monotonic := true
	var elapsed := 0.0
	while train.state == Train.State.BRAKING and elapsed < 60.0:
		train.advance(DELTA)
		elapsed += DELTA
		if train.speed > previous + 0.00001:
			monotonic = false
		previous = train.speed
	check_near(elapsed, train.braking_time, 0.05, "braking takes the configured time from full speed")
	check_eq(train.state, Train.State.STOPPED, "train ends up stopped")
	check_near(train.speed, 0.0, 0.0001, "speed is zero when stopped")
	check(monotonic, "speed never increases while braking")
	check_eq(stopped_events[0], 1, "stopped signal fires once")
	var distance := train.distance
	train.advance(1.0)
	check_near(train.distance, distance, 0.0001, "a stopped train does not move")


func test_stop_and_restart_mid_acceleration_is_continuous() -> void:
	train.set_mode_index(1)
	train.start()
	for i in 240:
		train.advance(DELTA)
	var speed_before := train.speed
	train.stop()
	train.advance(DELTA)
	check_less(absf(train.speed - speed_before), 0.15, "no speed jump when braking mid-acceleration")
	for i in 30:
		train.advance(DELTA)
	speed_before = train.speed
	train.start()
	train.advance(DELTA)
	check_less(absf(train.speed - speed_before), 0.15, "no speed jump when restarting mid-brake")
	_run_until(Train.State.CRUISING)
	check_near(train.speed, train.max_speed, 0.001, "train still reaches full speed")


func test_mode_change_mid_acceleration_is_continuous() -> void:
	train.set_mode_index(2)
	train.start()
	for i in 300:
		train.advance(DELTA)
	var speed_before := train.speed
	train.set_mode_index(0)
	train.advance(DELTA)
	check_less(absf(train.speed - speed_before), 0.15, "switching departure mode does not jump the speed")
	check_eq(train.current_mode.id, &"emergency", "mode switched")


func test_reset_returns_to_station() -> void:
	var reset_events := [0]
	train.reset_finished.connect(func() -> void: reset_events[0] += 1)
	train.set_mode_index(0)
	train.start()
	_run_until(Train.State.CRUISING)
	check_greater(train.distance, 10.0, "train has left the station")
	train.reset_to_station()
	check_eq(train.state, Train.State.STOPPED, "reset stops the train")
	check_near(train.speed, 0.0, 0.0001, "reset zeroes the speed")
	check_near(train.distance, 0.0, 0.0001, "reset returns the train to the stop")
	check_eq(reset_events[0], 1, "reset_finished fires once")
	train.start()
	var elapsed := _run_until(Train.State.CRUISING)
	check_near(elapsed, 6.0, 0.05, "a reset train departs normally again")


func test_brakes_before_end_of_track() -> void:
	train.track_length = 150.0
	train.set_mode_index(0)
	train.start()
	_run_until(Train.State.STOPPED, 120.0)
	note("stopped at %.1f m of a %.0f m track" % [train.distance, train.track_length])
	check_eq(train.state, Train.State.STOPPED, "train stops on its own near the end of the track")
	check_less(train.distance, train.track_length + 0.5, "train does not overrun the track")
	check_greater(train.distance, train.track_length - 5.0, "train uses the available track")
	check(train.is_at_end_of_track(), "train reports it is at the end of the track")
	check(not train.start(), "a train at the end of the track refuses to depart")
	check_eq(train.state, Train.State.STOPPED, "and stays stopped")
	train.reset_to_station()
	check(train.start(), "after a reset it departs again")
