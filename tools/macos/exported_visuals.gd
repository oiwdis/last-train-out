extends SceneTree
## Mount only the two authored capture scripts. Keep shipped resources authoritative.
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--visual-inputs=") and ProjectSettings.load_resource_pack(arg.trim_prefix("--visual-inputs="), false):
			start.call_deferred()
			return
	push_error("Missing art capture inputs.")
	quit(1)

func start() -> void:
	var script := load("res://tools/capture_finalization.gd") as Script
	root.add_child(script.new())
