extends SceneTree
## External test entry point. The ZIP mounts only the two input-driver scripts.
## Every game scene and asset, including the real Continue destination, comes from the exported PCK.

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--journey-inputs="):
			if ProjectSettings.load_resource_pack(arg.trim_prefix("--journey-inputs="), false):
				_start.call_deferred()
				return
	push_error("The exported journey requires its input-driver archive.")
	quit(1)

func _start() -> void:
	var driver := load("res://tools/validate_journey.gd") as Script
	if driver == null or not driver.can_instantiate():
		push_error("Could not instantiate the continuous journey inputs.")
		quit(1)
		return
	root.add_child(driver.new())
