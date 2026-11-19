extends TestSuite

func test_stopped_looping_audio_releases_mixer_owners_before_scene_completion() -> void:
	for attempt in 6:
		var scene := Node.new()
		add_child(scene)
		var playbacks: Array[WeakRef] = []
		for path in ["rumble","wind","breath"]:
			var voice := AudioStreamPlayer.new()
			var stream := load("res://assets/audio/fog/%s.wav" % path).duplicate() as AudioStreamWAV
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = int(stream.get_length()*stream.mix_rate)
			voice.stream = stream
			scene.add_child(voice)
			voice.play()
			playbacks.append(weakref(voice.get_stream_playback()))
		var owner: WeakRef = weakref(scene)
		var was_paused := get_tree().paused
		get_tree().paused = attempt % 2 == 1
		await DiagnosticSceneRetirement.release(scene)
		check_eq(get_tree().paused,attempt % 2 == 1,"retirement preserves the caller's pause state")
		get_tree().paused = was_paused
		check(owner.get_ref() == null,"scene freed before completion")
		for playback in playbacks:
			check(playback.get_ref() == null,"mixer retired stopped playback before completion")
