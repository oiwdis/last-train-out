extends TestSuite
## Static project checks: every resource loads, every scene instantiates, and
## the project settings the game relies on are present.

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_in", &"move_out", &"sprint", &"jump", &"interact",
	&"debug_toggle", &"debug_close",
]
const SKIP_DIRECTORIES: Array[String] = ["res://.godot", "res://.git", "res://tests/_output"]


func _collect(directory: String, extensions: Array[String], into: Array[String]) -> void:
	if directory in SKIP_DIRECTORIES:
		return
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	for file in dir.get_files():
		if file.get_extension() in extensions:
			into.append(directory.path_join(file))
	for sub in dir.get_directories():
		if not sub.begins_with("."):
			_collect(directory.path_join(sub), extensions, into)


func test_all_scripts_compile() -> void:
	var scripts: Array[String] = []
	_collect("res://", ["gd"], scripts)
	check_greater(float(scripts.size()), 25.0, "found the project's scripts")
	for path in scripts:
		var script := load(path) as GDScript
		check(script != null and script.can_instantiate(), "script compiles: %s" % path)
	note("%d scripts compiled" % scripts.size())


func test_all_resources_load() -> void:
	var resources: Array[String] = []
	_collect("res://", ["tres"], resources)
	check_greater(float(resources.size()), 30.0, "found the project's resources")
	for path in resources:
		check(load(path) != null, "resource loads: %s" % path)
	note("%d resources loaded" % resources.size())


func test_all_scenes_instantiate() -> void:
	var scenes: Array[String] = []
	_collect("res://", ["tscn"], scenes)
	check_greater(float(scenes.size()), 12.0, "found the project's scenes")
	for path in scenes:
		var packed := load(path) as PackedScene
		if not check(packed != null, "scene loads: %s" % path):
			continue
		var instance := packed.instantiate()
		check(instance != null, "scene instantiates: %s" % path)
		if instance != null:
			instance.free()
	note("%d scenes instantiated" % scenes.size())


func test_main_scene_is_configured() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	check_eq(main_scene, "res://scenes/missions/harlow_escape.tscn", "main scene is the three-station mission")
	check(ResourceLoader.exists(main_scene), "main scene file exists")


func test_input_map_has_all_actions() -> void:
	for action in REQUIRED_ACTIONS:
		check(InputMap.has_action(action), "input action exists: %s" % action)
		if InputMap.has_action(action):
			check(not InputMap.action_get_events(action).is_empty(), "input action has a key bound: %s" % action)


func test_physics_layers_are_named() -> void:
	var expected := {1: "world", 2: "player", 3: "train", 4: "interactable", 5: "trigger"}
	for layer: int in expected:
		check_eq(ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % layer, ""), expected[layer],
			"physics layer %d is named" % layer)


func test_player_and_train_use_the_documented_collision_layers() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as CharacterBody3D
	check_eq(player.collision_layer, 2, "player is on the player layer")
	check_eq(player.collision_mask, 5, "player collides with world and train")
	player.free()
	var car := (load("res://scenes/train/flat_car.tscn") as PackedScene).instantiate() as AnimatableBody3D
	check_eq(car.collision_layer, 4, "train cars are on the train layer")
	check(car.sync_to_physics, "train cars sync to physics so riders inherit their velocity")
	car.free()
