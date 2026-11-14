extends TestSuite
## The real input path: physical key events -> Input Map -> PlayerInput ->
## Player. (Every other suite drives the player through PlayerInput's
## scripted hook; this one proves the key bindings themselves.)

const SANDBOX := "res://scenes/main/movement_sandbox.tscn"
const GROUND_SPOT := Vector3(60.0, 0.05, 0.5)

var game: Game
var player: Player
var _held: Array[Key] = []


func before_each() -> void:
	game = await spawn_scene(SANDBOX) as Game
	player = game.player
	player.input.scripted = false
	player.teleport_to(GROUND_SPOT)
	await physics_frames(20)


func after_each() -> void:
	for key in _held.duplicate():
		_key(key, false)
	await free_spawned()


func _key(physical: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	if pressed and not _held.has(physical):
		_held.append(physical)
	elif not pressed:
		_held.erase(physical)


func _tap(physical: Key) -> void:
	_key(physical, true)
	await physics_frames(2)
	_key(physical, false)


func test_d_and_a_walk_right_and_left() -> void:
	var x := player.global_position.x
	_key(KEY_D, true)
	await seconds(0.5)
	check_greater(player.global_position.x, x + 1.0, "D walks right")
	check_eq(player.state, Player.State.WALK, "state is WALK")
	_key(KEY_D, false)
	await seconds(0.3)
	check_eq(player.state, Player.State.IDLE, "releasing D stops the player")
	x = player.global_position.x
	_key(KEY_A, true)
	await seconds(0.5)
	_key(KEY_A, false)
	check_less(player.global_position.x, x - 1.0, "A walks left")


func test_arrow_keys_also_move() -> void:
	var start := player.global_position
	_key(KEY_RIGHT, true)
	await seconds(0.4)
	_key(KEY_RIGHT, false)
	check_greater(player.global_position.x, start.x + 0.8, "right arrow walks right")
	var z := player.global_position.z
	_key(KEY_UP, true)
	await seconds(0.4)
	_key(KEY_UP, false)
	check_less(player.global_position.z, z - 0.5, "up arrow moves into the scene")


func test_w_and_s_move_in_depth() -> void:
	var z := player.global_position.z
	_key(KEY_W, true)
	await seconds(0.4)
	_key(KEY_W, false)
	check_less(player.global_position.z, z - 0.5, "W moves into the scene")
	z = player.global_position.z
	_key(KEY_S, true)
	await seconds(0.4)
	_key(KEY_S, false)
	check_greater(player.global_position.z, z + 0.5, "S moves out of the scene")


func test_shift_sprints() -> void:
	_key(KEY_SHIFT, true)
	_key(KEY_D, true)
	await seconds(0.6)
	check_eq(player.state, Player.State.SPRINT, "Shift + D sprints")
	check_near(player.get_horizontal_speed(), player.config.sprint_speed, 0.1, "at sprint speed")
	check_less(player.stamina.current, player.stamina.max_stamina, "and uses stamina")
	_key(KEY_SHIFT, false)
	await seconds(0.3)
	check_eq(player.state, Player.State.WALK, "releasing Shift drops back to a walk")
	_key(KEY_D, false)


func test_space_jumps() -> void:
	var jumps := [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	_key(KEY_SPACE, true)
	await physics_frames(8)
	check_eq(jumps[0], 1, "Space jumps once")
	check(not player.is_grounded(), "player is airborne")
	await seconds(1.0)
	check_eq(jumps[0], 1, "holding Space does not jump again")
	_key(KEY_SPACE, false)


func test_e_interacts() -> void:
	player.teleport_to(Vector3(47.0, 0.05, 1.7), Vector3.FORWARD)
	await physics_frames(15)
	await _tap(KEY_E)
	await seconds(0.6)
	check_eq(player.state, Player.State.CLIMB, "E grabs the ladder")
	_key(KEY_W, true)
	await seconds(0.5)
	_key(KEY_W, false)
	check_greater(player.global_position.y, 0.8, "W climbs the ladder")
	await _tap(KEY_E)
	await seconds(0.2)
	check(player.state != Player.State.CLIMB, "E lets go")


func test_debug_menu_keys() -> void:
	var menu := game.debug_menu
	menu.set_open(false)
	await _tap(KEY_F1)
	await get_tree().process_frame
	check(menu.is_open(), "F1 opens the debug menu")
	await _tap(KEY_ESCAPE)
	await get_tree().process_frame
	check(not menu.is_open(), "Esc closes the debug menu")
	await _tap(KEY_QUOTELEFT)
	await get_tree().process_frame
	check(menu.is_open(), "the backquote key also opens it")
	# Gameplay keys still reach the player while the menu is open.
	var x := player.global_position.x
	_key(KEY_D, true)
	await seconds(0.5)
	_key(KEY_D, false)
	check_greater(player.global_position.x, x + 1.0, "movement keys work while the menu is open")
