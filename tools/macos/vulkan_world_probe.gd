extends "res://scripts/diagnostics/startup_probe.gd"
## External fixture for the signed build 111 pack. Every arm runs production High
## preparation, the standard playable-state checks, thirty frames and teardown.
var treatment := ""
var journal: FileAccess
var legacy_shader: Shader

func _initialize() -> void:
	super._initialize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--treatment="):
			treatment = arg.trim_prefix("--treatment=")
		elif arg.begins_with("--legacy-shader="):
			legacy_shader = Shader.new()
			legacy_shader.code = FileAccess.get_file_as_string(arg.trim_prefix("--legacy-shader="))
	journal = FileAccess.open(destination + ".world.jsonl", FileAccess.WRITE)
	node_added.connect(_observe)
	_record("initialized", 0)

func _observe(node: Node) -> void:
	if node.name == &"RenderPreparation" and node.get_parent() is Game:
		var game := node.get_parent() as Game
		var affected := 0
		match treatment:
			"corridor_hidden":
				var corridor := game.get_node("RouteTrack") as Node3D
				corridor.hide()
				affected = corridor.find_children("*", "GeometryInstance3D", true, false).size()
			"legacy_fog":
				var banks := get_nodes_in_group("render_warmup_material")
				for bank: MeshInstance3D in banks:
					if bank.get_parent() is FogPresentation:
						for layer in (bank.get_parent() as FogPresentation).layers:
							(layer.material_override as ShaderMaterial).shader = legacy_shader
							affected += 1
		_record("prepare", affected)
	elif node is Camera3D and node.get_parent() is RenderWarmup and treatment == "platform_start":
		var views := get_nodes_in_group("render_warmup_view")
		if not views.is_empty() and views[0].name == &"Platform":
			(node as Camera3D).global_transform = (views[0] as Node3D).global_transform
			_record("platform_camera", 1)

func _record(phase: String, count: int) -> void:
	journal.store_line(JSON.stringify({"phase": phase, "treatment": treatment, "affected": count,
		"ticks_ms": Time.get_ticks_msec(), "user_dir": OS.get_user_data_dir()}))
	journal.flush()
