class_name FrameTimeline
extends Node
## Main-thread callback brackets, not an invented GPU timer. The driver may wait
## outside frame_pre_draw/post_draw; retain that unaccounted interval explicitly.
class EndProbe:
	extends Node
	var timeline: Node
	func _process(_delta: float) -> void:
		timeline.process_end = Time.get_ticks_usec()
	func _physics_process(_delta: float) -> void:
		timeline.physics_usec += Time.get_ticks_usec()-timeline.physics_begin

var process_begin := 0
var process_end := 0
var physics_begin := 0
var physics_usec := 0
var draw_begin := 0
var previous_draw := 0
var latest: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1000000
	process_physics_priority = -1000000
	var end := EndProbe.new()
	end.timeline = self
	end.process_priority = 1000000
	end.process_physics_priority = 1000000
	add_child(end)
	RenderingServer.frame_pre_draw.connect(_pre_draw)
	RenderingServer.frame_post_draw.connect(_post_draw)

func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(_pre_draw)
	RenderingServer.frame_post_draw.disconnect(_post_draw)

func _process(_delta: float) -> void:
	process_begin = Time.get_ticks_usec()

func _physics_process(_delta: float) -> void:
	physics_begin = Time.get_ticks_usec()

func _pre_draw() -> void:
	draw_begin = Time.get_ticks_usec()

func _post_draw() -> void:
	var now := Time.get_ticks_usec()
	latest = {"frame":Engine.get_process_frames(),"ticks_ms":now/1000.0,
		"frame_ms":(now-previous_draw)/1000.0 if previous_draw > 0 else 0.0,
		"process_bracket_ms":maxi(0,process_end-process_begin)/1000.0,
		"physics_bracket_ms":physics_usec/1000.0,"render_bracket_ms":(now-draw_begin)/1000.0,
		"render_setup_cpu_ms":RenderingServer.get_frame_setup_time_cpu()}
	physics_usec = 0
	previous_draw = now
