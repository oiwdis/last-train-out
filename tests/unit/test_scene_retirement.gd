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

func test_spawned_fixture_cleanup_retires_audio_owners_before_returning() -> void:
	var scene := Node.new()
	add_child(scene)
	_spawned.append(scene)
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
	await free_spawned()
	for playback in playbacks:
		check(playback.get_ref() == null,"fixture teardown cannot leave mixer-owned playback at test runner exit")

func test_retirement_deadline_requires_main_thread_update_opportunities() -> void:
	var scene := Node.new()
	add_child(scene)
	var voice := AudioStreamPlayer.new()
	voice.stream = load("res://assets/audio/fog/wind.wav").duplicate()
	scene.add_child(voice)
	voice.play()
	var completion := DiagnosticSceneRetirement.release(scene)
	var job := completion.get_object() as DiagnosticSceneRetirement
	# A long first shader-preparation draw can consume the wall deadline before
	# AudioServer gets another main-thread update. Model that boundary without
	# adding a multi-second sleep to every test-suite run.
	job.set("_deadline",0)
	job._process(0)
	check(not scene.is_queued_for_deletion(),"elapsed wall time alone cannot bypass audio retirement before main-thread updates")
	job.set("_deadline",Time.get_ticks_msec()+2000)
	await completion

func test_spatial_audio_stopped_before_first_physics_tick_releases_pending_owner() -> void:
	var scene := Node3D.new()
	add_child(scene)
	var voice := AudioStreamPlayer3D.new()
	voice.stream = load("res://assets/audio/engine.wav").duplicate()
	scene.add_child(voice)
	voice.play()
	var playback: WeakRef = weakref(voice.get_stream_playback())
	# No physics tick has happened. AudioStreamPlayer3D::setplayback still
	# owns this voice even after stop(); retirement must destroy that owner.
	await DiagnosticSceneRetirement.release(scene)
	check(playback.get_ref() == null,"pending spatial playback cannot outlive diagnostic retirement")
