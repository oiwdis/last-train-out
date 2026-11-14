class_name RailAudio
extends Node
## Quiet original synthesized ambience; no soundtrack or external recordings.

var player: Player
var train: Train
var _engine: AudioStreamPlayer3D
var _steps: AudioStreamPlayer3D
var _wind: AudioStreamPlayer
var _step_time := 0.0


func bind(who: Player, vehicle: Train) -> void:
	# Headless validation has no listening surface or audio clock. Avoid creating
	# looping playback instances which the Dummy audio driver cannot drain.
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	player = who
	train = vehicle
	_wind = AudioStreamPlayer.new()
	_wind.stream = _loop(preload("res://assets/audio/wind.wav"))
	_wind.volume_db = -17
	add_child(_wind)
	_wind.play()
	_engine = AudioStreamPlayer3D.new()
	_engine.stream = _loop(preload("res://assets/audio/engine.wav"))
	_engine.unit_size = 5
	_engine.max_distance = 45
	_engine.position = Vector3(1, 1.6, 0)
	train.get_node("Locomotive").add_child(_engine)
	_engine.play()
	_steps = AudioStreamPlayer3D.new()
	_steps.stream = preload("res://assets/audio/step.wav")
	_steps.volume_db = -14
	player.add_child(_steps)


func _exit_tree() -> void:
	for sound in [_wind, _engine, _steps]:
		if is_instance_valid(sound):
			sound.stop()
			sound.stream = null


func _loop(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	return stream


func _process(delta: float) -> void:
	if player == null:
		return
	_engine.volume_db = lerpf(-24, -8, minf(train.speed / 12, 1))
	_engine.pitch_scale = 0.65 + minf(train.speed / 12, 1) * 0.65
	_step_time -= delta
	if player.is_grounded() and player.get_horizontal_speed() > 0.5 and _step_time <= 0:
		_step_time = 0.46 if not player.is_sprinting() else 0.28
		_steps.play()
