extends Control
## Used by an explicit macOS renderer launch. Keep this script free of game
## class types and preloads so the loading UI can draw before the mission loads.
const MISSION := "res://scenes/missions/harlow_escape.tscn"

enum Stage { FIRST_FRAME, REQUEST, LOADING, ACTIVATE }
var stage := Stage.FIRST_FRAME
var mission: PackedScene
var started := 0
var status_history: Array = []
var last_frame := 0
var worst_gap_ms := 0.0

func _ready() -> void:
	$Center/Status.text = "Loading Harlow Junction…"
	started = Time.get_ticks_usec()
	last_frame = started

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	worst_gap_ms = maxf(worst_gap_ms, (now - last_frame) / 1000.0)
	last_frame = now
	if stage == Stage.FIRST_FRAME:
		stage = Stage.REQUEST
		return
	if stage == Stage.REQUEST:
		var err := ResourceLoader.load_threaded_request(MISSION, "PackedScene")
		if err != OK:
			_failed(error_string(err))
			return
		stage = Stage.LOADING
		return
	if stage == Stage.ACTIVATE:
		set_process(false)
		var err := get_tree().change_scene_to_packed(mission)
		if err != OK: _failed(error_string(err))
		return
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(MISSION, progress)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_failed("The mission resource request is unavailable.")
		return
	if not progress.is_empty():
		var percent := roundi(float(progress[0]) * 100)
		$Center/Progress.value = percent
		if status_history.is_empty() or status_history.back()[0] != percent:
			status_history.append([percent, Time.get_ticks_msec()])
	if status == ResourceLoader.THREAD_LOAD_FAILED:
		_failed("The mission resources could not be loaded.")
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		mission = ResourceLoader.load_threaded_get(MISSION) as PackedScene
		if mission == null:
			_failed("The mission scene is missing.")
			return
		RendererIdentity.load_progress = {"resource_ms": (Time.get_ticks_usec() - started) / 1000.0,
			"worst_loading_frame_ms":worst_gap_ms,"progress":status_history}
		$Center/Status.text = "Preparing the station…"
		stage = Stage.ACTIVATE

func _failed(reason: String) -> void:
	set_process(false)
	$Center/Status.text = reason
	push_error(reason)
