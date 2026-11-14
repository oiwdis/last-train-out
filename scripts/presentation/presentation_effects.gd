class_name PresentationEffects
extends Node3D
## Observes gameplay signals. Only visual children are animated; no body or camera shake.

var _player: Player
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _phase := 0.0
var _impact := 0.0
var _dust: CPUParticles3D
var _motes: CPUParticles3D


func bind(player: Player) -> void:
	_player = player
	if _player == null:
		return
	var visual := _player.visual
	visual.get_node("Legs").hide()
	var d := DetailBuilder.new(visual, "ClothingDetails")
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.12, 0.78, 0)
		visual.add_child(leg)
		_legs.append(leg)
		var ld := DetailBuilder.new(leg)
		ld.box(Vector3(0, -0.35, 0), Vector3(0.16, 0.7, 0.24), Color("253540"))
		ld.box(Vector3(0, -0.72, 0.06), Vector3(0.18, 0.12, 0.34), DetailBuilder.INK)
		ld.finish()
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.31, 1.34, 0)
		visual.add_child(arm)
		_arms.append(arm)
		var ad := DetailBuilder.new(arm)
		ad.box(Vector3(0, -0.23, 0), Vector3(0.14, 0.46, 0.19), Color("4a6269"))
		ad.box(Vector3(0, -0.48, 0), Vector3(0.13, 0.13, 0.17), DetailBuilder.INK)
		ad.finish()
	d.box(Vector3(0, 1.05, 0.165), Vector3(0.04, 0.5, 0.02), DetailBuilder.INK)
	d.box(Vector3(0, 0.88, 0), Vector3(0.53, 0.07, 0.32), DetailBuilder.INK)
	d.box(Vector3(0.16, 1.25, 0.17), Vector3(0.1, 0.05, 0.02), DetailBuilder.AMBER)
	d.finish()
	_dust = particles(_player, Vector3(0, 0.08, 0), 10, Color(0.65, 0.7, 0.69, 0.28), 0.08, 0.4)
	_dust.one_shot = true
	_dust.explosiveness = 1.0
	_dust.spread = 80
	_dust.initial_velocity_min = 0.25
	_dust.initial_velocity_max = 0.7
	_dust.gravity = Vector3(0, -0.5, 0)
	_player.jumped.connect(_on_jump)
	_player.landed.connect(_on_land)
	_player.vault_started.connect(_on_vault)
	_motes = particles(self, Vector3.ZERO, 42, Color(0.7, 0.8, 0.82, 0.3), 0.014, 7)
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_motes.emission_box_extents = Vector3(13, 4, 4)
	_motes.direction = Vector3(1, 0.1, 0)
	_motes.gravity = Vector3.ZERO
	_motes.initial_velocity_min = 0.06
	_motes.initial_velocity_max = 0.16
	_motes.emitting = true


static func particles(parent: Node3D, at: Vector3, count: int, tint: Color, size: float, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = count
	p.lifetime = life
	p.local_coords = false
	p.position = at
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shape := SphereMesh.new()
	shape.radius = size
	shape.height = size * 2
	shape.radial_segments = 6
	shape.rings = 3
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shape.material = mat
	p.mesh = shape
	var gradient := Gradient.new()
	gradient.set_color(0, Color(tint, 0.0))
	gradient.set_color(1, Color(tint, 0.0))
	gradient.add_point(0.15, tint)
	p.color_ramp = gradient
	parent.add_child(p)
	return p


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var state := _player.state
	var speed := _player.get_horizontal_speed()
	_phase += delta * (8.0 if state == Player.State.CLIMB else speed * 2.6)
	_impact = move_toward(_impact, 0.0, delta * 1.8)
	var moving := state == Player.State.WALK or state == Player.State.SPRINT
	var climbing := state == Player.State.CLIMB
	for i in 2:
		var swing := sin(_phase + i * PI) * (0.65 if state == Player.State.SPRINT else 0.4) if moving or climbing else 0.0
		_legs[i].rotation.x = lerpf(_legs[i].rotation.x, swing, 1.0 - exp(-18 * delta))
		var reach := -2.4 + swing if climbing else -swing
		if state == Player.State.HANG or state == Player.State.MOUNT:
			reach = -2.6
		elif state == Player.State.VAULT:
			reach = -1.2
		if _player.carrying_heavy:
			reach = -1.3
		_arms[i].rotation.x = lerpf(_arms[i].rotation.x, reach, 1.0 - exp(-15 * delta))
	_player.visual.position.y = -_impact * 0.1 + (absf(sin(_phase)) * 0.025 if moving else 0.0)
	_motes.global_position = _player.global_position + Vector3(0, 2, -1)


func _on_jump() -> void:
	_dust.restart()


func _on_land() -> void:
	_impact = 1.0
	_dust.restart()


func _on_vault(_kind: String) -> void:
	_impact = 0.5
	_dust.restart()
