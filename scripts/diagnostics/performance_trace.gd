class_name PerformanceTrace
extends RefCounted
## Opt-in phase evidence. No asset loading and no per-frame work in normal play.
static var enabled := "--profile-phases" in OS.get_cmdline_user_args()
static var events: Array[Dictionary] = []

static func mark(phase: String, began_usec: int = 0) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_usec()
	var row := {"phase":phase,"ticks_ms":now/1000.0,"duration_ms":(now-began_usec)/1000.0 if began_usec > 0 else 0.0,
		"static_bytes":OS.get_static_memory_usage(),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"pipeline_mesh":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH),"pipeline_draw":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW),
		"pipeline_specialization":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)}
	events.append(row)
	print("[phase] ",JSON.stringify(row))
