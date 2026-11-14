class_name GraphicsSettings
extends Node
## Render-only quality choices. Never changes collisions, physics ticks or movement.

signal changed(index: int)

const PRESETS: Array[GraphicsPreset] = [preload("res://resources/graphics/low.tres"),
	preload("res://resources/graphics/medium.tres"), preload("res://resources/graphics/high.tres")]
const SETTINGS_PATH := "user://graphics.cfg"

var current_index := 1
var _scene_root: Node3D
var _atmosphere: Atmosphere
var _lights: Array[Dictionary] = []
var _particles: Array[Dictionary] = []
var _ready_to_apply := false


func bind(scene_root: Node3D, atmosphere: Atmosphere = null) -> void:
	_scene_root = scene_root
	_atmosphere = atmosphere
	if _atmosphere != null:
		var world := _atmosphere.get_node("WorldEnvironment") as WorldEnvironment
		world.environment = world.environment.duplicate()
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		current_index = clampi(int(config.get_value("graphics", "preset", 1)), 0, 2)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--graphics="):
			var index := ["low", "medium", "high"].find(argument.trim_prefix("--graphics="))
			if index >= 0:
				current_index = index
	get_viewport().size_changed.connect(_apply_resolution)
	_finish_bind.call_deferred()


func _finish_bind() -> void:
	_collect(_scene_root)
	_ready_to_apply = true
	set_preset(current_index)


func _collect(node: Node) -> void:
	if node is Light3D:
		_lights.append({"light": node, "shadow": node.shadow_enabled})
	if node is CPUParticles3D:
		_particles.append({"particles": node, "amount": node.amount})
	for child in node.get_children(true):
		_collect(child)


func set_preset(index: int, persist: bool = false) -> void:
	current_index = clampi(index, 0, PRESETS.size() - 1)
	if not _ready_to_apply:
		return
	var preset := PRESETS[current_index]
	if _atmosphere != null:
		var environment := _atmosphere.get_environment()
		environment.volumetric_fog_enabled = preset.volumetric_fog and _atmosphere.use_volumetric_fog and _atmosphere._volumetric_fog_is_supported()
		environment.glow_enabled = preset.glow
	for entry in _lights:
		var light := entry.light as Light3D
		if light is DirectionalLight3D:
			light.shadow_enabled = bool(entry.shadow) and preset.directional_shadows
			(light as DirectionalLight3D).directional_shadow_max_distance = preset.shadow_distance
		else:
			light.shadow_enabled = bool(entry.shadow) and preset.local_shadows
			light.distance_fade_enabled = current_index < 2
			light.distance_fade_begin = preset.light_fade_distance
			light.distance_fade_shadow = preset.light_fade_distance * 0.75
			light.distance_fade_length = 10
	for entry in _particles:
		var particles := entry.particles as CPUParticles3D
		particles.amount = maxi(4, roundi(int(entry.amount) * preset.particle_fraction))
	get_viewport().msaa_3d = preset.msaa as Viewport.MSAA
	get_viewport().positional_shadow_atlas_size = preset.shadow_atlas_size
	RenderingServer.directional_shadow_atlas_set_size(preset.shadow_atlas_size * 2, true)
	_apply_resolution()
	if persist:
		var config := ConfigFile.new()
		config.set_value("graphics", "preset", current_index)
		config.save(SETTINGS_PATH)
	changed.emit(current_index)


func _apply_resolution() -> void:
	var preset := PRESETS[current_index]
	var scale := preset.render_scale
	if preset.maximum_3d_height > 0:
		# The visible rect is in stretched UI coordinates (often 1280×720).
		# Use window pixels so full-screen/Retina rendering actually respects the budget.
		scale = minf(scale, float(preset.maximum_3d_height) / maxf(get_viewport().get_window().size.y, 1))
	get_viewport().scaling_3d_scale = clampf(scale, 0.25, 1.0)


func cycle() -> void:
	set_preset((current_index + 1) % PRESETS.size(), true)
