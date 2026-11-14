class_name RouteBot
extends RefCounted
## Drives a Player along waypoints using only scripted input - steering,
## sprinting, jumping and pressing interact - the way a person would.
##
## Each step is a Dictionary:
##   to:      Vector3  target position (only x/z are steered toward)
##   then:    String   optional action on arrival:
##                     "interact", "jump", "climb_up", "climb_down", "wait_grounded"
##   radius:  float    arrival radius (default 0.3 m)
##   sprint:  bool     allow sprinting on this leg (default: the bot's setting)
##   timeout: float    seconds allowed for this leg (default 12)

## Sprint whenever stamina allows. Stops shortly before running dry and
## resumes once [member resume_stamina] has regenerated.
var sprint := true
var rest_below := 2.0
var resume_stamina := 30.0

## Human-readable reason of the last failure ("" when the route succeeded).
var failure := ""
## Physics ticks the last run took.
var ticks := 0

var _player: Player
var _tree: SceneTree
var _resting := false


func _init(player: Player) -> void:
	_player = player
	_tree = player.get_tree()
	_player.input.scripted = true


## Follows [param steps]; returns true when every step was completed.
func run(steps: Array) -> bool:
	failure = ""
	ticks = 0
	for index in steps.size():
		var step: Dictionary = steps[index]
		if not await _go_to(step, index):
			_player.input.clear()
			return false
		var action: String = step.get("then", "")
		if action != "" and not await _perform(action, step, index):
			_player.input.clear()
			return false
	_player.input.clear()
	return true


func get_seconds() -> float:
	return float(ticks) / float(Engine.physics_ticks_per_second)


func _tick() -> void:
	await _tree.physics_frame
	ticks += 1


func _go_to(step: Dictionary, index: int) -> bool:
	var target: Vector3 = step["to"]
	var radius: float = step.get("radius", 0.3)
	var allow_sprint: bool = step.get("sprint", sprint)
	var limit := int(float(step.get("timeout", 12.0)) * Engine.physics_ticks_per_second)
	var best := INF
	var stalled := 0
	for i in limit:
		var offset := target - _player.global_position
		var flat := Vector2(offset.x, offset.z)
		var distance := flat.length()
		if distance <= radius:
			return true
		# Compensate for the slower depth axis so the heading is exact.
		var heading := Vector2(flat.x, flat.y / _player.config.depth_speed_scale).normalized()
		_player.input.script_move(heading.x, heading.y, allow_sprint and _wants_sprint())
		await _tick()
		if distance < best - 0.02:
			best = distance
			stalled = 0
		else:
			stalled += 1
			if stalled > 100 and _player.is_grounded():
				failure = "step %d: stuck %.2f m from %s at %s (state %s)" % [
					index, distance, str(target), str(_player.global_position.snappedf(0.01)), _player.get_state_name()]
				return false
	failure = "step %d: timed out heading for %s, stopped at %s" % [index, str(target), str(_player.global_position.snappedf(0.01))]
	return false


func _perform(action: String, _step: Dictionary, index: int) -> bool:
	match action:
		"jump":
			_player.input.script_jump()
			await _tick()
			return true
		"interact":
			_player.input.script_move(0.0)
			_player.input.script_interact()
			for i in 30:
				await _tick()
				if _player.state in [Player.State.VAULT, Player.State.MOUNT, Player.State.CLIMB, Player.State.HANG]:
					break
			if not _player.state in [Player.State.VAULT, Player.State.MOUNT, Player.State.CLIMB, Player.State.HANG]:
				failure = "step %d: interact did nothing at %s" % [index, str(_player.global_position.snappedf(0.01))]
				return false
			for i in 180:
				if not _player.state in [Player.State.VAULT, Player.State.MOUNT]:
					return true
				await _tick()
			failure = "step %d: interaction never finished" % index
			return false
		"climb_up":
			_player.input.script_move(0.0, -1.0)
			var mounted := false
			for i in 480:
				await _tick()
				if _player.state == Player.State.MOUNT:
					mounted = true
				if mounted and _player.is_grounded():
					_player.input.script_move(0.0)
					return true
			failure = "step %d: did not reach the top of the ladder (state %s)" % [index, _player.get_state_name()]
			return false
		"climb_down":
			_player.input.script_move(0.0, 1.0)
			for i in 480:
				await _tick()
				if _player.is_grounded():
					_player.input.script_move(0.0)
					return true
			failure = "step %d: did not reach the bottom of the ladder (state %s)" % [index, _player.get_state_name()]
			return false
		"wait_grounded":
			for i in 240:
				await _tick()
				if _player.is_grounded():
					return true
			failure = "step %d: never landed" % index
			return false
	failure = "step %d: unknown action '%s'" % [index, action]
	return false


func _wants_sprint() -> bool:
	var stamina := _player.stamina
	if _resting:
		if stamina.current >= resume_stamina and not stamina.is_exhausted:
			_resting = false
	elif stamina.current <= rest_below or stamina.is_exhausted:
		_resting = true
	return not _resting
