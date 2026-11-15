class_name TrainArt
extends Node3D
## Visual fittings remain children of the existing moving bodies.

@export_enum("Locomotive", "Crew", "Flat") var kind := 0
var _steam: CPUParticles3D


func _ready() -> void:
	var car := get_parent()
	# Original mechanical meshes share materials and stay on the existing body.
	for child in car.get_children():
		if child is MeshInstance3D and kind == 0:
			child.hide()
	var wheels := car.get_node_or_null("Wheels")
	if wheels != null:
		for wheel in wheels.get_children():
			for old in wheel.get_children():
				if old is GeometryInstance3D:
					old.hide()
			wheel.add_child(preload("res://assets/models/rail_wheel.glb").instantiate())
	if kind == 0:
		var machinery := preload("res://assets/models/locomotive_machinery.glb").instantiate()
		add_child(machinery)
		for mesh: MeshInstance3D in machinery.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				if mesh.mesh.surface_get_material(surface).resource_name.contains("Blackened"):
					mesh.set_surface_override_material(surface, preload("res://resources/materials/metal_dark.tres"))
		_steam = PresentationEffects.particles(self, Vector3(3.5, 3.98, 0), 22, Color(0.6, 0.67, 0.7, 0.24), 0.32, 2.1)
		_steam.direction = Vector3(-0.4, 1, 0)
		_steam.initial_velocity_min = 0.35
		_steam.initial_velocity_max = 0.8
		_steam.gravity = Vector3(-0.1, 0.2, 0)
		_steam.emitting = true
	var d := DetailBuilder.new(self, "TrainDetails")
	if kind == 1:
		d.signboard(Vector3(0, 3.2, 1.34), "LAST TRAIN OUT  /  CREW", 4.5, 0.35)
	elif kind == 0:
		d.signboard(Vector3(-2.6, 1.5, 1.34), "L T O   /   07", 2, 0.3)
	else:
		d.lettering(Vector3(0, 0.78, 1.28), "SUPPLY   /   03", 0.2, DetailBuilder.PALE)
	for i in 25:
		for side in [-1.0, 1.0]:
			d.cylinder(Vector3(-4.2 + i * 0.35, 0.9, side * 1.28), 0.018, 0.025, DetailBuilder.STEEL, Vector3(PI / 2, 0, 0))
	d.finish()
	if kind != 2:
		_curved_roof(0.0 if kind == 1 else -2.6, 7.0 if kind == 1 else 3.45)


func _curved_roof(centre: float, length: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 20:
		var z0 := -1.37 + index * 2.74 / 20
		var z1 := z0 + 2.74 / 20
		var y0 := 3.62 - 0.13 * pow(z0 / 1.37, 2)
		var y1 := 3.62 - 0.13 * pow(z1 / 1.37, 2)
		var a := Vector3(centre - length / 2, y0, z0)
		var b := Vector3(centre + length / 2, y0, z0)
		var c := Vector3(centre + length / 2, y1, z1)
		var d := Vector3(centre - length / 2, y1, z1)
		for point in [a, c, b, a, d, c]:
			surface.add_vertex(point)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = preload("res://resources/materials/roof_metal.tres")
	add_child(mesh)


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
