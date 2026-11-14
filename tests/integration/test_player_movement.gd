extends TestSuite
## Walking, sprinting, jumping, stamina and the forgiving-jump timings.

const SANDBOX := "res://scenes/main/movement_sandbox.tscn"
## A clear spot on the flat ground to the right of the platform.
const GROUND_SPOT := Vector3(60.0, 0.05, 0.5)
## Near the right-hand end of the raised platform (edge at x = 30).
const PLATFORM_EDGE_SPOT := Vector3(28.6, 1.05, 0.5)

var game: Game
var player: Player
var states: Array[Player.State] = []
var jump_count := 0


func before_each() -> void:
	game = await spawn_scene(SANDBOX) as Game
	player = game.player
	player.input.scripted = true
	player.input.clear()
	states.clear()
	jump_count = 0
	player.state_changed.connect(func(_previous: Player.State, current: Player.State) -> void: states.append(current))
	player.jumped.connect(func() -> void: jump_count += 1)
	player.teleport_to(GROUND_SPOT)
	await physics_frames(20)
	states.clear()


func after_each() -> void:
	await free_spawned()


func test_idle_at_rest() -> void:
	check_eq(player.state, Player.State.IDLE, "player idles when there is no input")
	check(player.is_grounded(), "player stands on the ground")
	check_near(player.get_horizontal_speed(), 0.0, 0.01, "player is not moving")


func test_walk_speed_and_responsiveness() -> void:
	player.input.script_move(1.0)
	await seconds(0.15)
	check_near(player.get_horizontal_speed(), player.config.walk_speed, 0.05, "walk speed is reached within 0.15 s")
	check_eq(player.state, Player.State.WALK, "state is WALK")
	var x_start := player.global_position.x
	await seconds(1.0)
	check_near(player.global_position.x - x_start, player.config.walk_speed, 0.05, "covers walk_speed metres per second")
	player.input.script_move(0.0)
	await seconds(0.15)
	check_near(player.get_horizontal_speed(), 0.0, 0.05, "stops within 0.15 s")
	check_eq(player.state, Player.State.IDLE, "state returns to IDLE")


func test_sprint_speed_and_state_transitions() -> void:
	player.input.script_move(1.0)
	await seconds(0.3)
	player.input.script_move(1.0, 0.0, true)
	await seconds(0.3)
	check_near(player.get_horizontal_speed(), player.config.sprint_speed, 0.05, "sprint speed is reached")
	check_eq(player.state, Player.State.SPRINT, "state is SPRINT")
	check(player.is_sprinting(), "player reports sprinting")
	player.input.script_move(1.0)
	await seconds(0.3)
	check_eq(player.state, Player.State.WALK, "releasing sprint returns to WALK")
	check_near(player.get_horizontal_speed(), player.config.walk_speed, 0.05, "speed returns to walk speed")
	player.input.script_move(0.0)
	await seconds(0.3)
	check_eq(states, [Player.State.WALK, Player.State.SPRINT, Player.State.WALK, Player.State.IDLE] as Array[Player.State],
		"state sequence is WALK -> SPRINT -> WALK -> IDLE")


func test_turnaround_is_quick() -> void:
	player.input.script_move(1.0, 0.0, true)
	await seconds(0.5)
	player.input.script_move(-1.0, 0.0, true)
	await seconds(0.3)
	check_less(player.velocity.x, -player.config.sprint_speed + 0.3, "full speed in the opposite direction within 0.3 s")


func test_depth_movement() -> void:
	var z_start := player.global_position.z
	player.input.script_move(0.0, -1.0)
	await seconds(0.5)
	check_less(player.global_position.z, z_start - 0.8, "W moves into the scene (-Z)")
	player.input.script_move(0.0, 1.0)
	await seconds(1.0)
	check_greater(player.global_position.z, z_start, "S moves out of the scene (+Z)")
	player.input.script_move(0.0)


func test_jump_height_and_states() -> void:
	var ground_y := player.global_position.y
	player.input.script_jump()
	var peak := 0.0
	var airtime := 0
	for i in 120:
		await physics_frames(1)
		peak = maxf(peak, player.global_position.y - ground_y)
		if not player.is_grounded():
			airtime += 1
		elif i > 3:
			break
	note("apex %.3f m, air time %.2f s" % [peak, airtime * tick_delta()])
	check_near(peak, player.config.jump_height, 0.1, "jump reaches the configured height")
	check(player.is_grounded(), "player lands again")
	check_near(player.global_position.y, ground_y, 0.02, "player lands at the same height")
	check_eq(states, [Player.State.JUMP, Player.State.FALL, Player.State.IDLE] as Array[Player.State],
		"state sequence is JUMP -> FALL -> IDLE")
	check_eq(jump_count, 1, "exactly one jump happened")


func test_short_hop_when_jump_released_early() -> void:
	var ground_y := player.global_position.y
	player.input.script_jump(false)  # Tap: pressed but not held.
	var peak := 0.0
	for i in 90:
		await physics_frames(1)
		peak = maxf(peak, player.global_position.y - ground_y)
	note("tap-jump apex %.3f m" % peak)
	check_less(peak, player.config.jump_height * 0.6, "a tapped jump is clearly lower than a held jump")
	check_greater(peak, 0.15, "a tapped jump still leaves the ground")


func test_holding_jump_does_not_repeat() -> void:
	player.input.script_jump()
	await seconds(2.0)
	check_eq(jump_count, 1, "holding the button performs a single jump")


