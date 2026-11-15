extends TestSuite
var dose: FogExposure
var config: FogConfig
func before_each() -> void:
	dose = FogExposure.new()
	config = FogConfig.new()
func after_each() -> void:
	dose.free()
func test_exposure_accumulates_with_time_and_depth() -> void:
	dose.tick(1, 0, 0, config)
	check_near(dose.exposure, 3, 0.001, "boundary dose")
	dose.reset()
	dose.tick(1, 35, 0, config)
	check_near(dose.exposure, 6, 0.001, "deeper doubles dose")
func test_safety_recovers_exposure_without_free_healing() -> void:
	dose.exposure = 50
	dose.health = 70
	dose.tick(4, -0.1, 0, config)
	check_near(dose.exposure, 30, 0.001, "five units recovered per second")
	check_near(dose.health, 70, 0.001, "health damage remains meaningful")
func test_damage_is_gradual_after_warning_dose() -> void:
	dose.tick(1, 0, 0, config)
	check_near(dose.health, 100, 0.001, "brief boundary crossing forgivable")
	for i in 100:
		dose.tick(0.1, 0, 0, config)
	check_less(dose.health, 100, "sustained exposure hurts")
	check_greater(dose.health, 70, "no instant death")
func test_damage_calculation() -> void:
	dose.exposure = 100
	dose.tick(1, 35, 0.5, config)
	check_near(dose.health, 93.75, 0.001, "dose, depth and cover all scale damage")
func test_shelter_delays_but_cannot_prevent_death() -> void:
	var deaths := [0]
	dose.died.connect(func() -> void: deaths[0] += 1)
	for i in 3000:
		dose.tick(0.1, 50, config.protection_cab, config)
	check(dose.dead, "closed cab eventually fails")
	check_eq(deaths[0], 1, "one death notification")
func test_cover_order_and_independent_players() -> void:
	var covered := FogExposure.new()
	dose.tick(5, 0, 0, config)
	covered.tick(5, 0, config.protection_cab, config)
	check_less(covered.exposure, dose.exposure, "cab reduces dose")
	check_greater(config.protection_cab, config.protection_passenger, "cab strongest")
	check_greater(config.protection_passenger, config.protection_building, "crew beats leaking buildings")
	check_greater(config.protection_building, config.protection_open, "platform least shelter")
	covered.free()
func test_difficulty_scales_dose() -> void:
	config.difficulty = 1.5
	dose.tick(1, 0, 0, config)
	check_near(dose.exposure, 4.5, 0.001, "difficulty dose factor")
func test_exposure_save_and_validation() -> void:
	dose.exposure = 40
	dose.health = 55
	var copy: Dictionary = JSON.parse_string(JSON.stringify(dose.snapshot()))
	dose.reset()
	check(dose.restore(copy), "roundtrip")
	check_near(dose.health, 55, 0.001, "health restored")
	check(not dose.restore({"health": -1, "exposure": 0}), "negative health refused")
	check_near(dose.exposure, 40, 0.001, "invalid restore atomic")
