class_name PresentationEffects
extends Node3D
## Observes gameplay signals. Only visual children are animated; no body or camera shake.

var _player: Player
var _dust: CPUParticles3D
var _motes: CPUParticles3D


func bind(player: Player) -> void:
	_player = player
	if _player == null:
		return
	var visual := _player.visual
	for child in visual.get_children():
		if child is GeometryInstance3D:
			child.hide()
	var worker := WorkerAnimator.new()
	worker.name = "RailWorker"
	visual.add_child(worker)
	worker.bind(player)
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
	_motes.global_position = _player.global_position + Vector3(0, 2, -1)


func _on_jump() -> void:
	_dust.restart()


func _on_land() -> void:
	_dust.restart()


func _on_vault(_kind: String) -> void:
	_dust.restart()