func test_sprint_jump_covers_distance() -> void:
	player.input.script_move(1.0, 0.0, true)
	await seconds(0.4)
	var x_start := player.global_position.x
	player.input.script_jump()
	await physics_frames(2)
	for i in 120:
		await physics_frames(1)
		if player.is_grounded():
			break
	var distance := player.global_position.x - x_start
	note("sprint jump length %.2f m" % distance)
	check_greater(distance, 3.4, "a sprinting jump clears a wide gap")
	check_less(distance, 4.8, "jump length is predictable")
	player.input.script_move(0.0)


func test_stamina_drains_only_while_sprinting_then_regenerates() -> void:
	var stamina := player.stamina
	player.input.script_move(1.0)
	await seconds(1.0)
	check_near(stamina.current, stamina.max_stamina, 0.001, "walking does not use stamina")
	player.input.script_move(1.0, 0.0, true)
	await seconds(2.0)
	check_near(stamina.current, stamina.max_stamina - 2.0 * stamina.drain_per_second, 0.5, "sprinting drains stamina")
	player.input.script_move(0.0, 0.0, true)
	await seconds(0.5)
	var resting := stamina.current
	check_near(resting, stamina.max_stamina - 2.0 * stamina.drain_per_second, 0.5, "holding sprint while standing still costs nothing")
	await seconds(stamina.regen_delay + 1.0)
	check_greater(stamina.current, resting + 5.0, "stamina regenerates after the delay")


func test_exhaustion_forces_walking() -> void:
	var stamina := player.stamina
	stamina.current = stamina.drain_per_second * 0.5  # Half a second of sprint left.
	player.input.script_move(1.0, 0.0, true)
	await seconds(1.2)
	check(stamina.is_exhausted, "player ran out of stamina")
	check_near(player.get_horizontal_speed(), player.config.walk_speed, 0.1, "exhausted player falls back to walking speed")
	check_eq(player.state, Player.State.WALK, "state is WALK while exhausted")
	game.reset_stamina()
	await seconds(0.4)
	check_eq(player.state, Player.State.SPRINT, "sprinting resumes once stamina is restored")
	player.input.script_move(0.0)


func _walk_off_platform_edge() -> bool:
	player.teleport_to(PLATFORM_EDGE_SPOT)
	await physics_frames(20)
	player.input.script_move(1.0)
	for i in 120:
		await physics_frames(1)
		if not player.is_on_floor():
			return true
	return false


func test_coyote_time_allows_late_jump() -> void:
	check(await _walk_off_platform_edge(), "player walked off the platform edge")
	await physics_frames(4)  # 4 ticks (~0.07 s) after leaving the edge: inside the grace period.
	player.input.script_jump()
	await physics_frames(2)
	check_eq(jump_count, 1, "jump is accepted shortly after leaving the ledge")
	check_greater(player.velocity.y, 3.0, "player is moving upward")
	player.input.script_move(0.0)


func test_coyote_time_expires() -> void:
	check(await _walk_off_platform_edge(), "player walked off the platform edge")
	await physics_frames(12)  # 0.2 s after leaving the edge: grace period is over.
	player.input.script_jump()
	await physics_frames(2)
	check_eq(jump_count, 0, "jump is refused once coyote time has passed")
	check_less(player.velocity.y, 0.0, "player keeps falling")
	player.input.script_move(0.0)


## Drops the player from [param height] and returns how many ticks the fall takes.
func _measure_fall_ticks(height: float) -> int:
	player.teleport_to(GROUND_SPOT + Vector3.UP * height)
	for i in 240:
		await physics_frames(1)
		if player.is_grounded():
			return i + 1
	return -1


func test_jump_buffer_executes_on_landing() -> void:
	var fall_ticks := await _measure_fall_ticks(1.2)
	check_greater(float(fall_ticks), 10.0, "fall lasts long enough to test buffering")
	player.teleport_to(GROUND_SPOT + Vector3.UP * 1.2)
	await physics_frames(fall_ticks - 4)  # Press ~4 ticks (0.07 s) before touchdown.
	check(not player.is_grounded(), "player is still falling when jump is pressed")
	player.input.script_jump()
	await physics_frames(10)
	check_eq(jump_count, 1, "buffered jump fires on landing")
	check_greater(player.global_position.y, GROUND_SPOT.y + 0.2, "player is airborne again")


func test_jump_buffer_expires() -> void:
	var fall_ticks := await _measure_fall_ticks(1.2)
	player.teleport_to(GROUND_SPOT + Vector3.UP * 1.2)
	await physics_frames(maxi(fall_ticks - 14, 1))  # Press ~14 ticks (0.23 s) before touchdown.
	check(not player.is_grounded(), "player is still falling when jump is pressed")
	player.input.script_jump(false)
	await physics_frames(24)
	check_eq(jump_count, 0, "a jump pressed too early is forgotten")
	check(player.is_grounded(), "player simply lands")


func test_reset_player_returns_to_spawn() -> void:
	player.input.script_move(1.0, 0.0, true)
	await seconds(1.0)
	game.reset_player()
	player.input.script_move(0.0)
	await physics_frames(20)
	check_less(player.global_position.distance_to(game.get_spawn_position()), 0.1, "player is back at the spawn point")
	check(player.is_grounded(), "player is grounded after the reset")
	check_near(player.get_world_velocity().length(), 0.0, 0.05, "player has no leftover velocity")
