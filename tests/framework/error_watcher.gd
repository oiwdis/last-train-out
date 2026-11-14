class_name TestErrorWatcher
extends Logger
## Collects every engine / script error raised while a test runs.
##
## GDScript aborts a function on a runtime error, which would otherwise look
## like a test that simply stopped asserting. The runner fails any test during
## which this watcher saw an error. (Requires Godot 4.5+, which added Logger.)

var _mutex := Mutex.new()
var _errors: Array[String] = []


func _log_error(
	_function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace]
) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var kind := "SCRIPT ERROR" if error_type == ERROR_TYPE_SCRIPT else "ERROR"
	var text := rationale if rationale != "" else code
	_mutex.lock()
	_errors.append("%s: %s (%s:%d)" % [kind, text, file, line])
	_mutex.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass


## Returns the errors seen since the last call and clears the list.
func take_errors() -> Array[String]:
	_mutex.lock()
	var result := _errors.duplicate()
	_errors.clear()
	_mutex.unlock()
	return result
