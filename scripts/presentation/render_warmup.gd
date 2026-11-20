class_name RenderWarmup
extends Node
## A scene-owned preparation job. No static coroutine survives scene removal.
## Real draws prepare destination-GPU pipelines while gameplay stays paused.
signal completed

var _scene: Node3D
var _tree: SceneTree
var _original: Camera3D
var _previous_focus: Control
var _camera: Camera3D
var _cover: CanvasLayer
var _label: Label
var _proxy: MeshInstance3D
var _views: Array[Node3D] = []
var _sources: Array[MeshInstance3D] = []
var _source_index := 0
var _view_index := -1
var _view_frames := 0
var _view_started := 0
var _source_started := 0
var _source_frames := 0
var _frames_required := 2
var _drain_frames := 0
var _drain_started := 0
var _started := 0
var _was_paused := false
var _active := false
var _draining := false
var _frame_signal: Signal


static func prepare(scene: Node3D) -> Signal:
	var job := RenderWarmup.new()
	job.name = "RenderPreparation"
	job.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.add_child(job)
	job._begin(scene)
	return job.completed


func _begin(scene: Node3D) -> void:
	_scene = scene
	_tree = scene.get_tree()
	var viewport := scene.get_viewport()
	_original = viewport.get_camera_3d()
	_previous_focus = viewport.gui_get_focus_owner()
	for node in _tree.get_nodes_in_group("render_warmup_view"):
		if node is Node3D and scene.is_ancestor_of(node): _views.append(node)
	if _original == null or viewport.disable_3d or _views.is_empty():
		_finish.call_deferred()
		return
	for node in _tree.get_nodes_in_group("render_warmup_material"):
		if node is MeshInstance3D and scene.is_ancestor_of(node): _sources.append(node)
	PerformanceTrace.mark("warmup_begin")
	_started = Time.get_ticks_msec()
	var device := RenderingServer.get_rendering_device()
	if device != null:
		# frame_post_draw means submitted, not GPU-complete. Render through a
		# whole queue rotation before leaving each view or releasing gameplay.
		_frames_required = device.get_frame_delay()+1
	_was_paused = _tree.paused
	_active = true
	_tree.paused = true
	_cover = CanvasLayer.new()
	_cover.layer = 128
	add_child(_cover)
	var background := ColorRect.new()
	background.color = Color("101a1e")
	background.focus_mode = Control.FOCUS_ALL
	_cover.add_child(background)
	background.grab_focus()
	background.gui_input.connect(func(_event: InputEvent) -> void: background.accept_event())
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size",20)
	background.add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_camera = Camera3D.new()
	_camera.fov = 78
	_camera.near = _original.near
	_camera.far = _original.far
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# Keep the initial surrounding geometry in this pass. Isolating the fog
	# quad concentrated the next view's pipeline work into one burst and
	# reproduced device loss on two independent native runners (3.5.2).
	_camera.cull_mask = _original.cull_mask
	add_child(_camera)
	# Metal used to draw the surrounding world from the origin for the fog
	# material, then compile another visible set at the platform. Start both
	# there. Still submit the uncovered platform, every interior and the final
	# gameplay camera through the full queue before releasing simulation.
	if RenderingServer.get_current_rendering_driver_name() == "metal" and OS.get_environment("LTO_METAL_WARMUP_CONTROL") != "1":
		_camera.global_transform = _views[0].global_transform
	_camera.make_current()
	_frame_signal = _tree.process_frame if DisplayServer.get_name() == "headless" else RenderingServer.frame_post_draw
	_frame_signal.connect(_on_frame)
	_show_next_source()


func _show_next_source() -> void:
	if _source_index >= _sources.size():
		_show_next_view()
		return
	_proxy = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(4,4)
	quad.material = _sources[_source_index].get_active_material(0)
	_proxy.mesh = quad
	_proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_camera.add_child(_proxy)
	_proxy.position = Vector3(0,0,-4)
	_source_frames = _frames_required
	_source_started = Time.get_ticks_usec()
	_progress(_source_index)


func _show_next_view() -> void:
	_view_index += 1
	if _view_index >= _views.size():
		_original.make_current()
		_camera.free()
		_camera = null
		# Consume preparation's last delta while physics is still paused.
		_draining = true
		_drain_frames = _frames_required+1
		_drain_started = Time.get_ticks_usec()
		_progress(_sources.size()+_views.size())
		return
	_camera.global_transform = _views[_view_index].global_transform
	_view_started = Time.get_ticks_usec()
	_view_frames = _frames_required
	_progress(_sources.size()+_view_index)


func _on_frame() -> void:
	if not _active: return
	if _draining:
		_drain_frames -= 1
		if _drain_frames == 0:
			PerformanceTrace.mark("warmup_final_camera",_drain_started)
			_finish()
	elif is_instance_valid(_proxy):
		_source_frames -= 1
		if _source_frames == 0:
			PerformanceTrace.mark("warmup_fog_material",_source_started)
			_proxy.free()
			_proxy = null
			_source_index += 1
			_show_next_source()
	else:
		_view_frames -= 1
		if _view_frames == 0:
			PerformanceTrace.mark("warmup_view_"+String(_views[_view_index].name),_view_started)
			_show_next_view()


func _progress(done: int) -> void:
	_label.text = "Preparing journey… %d / %d" % [done,_sources.size()+_views.size()+1]


func _disconnect_frame() -> void:
	if not _frame_signal.is_null() and _frame_signal.is_connected(_on_frame):
		_frame_signal.disconnect(_on_frame)


func _finish() -> void:
	_disconnect_frame()
	if _active:
		_active = false
		_cover.free()
		if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree():
			_previous_focus.grab_focus()
		_tree.paused = _was_paused
		PerformanceTrace.mark("warmup_end")
		print("[render-warmup] ",_views.size()," views / ",Time.get_ticks_msec()-_started,
			" ms / draw pipelines=",Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW))
	# Remove temporary ownership before notifying callers that play is ready.
	get_parent().remove_child(self)
	completed.emit()
	queue_free()


func _exit_tree() -> void:
	_disconnect_frame()
	if _active:
		_active = false
		_tree.paused = _was_paused
		# Resolve waiting controllers during teardown. An awaiting static
		# GDScriptFunctionState used to outlive its freed GraphicsSettings owner.
		completed.emit()
