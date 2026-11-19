class_name RouteTrack
extends Node3D
## Bounded draw chunks. All collision remains resident: no streaming underneath riders.
var route: FogRoute
var chunks: Array[Node3D] = []
var observer: Node3D
var _refresh := 0.0

static func frame(railway: FogRoute, progress: float) -> Transform3D:
	var x := railway.tangent(progress)
	var z := x.cross(Vector3.UP).normalized()
	return Transform3D(Basis(x, z.cross(x).normalized(), z), railway.sample(progress))

func build(railway: FogRoute, player: Node3D) -> void:
	route = railway
	observer = player
	var steel := preload("res://resources/materials/rail_steel.tres")
	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color("363b32")
	ground.roughness = 1
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("49453a")
	wood.roughness = 0.95
	for start in range(280, ceili(route.length()) + 100, 120):
		var chunk := Node3D.new()
		chunk.name = "Track_%d" % start
		add_child(chunk)
		chunks.append(chunk)
		var sleepers: Array[Transform3D] = []
		var rails: Array[Transform3D] = []
		for n in range(172):
			var at := start + n * 0.7
			var t := frame(route, at)
			t.origin += t.basis.y * 0.035
			sleepers.append(t)
		var earth := StaticBody3D.new()
		chunk.add_child(earth)
		for n in range(12):
			var t := frame(route, start + n * 10 + 5)
			for side in [-Track.STANDARD_GAUGE/2,Track.STANDARD_GAUGE/2]:
				var rail := t
				rail.origin += t.basis * Vector3(0,Track.STANDARD_RAIL_HEIGHT-0.03,side)
				rails.append(rail)
			var floor := BoxPart.new()
			floor.size = Vector3(10.3,0.6,620)
			floor.material = ground
			floor.transform = t.translated_local(Vector3(0,-0.32,0))
			floor.cast_shadow = false
			earth.add_child(floor)
		# Match Harlow's running surface. Only visible ties/rails change; the
		# existing ground bodies, route frames and train integrator are untouched.
		_instance(chunk, sleepers, Vector3(0.23,0.05,2.7), wood)
		_instance(chunk, rails, Vector3(10.12,0.06,0.09), steel)
		# Telegraph poles and broken fence lines provide speed/scale cues.
		var detail := DetailBuilder.new(chunk)
		for along in [15.0,75.0]:
			var t := frame(route, start + along)
			var pole := t * Vector3(0,0,10)
			detail.beam(pole, pole + Vector3.UP * 6, 0.18, Color("514a40"))
			detail.beam(pole + Vector3(-1.2,5.3,0), pole + Vector3(1.2,5.3,0), 0.12, Color("514a40"))
		detail.finish()
	_update_visibility()

func _instance(parent: Node3D, transforms: Array[Transform3D], size: Vector3, material: Material) -> void:
	var batch := MultiMeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.mesh = mesh
	batch.multimesh.instance_count = transforms.size()
	for i in transforms.size():
		batch.multimesh.set_instance_transform(i, transforms[i])
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(batch)

func _process(delta: float) -> void:
	_refresh += delta
	if _refresh > 0.3:
		_refresh = 0
		_update_visibility()

func _update_visibility() -> void:
	if observer == null:
		return
	var progress := route.project(observer.global_position)
	for i in chunks.size():
		chunks[i].visible = absf(340 + i * 120 - progress) < 430
