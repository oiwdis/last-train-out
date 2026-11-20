extends TestSuite
var config: FogConfig
var sim: FogSimulation

func before_each() -> void:
	config = FogConfig.new()
	config.events_enabled = false
	sim = FogSimulation.new(config)

func test_front_advances_exact_distance_without_escalation() -> void:
	config.escalation_per_minute = 0
	sim.advance(10)
	check_near(sim.front, -202, 0.00001, "ten seconds advances eight route metres")

func test_partitioned_time_matches_one_batch() -> void:
	var other := FogSimulation.new(config)
	sim.advance(23.47)
	for i in 2347:
		other.advance(0.01)
	check_near(sim.front, other.front, 0.000001, "frame partition does not change progression")
	check_near(sim.remainder, other.remainder, 0.000001, "fractional ticks retained")

func test_invalid_delta_cannot_rewind_or_poison_state() -> void:
	var before := sim.snapshot()
	for delta in [-1.0, NAN, INF, 0.0]:
		sim.advance(delta)
	check_eq(sim.snapshot(), before, "invalid times rejected")

func test_four_danger_boundaries() -> void:
	sim.front = 0
	check_eq(sim.danger(131), FogSimulation.Danger.DISTANT, "distant")
	check_eq(sim.danger(130), FogSimulation.Danger.APPROACHING, "approaching inclusive")
	check_eq(sim.danger(45), FogSimulation.Danger.CRITICAL, "critical inclusive")
	check_eq(sim.danger(0), FogSimulation.Danger.ENGULFED, "boundary damages")
	check_eq(sim.danger(-100), FogSimulation.Danger.ENGULFED, "deep fog")

func test_speed_escalates_and_caps() -> void:
	sim.advance(60)
	check_near(sim.speed, 0.88, 0.0001, "first minute escalation")
	sim.advance(1000)
	check_near(sim.speed, 1.6, 0.0001, "speed cap")

func test_difficulty_changes_progress() -> void:
	var hard := FogConfig.new()
	hard.events_enabled = false
	hard.difficulty = 1.5
	var other := FogSimulation.new(hard)
	sim.advance(30)
	other.advance(30)
	check_near(other.front + 210, (sim.front + 210) * 1.5, 0.00001, "hard fog advances proportionally")

func test_surge_always_warns_before_acceleration() -> void:
	config.escalation_per_minute = 0
	check(sim.request_event("surge"), "surge accepted")
	sim.advance(9.9)
	check_near(sim.speed, 0.8, 0.001, "no early surge")
	sim.advance(0.1)
	check_eq(sim.event, "surge", "starts after warning")
	check_near(sim.speed, 1.44, 0.001, "surge factor")
	sim.advance(16)
	check_eq(sim.event, "", "event expires")
	check_near(sim.speed, 0.8, 0.001, "normal speed resumes")

func test_event_requests_do_not_stack_or_skip_warning() -> void:
	check(not sim.request_event("unknown"), "unknown event refused")
	check(sim.request_event("surge"), "first event")
	check(not sim.request_event("surge"), "warning not restarted or stacked")
	sim.advance(10)
	check(not sim.request_event("calm"), "active event not overwritten")

func test_calm_slows_and_dense_does_not_change_speed() -> void:
	config.escalation_per_minute = 0
	sim.request_event("calm")
	sim.advance(10)
	check_near(sim.speed, 0.44, 0.001, "calm slowdown")
	sim.advance(16)
	sim.request_event("dense")
	sim.advance(10)
	check_near(sim.speed, 0.8, 0.001, "density is not speed")

func test_seeded_events_and_front_are_reproducible() -> void:
	config.events_enabled = true
	var other := FogSimulation.new(config, null, sim.seed_value)
	var events_a: Array = []
	var events_b: Array = []
	sim.event_announced.connect(func(kind: String) -> void: events_a.append(kind))
	other.event_announced.connect(func(kind: String) -> void: events_b.append(kind))
	sim.advance(1200)
	for i in 12000:
		other.advance(0.1)
	check_greater(events_a.size(), 6, "several seeded events exercised")
	check_eq(events_a, events_b, "same event sequence")
	check_near(sim.front, other.front, 0.000001, "same world state")

