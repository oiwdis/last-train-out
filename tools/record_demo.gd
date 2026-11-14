extends Node
## Developer tool: plays a scripted tour of the milestone for a recording.
##
## The player is driven only through its scripted-input hook (the same inputs a
## person would give), so the recording shows real gameplay. Record with
## Godot's Movie Maker mode, which renders every frame regardless of speed:
##   godot --path . --write-movie demo.avi --fixed-fps 30 tools/record_demo.tscn

const MAIN_SCENE := "res://scenes/main/main.tscn"

var _game: Game
var _player: Player
var _train: Train
var _bot: RouteBot


func _ready() -> void:
	_game = (load(MAIN_SCENE) as PackedScene).instantiate() as Game
	add_child(_game)
	_player = _game.player
	_train = _game.train
	_player.input.scripted = true
	_player.input.clear()
	_bot = RouteBot.new(_player)
	_run.call_deferred()


func _run() -> void:
	await _seconds(1.2)
	await _movement_basics()
	await _freight_yard_climb()
	await _board_by_jumping()
	await _board_by_ladder()
	await _seconds(0.5)
	print("[demo] finished after %.1f s of game time; aboard the train: %s" % [
		float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second, str(_player.is_on_train())])
	get_tree().quit()


## Runs a bot route and reports (but does not hide) any step that failed.
func _route(steps: Array) -> void:
	if not await _bot.run(steps):
		push_warning("[demo] route step failed: %s" % _bot.failure)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _seconds(duration: float) -> void:
	await _frames(maxi(roundi(duration * Engine.physics_ticks_per_second), 1))


func _caption(text: String, duration: float = 4.0) -> void:
	_game.hud.show_message(text, duration)


func _v(x: float, z: float) -> Vector3:
	return Vector3(x, 0.0, z)


# 1. Walking, sprinting, jumping and vaulting on the platform.
func _movement_basics() -> void:
	_caption("Walk  -  A / D")
	_player.input.script_move(-1.0)
	await _seconds(1.6)
	_caption("Sprint  -  Shift")
	_player.input.script_move(1.0, 0.0, true)
	await _seconds(1.1)
	_caption("Jump  -  Space")
	_player.input.script_jump()
	await _seconds(0.8)
	_player.input.script_move(0.0)
	await _seconds(0.5)
	_player.input.script_jump()
	await _seconds(1.0)
	_caption("Vault low obstacles  -  E")
	_bot.sprint = false
	await _route([{"to": _v(19.4, 1.35)}, {"to": _v(18.35, 1.35), "then": "interact"}])
	_bot.sprint = true
	_player.input.script_move(-1.0)
	await _seconds(0.5)
	_player.input.script_move(0.0)
	await _seconds(0.6)


# 2. Ladders, roofs and a jumpable gap in the freight yard.
func _freight_yard_climb() -> void:
	_player.teleport_to(Vector3(100.8, 0.05, 1.7))
	await _seconds(1.6)
	_caption("Climb ladders  -  E, then W / S")
	await _route([{"to": _v(101.55, 2.0), "then": "interact"}])
	await _route([{"to": _player.global_position, "then": "climb_up"}])
	_caption("Sprint and jump across the gap")
	await _route([{"to": _v(104.0, 0.2)}, {"to": _v(107.6, 0.2), "then": "jump"}, {"to": _v(112.5, 0.2), "timeout": 4.0}])
	await _route([{"to": _v(116.85, 0.9), "then": "interact"}])
	await _route([{"to": _player.global_position, "then": "climb_down"}])
	await _seconds(0.6)


# 3. Normal departure: run along the platform and jump onto the open deck.
func _board_by_jumping() -> void:
	var flat_car := _train.get_node("FlatCar") as TrainCar
	_player.teleport_to(Vector3(flat_car.global_position.x + 3.0, 1.05, -1.5))
	_game.debug_menu.set_open(true)
	await _seconds(2.0)
	_caption("Normal departure  -  sprint and jump aboard", 6.0)
	_train.set_mode_index(1)
	_train.start()
	for i in 900:
		await _frames(1)
		var lead := _player.global_position.x - flat_car.global_position.x
		if lead > 0.4:
			_player.input.script_move(0.0)
		elif lead < -0.4:
			_player.input.script_move(1.0, 0.0, true)
		else:
			_player.input.script_move(1.0)
		if _train.speed > 4.0 and absf(lead) < 0.6 and _player.is_grounded():
			_player.input.script_move(1.0, -1.0, true)
			_player.input.script_jump()
			break
	for i in 120:
		await _frames(1)
		if _player.is_grounded():
			break
	_player.input.script_move(0.0)
	_caption("Riding the moving train", 4.0)
	await _seconds(2.0)
	_player.input.script_move(-1.0)
	await _seconds(0.5)
	_player.input.script_move(0.0)
	await _seconds(2.5)
	_game.debug_menu.set_open(false)
	await _seconds(0.5)


# 4. Emergency Steam: catch the passing ladder, climb to the roof, ride out of the station.
func _board_by_ladder() -> void:
	_game.reset_station()
	await _seconds(1.0)
	var ladder := _train.get_node("CrewCar/RoofLadder") as Ladder
	_player.teleport_to(Vector3(ladder.global_position.x + 9.0, 1.05, -1.55))
	await _seconds(1.5)
	_caption("Emergency Steam  -  grab the ladder as it passes  (E)", 6.0)
	_train.set_mode_index(0)
	_train.start()
	for i in 900:
		await _frames(1)
		var gap := _player.global_position.x - ladder.global_position.x
		if gap < 4.0:
			_player.input.script_move(1.0, 0.0, true)  # Run with the train as it arrives.
		if gap < 0.45:
			_player.input.script_interact()
			break
	await _seconds(0.5)
	_player.input.script_move(0.0, -1.0)
	for i in 400:
		await _frames(1)
		if _player.state != Player.State.CLIMB and _player.is_grounded():
			break
	_player.input.script_move(0.0)
	_caption("On the roof  -  buildings open up as the train passes behind them", 6.0)
	await _seconds(2.2)
	_player.input.script_move(1.0)
	await _seconds(1.2)
	_player.input.script_move(0.0)
	await _seconds(6.0)
