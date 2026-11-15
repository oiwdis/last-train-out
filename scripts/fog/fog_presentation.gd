class_name FogPresentation
extends Node3D
## Render-only observer. A handful of front sheets plus ordinary distance fog;
## no extra volumetric pass or screen blur, including on High.
var system: FogSystem
var player_id := ""
var layers: Array[MeshInstance3D] = []
var environment: Environment
var base_density := 0.004
var base_light := Color.WHITE
var audio: FogAudio
var _blend := 0.0

func bind(authority: FogSystem, id: String) -> void:
	system = authority
	player_id = id
	environment = system.game.station.get_node("Atmosphere").get_environment()
	base_density = environment.fog_density
	base_light = environment.fog_light_color
	for i in 6:
		var mesh := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(180, 36)
		mesh.mesh = quad
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/fog/fog_front.gdshader")
		material.set_shader_parameter("phase", float(i) * 1.73)
		mesh.material_override = material
		add_child(mesh)
		layers.append(mesh)
	system.game.graphics.changed.connect(_quality)
	_quality(system.game.graphics.current_index)
	audio = FogAudio.new()
	add_child(audio)
	audio.bind(system, player_id)

func _quality(index: int) -> void:
	for i in layers.size():
		layers[i].visible = i < [2, 4, 6][index]
		(layers[i].material_override as ShaderMaterial).set_shader_parameter("detail", 0.0 if index == 0 else 1.0)

func _process(delta: float) -> void:
	if not system.players.has(player_id):
		return
	var sim := system.simulation
	var dose := system.players[player_id].exposure as FogExposure
	var gap := dose.progress - sim.front
	# Visibility is local to the observer, never global while the front is distant.
	var target := clampf(1 - gap / 65.0, 0, 1)
	if sim.event == "dense" and gap < system.config.approach_distance:
		target = maxf(target, 0.55)
	_blend = move_toward(_blend, target, delta * 0.6)
	environment.fog_enabled = true
	environment.fog_density = lerpf(base_density, system.config.visibility_density, _blend)
	environment.fog_light_color = base_light.lerp(Color(0.22, 0.27, 0.30), _blend)
	for i in layers.size():
		var progress := sim.front - i * 5.0
		layers[i].global_position = system.route.sample(progress) + Vector3.UP * 14
		var axis := system.route.tangent(progress)
		if axis.length_squared() > 0.1:
			layers[i].look_at(layers[i].global_position + axis, Vector3.UP)