func test_json_save_continues_exact_random_sequence() -> void:
	config.events_enabled = true
	sim.advance(129.45)
	var data: Dictionary = JSON.parse_string(JSON.stringify(sim.snapshot()))
	var restored := FogSimulation.new(config)
	check(restored.restore(data), "JSON restore accepted")
	sim.advance(500)
	restored.advance(500)
	check_eq(str(restored.rng.state), str(sim.rng.state), "exact random state preserved")
	check_eq(restored.event, sim.event, "event sequence preserved")
	check_near(restored.front, sim.front, 0.00000001, "front preserved to nanometres")
	check_near(restored.remainder, sim.remainder, 0.00000001, "sub-tick preserved")

func test_bad_snapshot_rejected_atomically() -> void:
	for key in ["version", "front", "rng", "event", "remainder", "config"]:
		var before := sim.snapshot()
		var bad := before.duplicate(true)
		bad[key] = "invalid"
		check(not sim.restore(bad), "reject corrupt " + key)
		check_eq(sim.snapshot(), before, "no partial mutation for " + key)

func _route() -> FogRoute:
	var route := FogRoute.new()
	var first := FogRouteSegment.new()
	first.id = "west"
	first.next_ids = ["bend", "future_branch"]
	first.curve = Curve3D.new()
	first.curve.add_point(Vector3.ZERO)
	first.curve.add_point(Vector3(20, 0, 0))
	var second := FogRouteSegment.new()
	second.id = "bend"
	second.curve = Curve3D.new()
	second.curve.add_point(Vector3(20, 0, 0), Vector3.ZERO, Vector3(15, 0, 0))
	second.curve.add_point(Vector3(40, 0, 20), Vector3(0, 0, -15))
	route.segments = [first, second]
	route.stations = {"harlow": 0.0, "next": 40.0}
	return route

func test_progress_crosses_segments_without_reset() -> void:
	var route := _route()
	sim.route = route
	sim.front = 19
	sim.advance(4)
	check_eq(route.locate(sim.front).segment, "bend", "front passes junction")
	check_greater(sim.front, 20, "continuous route distance")

func test_curved_sample_and_projection_agree() -> void:
	var route := _route()
	var at := route.sample(35)
	check_greater(at.z, 1, "curve turns away from X")
	check_near(route.project(at, "bend"), 35, 0.1, "hinted projection follows curve")
	check_near(route.sample(-10).x, -10, 0.001, "initial fog extrapolates behind route")
	check_near(route.project(Vector3(-10, 2, 3)), -10, 0.001, "observer behind start remains exposed")

func test_station_transition_keeps_surge_time_and_front() -> void:
	sim.route = _route()
	sim.request_event("surge")
	sim.advance(9)
	var before := sim.front
	check(sim.enter_station("next"), "known station accepted")
	check_near(sim.front, before, 0.00001, "no front reset")
	sim.advance(1)
	check_eq(sim.event, "surge", "warning survives transition")
	check(not sim.enter_station("missing"), "unknown station rejected")
	check_eq(sim.station_id, "next", "valid station retained")

func test_station_approach_slowdown_only_before_station() -> void:
	sim.route = _route()
	sim.front = -20
	check_near(sim.current_speed(), 0.68, 0.001, "gentler station approach")
	sim.front = 20
	check_near(sim.current_speed(), 0.8, 0.001, "no permanent slowdown after station")

func test_stationary_and_reversing_train_are_caught() -> void:
	sim.advance(300)
	check_eq(sim.danger(0), FogSimulation.Danger.ENGULFED, "stationary train caught")
	check_eq(sim.danger(sim.front - 10), FogSimulation.Danger.ENGULFED, "reversing toward fog loses safety")

func test_faster_train_increases_gap() -> void:
	sim.front = -3
	sim.advance(30)
	check_greater(12 * 30 - sim.front, 300, "cruising train gains ground")

func test_conservative_eta_accounts_for_future_surges() -> void:
	var eta := sim.seconds_to_danger(0)
	sim.request_event("surge")
	sim.advance(eta)
	check_less(sim.front, 0, "display estimate never promises extra time")
