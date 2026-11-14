extends Node
## Lightweight Godot-native test runner.
##
## Run headless from the project directory:
##   godot --headless --path . --fixed-fps 60 tests/test_runner.tscn
## Optional arguments after "--":
##   --only=<text>     run only suites whose file name contains <text>
##   --report=<path>   also write a JSON summary to <path>
## Exit code is 0 when every test passes, 1 otherwise.

const SUITE_DIRECTORIES: Array[String] = ["res://tests/unit", "res://tests/integration"]

var _only := ""
var _report_path := ""
var _watcher := TestErrorWatcher.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			_only = argument.trim_prefix("--only=")
		elif argument.begins_with("--report="):
			_report_path = argument.trim_prefix("--report=")
	OS.add_logger(_watcher)
	_run.call_deferred()


func _run() -> void:
	var started := Time.get_ticks_msec()
	var results: Array[Dictionary] = []
	var passed := 0
	var failed := 0
	print("\n=== Last Train Out - automated tests (Godot %s, physics: %s) ===" % [
		Engine.get_version_info()["string"],
		ProjectSettings.get_setting("physics/3d/physics_engine", "DEFAULT"),
	])
	for path in _find_suites():
		var script := load(path) as GDScript
		if script == null:
			failed += 1
			print("\n[SUITE] %s\n  FAIL  could not load script" % path)
			results.append({"suite": path, "test": "<load>", "passed": false, "failures": ["could not load"], "notes": []})
			continue
		var suite := script.new() as TestSuite
		if suite == null:
			continue
		suite.name = path.get_file().get_basename()
		add_child(suite)
		print("\n[SUITE] %s" % path.get_file())
		for method in _test_methods(script):
			suite.failures.clear()
			suite.notes.clear()
			suite.check_count = 0
			_watcher.take_errors()
			await suite.before_each()
			await suite.call(method)
			await suite.after_each()
			# A runtime error aborts the GDScript function it happens in, so a
			# test that errored (or asserted nothing) must never count as passed.
			for error in _watcher.take_errors():
				suite.failures.append("engine error during test: %s" % error)
			if suite.check_count == 0:
				suite.failures.append("test finished without running a single check")
			var ok := suite.failures.is_empty()
			if ok:
				passed += 1
			else:
				failed += 1
			print("  %s  %s" % ["PASS" if ok else "FAIL", method])
			for line in suite.notes:
				print("          . %s" % line)
			for line in suite.failures:
				print("          ! %s" % line)
			results.append({
				"suite": path.get_file(),
				"test": method,
				"passed": ok,
				"failures": suite.failures.duplicate(),
				"notes": suite.notes.duplicate(),
			})
		suite.queue_free()
		await get_tree().process_frame
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	print("\n=== %d passed, %d failed, %d total (%.1f s wall clock) ===\n" % [passed, failed, passed + failed, elapsed])
	if _report_path != "":
		var file := FileAccess.open(_report_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({
				"godot": Engine.get_version_info()["string"],
				"physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine", "DEFAULT"),
				"passed": passed,
				"failed": failed,
				"results": results,
			}, "  "))
	get_tree().quit(0 if failed == 0 and passed > 0 else 1)


func _find_suites() -> Array[String]:
	var found: Array[String] = []
	for directory in SUITE_DIRECTORIES:
		var dir := DirAccess.open(directory)
		if dir == null:
			continue
		var files := dir.get_files()
		files.sort()
		for file in files:
			if file.begins_with("test_") and file.ends_with(".gd"):
				if _only == "" or file.contains(_only):
					found.append(directory.path_join(file))
	return found


func _test_methods(script: GDScript) -> Array[String]:
	var methods: Array[String] = []
	for method in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_") and not methods.has(method_name):
			methods.append(method_name)
	return methods
