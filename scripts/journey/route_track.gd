class_name RouteTrack
extends Node3D
## The sampled landscape supplies both visible ground and continuously resident collision.
const RAIL_START := 280
const FIRST_CHUNK := -440
const CHUNK := 120
const STEP := 6
const STEEL := preload("res://resources/materials/rail_steel.tres")
const TIMBER := preload("res://resources/materials/sleeper_wood.tres")
var route: FogRoute
var chunks: Array[Node3D] = []
var observer: Node3D
var _refresh := 0.0

static func frame(railway: FogRoute, progress: float) -> Transform3D:
	var x := railway.tangent(progress)
	var z := x.cross(Vector3.UP).normalized()
	return Transform3D(Basis(x,z.cross(x).normalized(),z),railway.sample(progress))

static func geometry_key(railway: FogRoute) -> String:
	var controls := PackedInt32Array()
	for segment in railway.segments:
		var curve := segment.curve
		controls.append(curve.point_count)
		for i in curve.point_count:
			for value: Vector3 in [curve.get_point_position(i),curve.get_point_in(i),curve.get_point_out(i)]:
				for axis in 3: controls.append(roundi(value[axis]*1000.))
	for station in railway.stations: controls.append(roundi(float(railway.stations[station])*10.))
	return (railway.id+str(controls)).sha256_text()

func build(railway: FogRoute, player: Node3D, baked: PackedScene = null) -> void:
	route = railway
	observer = player
	if baked != null:
		var corridor := baked.instantiate() as Node3D
		if corridor.get_meta("geometry_key","") == geometry_key(route):
			add_child(corridor)
			chunks.assign(corridor.get_children())
			_update_visibility()
			return
		corridor.free()
	generate_corridor()
	_update_visibility()

## Editor bake and custom-route fallback. Shipped routes load the mesh and the
## triangle collision together through the normal threaded mission resource.
func generate_corridor() -> void:
	var tie := BoxMesh.new()
	tie.size = Vector3(.24,.05,2.3)
	tie.material = TIMBER
	for start in range(FIRST_CHUNK,ceili(route.length())+400,CHUNK):
		var chunk := Node3D.new()
		chunk.name = "Track_%d" % start
		add_child(chunk)
		chunks.append(chunk)
		var frames: Array[Transform3D] = []
		for along in range(start,start+CHUNK+1,STEP):
			frames.append(frame(route,along))
		var ground := RouteLandscape.build(frames,start,STEP,route)
		_visual(chunk,"Ground",ground)
		var body := StaticBody3D.new()
		body.name = "GroundCollision"
		var collision := CollisionShape3D.new()
		collision.shape = ground.create_trimesh_shape()
		body.add_child(collision)
		chunk.add_child(body)
		if start >= RAIL_START:
			_visual(chunk,"BallastShoulders",RailFormation.ballast(frames,start,STEP,2.9,RailFormation.BALLAST))
			_visual(chunk,"RunningRails",RailFormation.running_rails(frames,start,STEP,Track.STANDARD_GAUGE,Track.STANDARD_RAIL_HEIGHT,STEEL))
			var sleepers: Array[Transform3D] = []
			for n in range(ceili(start/.7),ceili((start+CHUNK)/.7)):
				var index := (n*.7-start)/STEP
				var before := clampi(floori(index),0,frames.size()-2)
				var pose := frames[before].interpolate_with(frames[before+1],index-before)
				sleepers.append(pose.translated_local(Vector3.UP*.035))
			instance_batch(chunk,"Ties",tie,sleepers,150.)
		RouteVerge.dress(chunk,route,start)

static func _visual(parent: Node3D, title: String, mesh: Mesh) -> void:
	var instance := MeshInstance3D.new()
	instance.name = title
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

static func instance_batch(parent: Node3D, title: String, mesh: Mesh, poses: Array[Transform3D], end: float) -> void:
	if poses.is_empty():
		return
	var batch := MultiMeshInstance3D.new()
	batch.name = title
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = poses.size()
	# Godot's headless storage serializes the bulk buffer. Individual transform
	# setters lack storage on that backend, so baking those would lose the poses.
	var data := PackedFloat32Array()
	var mesh_bounds := mesh.get_aabb()
	var bounds := poses[0]*mesh_bounds
	for pose in poses:
		bounds = bounds.merge(pose*mesh_bounds)
		for axis in 3:
			data.append(pose.basis.x[axis])
			data.append(pose.basis.y[axis])
			data.append(pose.basis.z[axis])
			data.append(pose.origin[axis])
	multi.buffer = data
	multi.custom_aabb = bounds
	batch.multimesh = multi
	batch.visibility_range_end = end
	batch.visibility_range_end_margin = 12.
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(batch)

func _process(delta: float) -> void:
	_refresh += delta
	if _refresh > .3:
		_refresh = 0
		_update_visibility()

func _update_visibility() -> void:
	if observer == null: return
	var progress := route.project(observer.global_position)
	for i in chunks.size():
		chunks[i].visible = absf(FIRST_CHUNK+(i+.5)*CHUNK-progress) < 520.
