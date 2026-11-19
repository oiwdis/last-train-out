class_name DiagnosticSceneRetirement
extends Node
## Godot stops audio through the mixer, then retires playbacks on a later main
## thread update. Two fast render frames are not an audio lifetime barrier.
## Keep the diagnostic alive until its actual playback owners have gone away.
signal completed

var _scene: Node
var _playbacks: Array[WeakRef] = []
var _deadline := 0
var _stop_frame := 0
var _released_frame := -1

static func release(scene: Node) -> Signal:
	var job := DiagnosticSceneRetirement.new()
	job.name = "DiagnosticSceneRetirement"
	job.process_mode = Node.PROCESS_MODE_ALWAYS
	job._scene = scene
	job._deadline = Time.get_ticks_msec()+2000
	job._stop_frame = Engine.get_process_frames()
	scene.get_tree().root.add_child(job)
	# No simulation or audio event can restart a voice while it is retiring.
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	job._stop_audio(scene)
	return job.completed

func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.has_stream_playback():
			_playbacks.append(weakref(node.get_stream_playback()))
		node.stop()
		node.stream = null
		if node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
			# Godot 4.5.1 keeps a separate pending setplayback Ref until the
			# first physics update or node destruction. stop() clears the
			# server-facing list but not that Ref. A scene paused for shader
			# preparation may never have started its spatial audio at all.
			# Destroy that owner before waiting for actual mixer retirement.
			node.queue_free()
	for child in node.get_children(true):
		_stop_audio(child)

func _process(_delta: float) -> void:
	if _released_frame < 0:
		_playbacks = _playbacks.filter(func(ref: WeakRef) -> bool: return ref.get_ref() != null)
		if not _playbacks.is_empty():
			# A blocked render submission can consume the wall deadline before
			# AudioServer has run its main-thread retirement updates. Require
			# update opportunities as well as elapsed time; a retained owner still
			# fails after both limits. The outer diagnostic has a process timeout.
			if Time.get_ticks_msec() < _deadline or Engine.get_process_frames()-_stop_frame < 3: return
			# A timeout remains a failed diagnostic, never a suppressed warning.
			push_error("Audio playback retirement timed out: %d owners remain" % _playbacks.size())
		_scene.queue_free()
		_released_frame = Engine.get_process_frames()
	elif Engine.get_process_frames()-_released_frame >= 3:
		set_process(false)
		completed.emit()
		queue_free()
