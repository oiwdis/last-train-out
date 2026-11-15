class_name CameraSettings
extends Resource
## Locally persisted preferences; never includes gameplay or inventory state.

@export var default_perspective := 1
@export var sensitivity := 0.0025
@export var first_person_fov := 78.0
@export var third_person_distance := 3.2
@export var smoothing := 14.0


func sanitize() -> void:
	default_perspective = clampi(default_perspective, 0, 1)
	sensitivity = clampf(sensitivity, 0.0005, 0.01)
	first_person_fov = clampf(first_person_fov, 60, 105)
	third_person_distance = clampf(third_person_distance, 1.2, 5.0)
	smoothing = clampf(smoothing, 4, 30)


func save_preferences(path: String = "user://camera.cfg") -> Error:
	sanitize()
	var config := ConfigFile.new()
	for key in ["default_perspective", "sensitivity", "first_person_fov", "third_person_distance", "smoothing"]:
		config.set_value("camera", key, get(key))
	return config.save(path)


func load_preferences(path: String = "user://camera.cfg") -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for key in ["default_perspective", "sensitivity", "first_person_fov", "third_person_distance", "smoothing"]:
		set(key, config.get_value("camera", key, get(key)))
	sanitize()
