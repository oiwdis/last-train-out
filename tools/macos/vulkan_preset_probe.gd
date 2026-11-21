extends "res://scripts/diagnostics/preparation_stress.gd"
## Observe the real fog proxy immediately before its first draw. Both arms run
## build 117's packaged preset, fog, Save/Continue and restart sequence.
var startup_only := false
var preparation_number := 0
var journal: FileAccess

func _initialize() -> void:
	super._initialize()
	startup_only = "--startup-camera-only" in OS.get_cmdline_user_args()
	journal = FileAccess.open(destination + ".cameras.jsonl", FileAccess.WRITE)
	node_added.connect(_observe_camera)

func _observe_camera(node: Node) -> void:
	if node is RenderWarmup and node.get_parent() is Game:
		preparation_number += 1
	if not node is MeshInstance3D or not node.get_parent() is Camera3D:
		return
	var camera := node.get_parent() as Camera3D
	var job := camera.get_parent() as RenderWarmup
	if job == null:
		return
	var scene := job.get_parent() as Game
	var preset := scene.graphics.current_index
	var before := camera.transform
	if startup_only and preparation_number > 1 and preset == 2:
		camera.transform = Transform3D.IDENTITY
	journal.store_line(JSON.stringify({
		"preparation": preparation_number, "preset": preset,
		"origin_before": before.is_equal_approx(Transform3D.IDENTITY),
		"origin_after": camera.transform.is_equal_approx(Transform3D.IDENTITY),
		"user_dir": OS.get_user_data_dir()
	}))
	journal.flush()
