class_name FogAudio
extends Node
## Original synthesized layers. No random draws touch gameplay RNG.
var system: FogSystem
var player_id := ""
var voices: Array[AudioStreamPlayer] = []
var cue: AudioStreamPlayer
var _world_bus := ""
var _filter: AudioEffectLowPassFilter
var _routed: Array[Dictionary] = []

func bind(authority: FogSystem, id: String) -> void:
	system = authority
	player_id = id
	if DisplayServer.get_name() == "headless":
		return
	_world_bus = "FogWorld_%d" % get_instance_id()
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, _world_bus)
	_filter = AudioEffectLowPassFilter.new()
	_filter.cutoff_hz = 20000
	AudioServer.add_bus_effect(bus, _filter)
	for node in system.game.find_children("*", "", true, false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
			_routed.append({"node": node, "bus": node.bus})
			node.bus = _world_bus
	for path in ["rumble", "wind", "breath"]:
		var voice := AudioStreamPlayer.new()
		var stream := load("res://assets/audio/fog/%s.wav" % path).duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		voice.stream = stream
		voice.volume_db = -60
		add_child(voice)
		voice.play()
		voices.append(voice)
	cue = AudioStreamPlayer.new()
	cue.stream = preload("res://assets/audio/fog/metal.wav")
	cue.volume_db = -20
	add_child(cue)
	system.simulation.event_announced.connect(func(_kind: String) -> void: cue.play())
	system.fog_state_changed.connect(func(state: FogSystem.FogState) -> void:
		if state == FogSystem.FogState.CRITICAL:
			cue.play())

func _process(delta: float) -> void:
	if voices.is_empty() or not system.players.has(player_id):
		return
	var dose := system.players[player_id].exposure as FogExposure
	var gap := dose.progress - system.simulation.front
	var urgency := clampf(1 - gap / system.config.approach_distance, 0, 1)
	_filter.cutoff_hz = lerpf(_filter.cutoff_hz, lerpf(20000, 1300, urgency), minf(1, delta * 2))
	var gain := system.config.audio_intensity
	var levels := [gain * (0.08 + urgency * 0.28), gain * (0.02 + urgency * 0.22), gain * dose.exposure / 100 * 0.3]
	for i in voices.size():
		var target := linear_to_db(maxf(0.001, levels[i]))
		voices[i].volume_db = move_toward(voices[i].volume_db, target, delta * 12)

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	if is_instance_valid(cue):
		cue.stop()
	for entry in _routed:
		if is_instance_valid(entry.node):
			entry.node.bus = entry.bus
	var bus := AudioServer.get_bus_index(_world_bus)
	if bus > 0:
		AudioServer.remove_bus(bus)
