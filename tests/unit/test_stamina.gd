extends TestSuite
## Sprint stamina rules, tested on the component alone (no scene needed).

const DELTA := 1.0 / 60.0

var stamina: PlayerStamina


func before_each() -> void:
	stamina = PlayerStamina.new()
	add_child(stamina)


func after_each() -> void:
	stamina.queue_free()


func _tick(duration: float, sprinting: bool) -> void:
	for i in roundi(duration / DELTA):
		stamina.tick(DELTA, sprinting)


func test_starts_full() -> void:
	check_near(stamina.current, stamina.max_stamina, 0.001, "stamina starts full")
	check(stamina.can_sprint(), "sprinting is available at the start")


func test_drains_while_sprinting() -> void:
	_tick(2.0, true)
	check_near(stamina.current, stamina.max_stamina - 2.0 * stamina.drain_per_second, 0.05, "stamina drains at the configured rate")
	check(not stamina.is_exhausted, "player is not exhausted yet")


func test_does_not_drain_when_not_sprinting() -> void:
	_tick(2.0, false)
	check_near(stamina.current, stamina.max_stamina, 0.001, "walking costs nothing")


func test_regeneration_waits_for_delay() -> void:
	_tick(2.0, true)
	var after_sprint := stamina.current
	_tick(stamina.regen_delay - 0.1, false)
	check_near(stamina.current, after_sprint, 0.001, "no regeneration during the delay")
	_tick(0.1 + 1.0, false)
	check_near(stamina.current, after_sprint + 1.0 * stamina.regen_per_second, 0.6, "stamina regenerates at the configured rate after the delay")


func test_regenerates_to_full_and_stops() -> void:
	_tick(3.0, true)
	_tick(20.0, false)
	check_near(stamina.current, stamina.max_stamina, 0.001, "stamina refills completely and is clamped")


func test_exhaustion_locks_sprinting_until_recovered() -> void:
	var exhausted_events := [0]
	var recovered_events := [0]
	stamina.exhausted.connect(func() -> void: exhausted_events[0] += 1)
	stamina.recovered.connect(func() -> void: recovered_events[0] += 1)
	_tick(stamina.max_stamina / stamina.drain_per_second + 0.5, true)
	check_near(stamina.current, 0.0, 0.001, "stamina bottoms out at zero")
	check(stamina.is_exhausted, "player becomes exhausted")
	check(not stamina.can_sprint(), "exhausted player cannot sprint")
	check_eq(exhausted_events[0], 1, "exhausted signal fires once")
	# Holding sprint while exhausted must not block regeneration.
	_tick(stamina.regen_delay + 0.5, true)
	check_greater(stamina.current, 0.0, "stamina regenerates even while sprint is held")
	check(stamina.is_exhausted, "still exhausted below the recovery threshold")
	_tick(1.0, false)
	check(not stamina.is_exhausted, "recovered above the threshold")
	check(stamina.can_sprint(), "sprinting is available again")
	check_eq(recovered_events[0], 1, "recovered signal fires once")


func test_reset_restores_everything() -> void:
	_tick(stamina.max_stamina / stamina.drain_per_second + 0.5, true)
	stamina.reset()
	check_near(stamina.current, stamina.max_stamina, 0.001, "reset refills stamina")
	check(not stamina.is_exhausted, "reset clears exhaustion")
