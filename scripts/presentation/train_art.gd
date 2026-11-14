class_name TrainArt
extends Node3D
## Visual fittings remain children of the existing moving bodies.

@export_enum("Locomotive", "Crew", "Flat") var kind := 0
var _steam: CPUParticles3D


func _ready() -> void:
	var d := DetailBuilder.new(self, "TrainDetails")
	var ink := DetailBuilder.INK
	var brass := DetailBuilder.AMBER.darkened(0.18)
	var cream := DetailBuilder.PALE
	for x in [-3.3, -2.3, 2.3, 3.3]:
		d.box(Vector3(x, 0.7, 1.12), Vector3(0.7, 0.14, 0.18), ink)
		d.cylinder(Vector3(x, 0.52, 1.0), 0.13, 0.11, brass, Vector3(PI / 2, 0, 0))
	if kind == 0:
		for x in [-0.3, 1.1, 2.6, 3.7]:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.96
			ring.outer_radius = 1.01
			ring.rings = 20
			ring.ring_segments = 6
			d.mesh(ring, Vector3(x, 2.02, 0), brass, Vector3(0, 0, PI / 2))
		d.beam(Vector3(-0.8, 2.6, 0.9), Vector3(3.9, 2.6, 0.9), 0.045, brass)
		d.box(Vector3(1, 1.35, 1.18), Vector3(4.9, 0.15, 0.12), ink)
		d.cylinder(Vector3(3.5, 3.87, 0), 0.38, 0.15, ink)
		d.signboard(Vector3(-2.2, 1.38, 1.34), "L T O   /   07", 2.0, 0.45, cream)
		_frame_window(d, Vector3(-2.3, 2.55, 1.34), Vector2(1.3, 0.75))
		_steam = PresentationEffects.particles(self, Vector3(3.5, 3.98, 0), 22, Color(0.6, 0.67, 0.7, 0.24), 0.32, 2.1)
		_steam.direction = Vector3(-0.4, 1, 0)
		_steam.initial_velocity_min = 0.35
		_steam.initial_velocity_max = 0.8
		_steam.gravity = Vector3(-0.1, 0.2, 0)
		_steam.emitting = true
	elif kind == 1:
		for x in [-2.2, -0.75, 0.75, 2.2]:
			_frame_window(d, Vector3(x, 2.45, 1.34), Vector2(0.9, 0.7))
			# Curtains and a lower sash give the warm windows an inhabited scale.
			d.box(Vector3(x - 0.32, 2.47, 1.36), Vector3(0.15, 0.6, 0.025), Color("ab683e"))
		for x in range(-3, 4):
			d.box(Vector3(x, 1.35, 1.315), Vector3(0.025, 0.55, 0.025), brass)
		d.signboard(Vector3(0.5, 3.13, 1.34), "LAST TRAIN OUT", 3.8, 0.42, cream)
		d.lettering(Vector3(0.4, 1.38, 1.35), "CREW   /   02", 0.18, cream)
		for x in [-2.6, -1.1, 1.1, 2.6]:
			d.box(Vector3(x, 3.64, 0), Vector3(0.035, 0.03, 2.58), brass)
	else:
		for x in range(-4, 5):
			d.box(Vector3(x * 0.95, 1.015, 0), Vector3(0.025, 0.015, 2.45), ink)
		d.lettering(Vector3(0, 0.78, 1.28), "SUPPLY   /   03", 0.2, cream)
	# Small rivet rows are baked into the same batch as the brass fittings.
	for i in 25:
		d.box(Vector3(-4.2 + i * 0.35, 0.91, 1.28), Vector3(0.035, 0.035, 0.025), brass)
	d.finish()


func _process(_delta: float) -> void:
	if _steam == null:
		return
	var train := get_parent().get_parent() as Train
	if train != null:
		_steam.initial_velocity_max = 0.8 + minf(train.speed, 12.0) * 0.1
		_steam.direction.x = -0.4 - train.speed * 0.1


func _frame_window(d: DetailBuilder, p: Vector3, size: Vector2) -> void:
	for side in [-1.0, 1.0]:
		d.box(p + Vector3(side * size.x * 0.5, 0, 0), Vector3(0.065, size.y + 0.08, 0.06), DetailBuilder.INK)
		d.box(p + Vector3(0, side * size.y * 0.5, 0), Vector3(size.x + 0.08, 0.06, 0.07), DetailBuilder.AMBER)
	d.box(p, Vector3(0.035, size.y, 0.05), DetailBuilder.INK)
