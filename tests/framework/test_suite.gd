class_name TestSuite
extends Node
## Base class for a group of automated tests.
##
## Every method whose name starts with "test_" is run in declaration order by
## the test runner. Tests may be coroutines (use `await`). Assertions never
## abort a test; they record a failure and execution continues.

var failures: Array[String] = []
var check_count := 0
var notes: Array[String] = []

var _spawned: Array[Node] = []


## Called before every test. May be a coroutine.
func before_each() -> void:
	pass


## Called after every test. May be a coroutine.
func after_each() -> void:
	pass


# --- Assertions --------------------------------------------------------------

func check(condition: bool, message: String) -> bool:
	check_count += 1
	if not condition:
		failures.append(message)
	return condition


func check_near(actual: float, expected: float, tolerance: float, message: String) -> bool:
	return check(
		absf(actual - expected) <= tolerance,
		"%s (expected %.4f +/- %.4f, got %.4f)" % [message, expected, tolerance, actual]
	)


func check_eq(actual: Variant, expected: Variant, message: String) -> bool:
	return check(actual == expected, "%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func check_less(actual: float, limit: float, message: String) -> bool:
	return check(actual < limit, "%s (expected < %.4f, got %.4f)" % [message, limit, actual])


func check_greater(actual: float, limit: float, message: String) -> bool:
	return check(actual > limit, "%s (expected > %.4f, got %.4f)" % [message, limit, actual])


## Records a measurement that is printed with the test result.
func note(text: String) -> void:
	notes.append(text)


# --- Helpers -----------------------------------------------------------------

func physics_frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame


## Waits until the end of a rendered frame, i.e. after all physics ticks of the
## frame ran. Positions sampled here are what the player actually sees.
func render_frame() -> void:
	await get_tree().process_frame


func seconds(duration: float) -> void:
	await physics_frames(maxi(roundi(duration * Engine.physics_ticks_per_second), 1))


func tick_delta() -> float:
	return 1.0 / Engine.physics_ticks_per_second


## Instantiates a scene under this suite and waits for it to settle.
func spawn_scene(path: String, settle_frames: int = 3) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		check(false, "Could not load scene %s" % path)
		return null
	var instance := packed.instantiate()
	add_child(instance)
	_spawned.append(instance)
	await physics_frames(settle_frames)
	return instance


## Frees everything created with spawn_scene().
func free_spawned() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			# Native fixed-step tests can end before the audio mixer relinquishes
			# stopped WAV playbacks. Retire real owners, not just scene nodes.
			await DiagnosticSceneRetirement.release(node)
	_spawned.clear()
	await physics_frames(2)
