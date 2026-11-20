class_name TrainArt
extends Node3D
## Visual fittings remain children of the existing moving bodies.

@export_enum("Locomotive", "Crew", "Flat") var kind := 0
var _steam: CPUParticles3D
var _drive_wheels: Array[MeshInstance3D] = []
var _wheel_phase := 0.0
var _last_speed := -1.0
var _last_state := -1
var mechanics: TrainMechanics


func _ready() -> void:
	var profile_start := Time.get_ticks_usec()
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
			if kind != 0:
				wheel.add_child(preload("res://assets/models/rail_wheel.glb").instantiate())
				# The common carriage wheel has a 0.45 m outer tyre radius.
				wheel.position.y = Track.STANDARD_RAIL_HEIGHT + .45
				wheel.position.z = signf(wheel.position.z)*Track.STANDARD_GAUGE/2
	if kind == 0:
		var machinery := preload("res://assets/train/steam_locomotive.glb").instantiate()
		machinery.name = "AuthoredLocomotive"
		add_child(machinery)
		for piece: MeshInstance3D in machinery.find_children("*","MeshInstance3D",true,false):
			for surface in piece.mesh.get_surface_count():
				var material := piece.mesh.surface_get_material(surface) as StandardMaterial3D
				if material != null and material.resource_name in ["LTO Black","LTO Black Metal Paint","LTO Black.001"]:
					# Source dark paint was multiplied into an already dark scan at
					# conversion. Restore charcoal detail without adding emission.
					material.albedo_color = Color(1.85,1.85,1.85)
		for mesh: MeshInstance3D in machinery.find_children("DrivingWheel*", "MeshInstance3D", true, false):
			# The source model's wheelset is narrower and off-centre. Fit only its
			# rolling assemblies to the shared rails; cabin/boiler and collisions
			# retain their authored dimensions and positions.
			var at := to_local(mesh.global_position)
			at.y = mesh.mesh.get_aabb().size.y*.5 + Track.STANDARD_RAIL_HEIGHT
			at.z = signf(at.z)*Track.STANDARD_GAUGE/2
			mesh.global_position = to_global(at)
			_drive_wheels.append(mesh)
		_fit_axles()
		mechanics = TrainMechanics.new()
		mechanics.name = "LiveRunningGearAndInstruments"
		add_child(mechanics)
		_steam = PresentationEffects.particles(self, Vector3(5.15, 3.55, 0), 22, Color(0.6, 0.67, 0.7, 0.24), 0.32, 2.1)
		_steam.direction = Vector3(-0.4, 1, 0)
		_steam.initial_velocity_min = 0.35
		_steam.initial_velocity_max = 0.8
		_steam.gravity = Vector3(-0.1, 0.2, 0)
		_steam.emitting = true
		_soft_steam()
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
		var finish := (preload("res://assets/train/crew_car_finish.glb") if kind == 1 else preload("res://assets/train/locomotive_cab_finish.glb")).instantiate()
		finish.name = "CarriageFinish"
		add_child(finish)
		for mesh: MeshInstance3D in finish.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				if mesh.mesh.surface_get_material(surface).resource_name == "Black oxide hardware":
					mesh.set_surface_override_material(surface, preload("res://resources/materials/metal_dark.tres"))
		AssetDressing.place(self, "sconce", Vector3(-0.8 if kind == 1 else -2.8, 2.9, 1.15), Vector3.ONE * 0.65, PI)
		if kind == 1:
			AssetDressing.place(self, "suitcase", Vector3(1.8, 1.5, 0.95), Vector3.ONE * 0.7)
		else:
			AssetDressing.place(self, "oil_can", Vector3(-3.6, 1.6, -0.9), Vector3.ONE)
	set_process(_steam != null)
	PerformanceTrace.mark("train_art",profile_start)


func _fit_axles() -> void:
	var seen := {}
	for wheel in _drive_wheels:
		var at := to_local(wheel.global_position)
		var key := Vector2(at.x,at.y).snapped(Vector2.ONE*.01)
		if seen.has(key): continue
		seen[key] = true
		var axle := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = .055
		cylinder.bottom_radius = .055
		cylinder.height = Track.STANDARD_GAUGE
		cylinder.radial_segments = 16
		cylinder.rings = 1
		cylinder.material = preload("res://resources/materials/metal_dark.tres")
		axle.mesh = cylinder
		axle.position = Vector3(at.x,at.y,0)
		axle.rotation.x = PI/2
		add_child(axle)

func _soft_steam() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray([Color(1,1,1,0.32), Color(1,1,1,0.18), Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var quad := QuadMesh.new()
	quad.size = Vector2(1.4,1.4)
	quad.material = material
	_steam.mesh = quad


func _process(_delta: float) -> void:
	if _steam == null:
		return
	var train := get_parent().get_parent() as Train
	if train != null:
		# Node3D transform setters dirty shadow casters even when the pose is
		# identical. A brake/regulator change at rest still updates the gauges.
		if train.distance == _wheel_phase and train.speed == _last_speed and train.state == _last_state:
			return
		_last_speed = train.speed
		_last_state = train.state
		# Route distance is the simulation authority, including curves and restored
		# saves. Integrating render deltas drifted and restarted the rods on loading.
		_wheel_phase = train.distance
		for wheel in _drive_wheels:
			var radius := maxf(wheel.mesh.get_aabb().size.y * 0.5, 0.2)
			var quartering := PI/2 if radius > .5 and wheel.position.z > 0 else 0.0
			wheel.rotation.z = -_wheel_phase / radius + quartering
		mechanics.update_mechanism(_wheel_phase,train)
		_steam.initial_velocity_max = 0.8 + minf(train.speed, 12.0) * 0.1
		_steam.direction.x = -0.4 - train.speed * 0.1


func _frame_window(d: DetailBuilder, p: Vector3, size: Vector2) -> void:
	for side in [-1.0, 1.0]:
		d.box(p + Vector3(side * size.x * 0.5, 0, 0), Vector3(0.065, size.y + 0.08, 0.06), DetailBuilder.INK)
		d.box(p + Vector3(0, side * size.y * 0.5, 0), Vector3(size.x + 0.08, 0.06, 0.07), DetailBuilder.AMBER)
	d.box(p, Vector3(0.035, size.y, 0.05), DetailBuilder.INK)
