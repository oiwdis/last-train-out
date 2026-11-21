class_name RouteVerge
extends RefCounted
## Trees, wire and fences are grouped within each terrain chunk. They use fixed
## coordinates and local seeds and never participate in the survival random stream.
const ATLAS := preload("res://assets/environment/railway_copse.png")
static var _trees: Array[ArrayMesh] = []

static func clear_cache() -> void:
	_trees.clear()

static func foliage_mesh(index: int) -> ArrayMesh:
	if _trees.is_empty():
		var leaves := StandardMaterial3D.new()
		leaves.albedo_texture = ATLAS
		leaves.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		leaves.alpha_scissor_threshold = .36
		leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
		leaves.roughness = 1.
		leaves.backlight_enabled = true
		leaves.backlight = Color(.16,.19,.09)
		for variant in 4:
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			var tile := Vector2(variant%2,variant/2)*.5
			for turn in 3:
				var direction := Vector3(cos(turn*PI/3.),0,sin(turn*PI/3.))
				for uv: Vector2 in [Vector2(0,1),Vector2(0,0),Vector2(1,0), Vector2(0,1),Vector2(1,0),Vector2(1,1)]:
					surface.set_uv(tile + (Vector2(.003,.003)+uv*.994)*.5)
					surface.set_normal((Vector3.UP*.78 + direction*(uv.x-.5)*.4).normalized())
					surface.add_vertex(direction*(uv.x-.5)+Vector3.UP*(1.-uv.y))
			surface.set_material(leaves)
			_trees.append(surface.commit())
	return _trees[index]

static func dress(chunk: Node3D, route: FogRoute, start: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 37249 + start
	var groups: Array = [[],[],[],[]]
	for grove in 7:
		var along := start + rng.randf_range(2.,115.)
		var side := (-1. if grove%2 else 1.) * rng.randf_range(12.,125.)
		for tree in range(2+rng.randi_range(0,4)):
			var at := along+rng.randf_range(-9.,9.)
			var lateral := side+rng.randf_range(-8.,8.)
			if absf(lateral)<9. or RouteLandscape.yard_weight(route,at,lateral)>.02: continue
			var ground := RouteLandscape.point(RouteTrack.frame(route,at),at,lateral,route)
			var variant := rng.randi_range(0,3)
			var height := rng.randf_range(4.8,9.2) if variant<2 else rng.randf_range(1.6,3.8)
			var basis := Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*height)
			groups[variant].append(Transform3D(basis,ground-Vector3.UP*.045))
	for variant in 4:
		var poses: Array[Transform3D] = []
		poses.assign(groups[variant])
		RouteTrack.instance_batch(chunk,"Copse%d" % variant,foliage_mesh(variant),poses,285. if variant<2 else 155.)
	var steel := DetailBuilder.new(chunk,"LineFurniture")
	for at in range(start+12,start+RouteTrack.CHUNK,60):
		var frame := RouteTrack.frame(route,at)
		var base := RouteLandscape.point(frame,at,-10.8,route)
		var next_at := at+60
		var next_frame := RouteTrack.frame(route,next_at)
		var other := RouteLandscape.point(next_frame,next_at,-10.8,route)
		if RouteLandscape.yard_weight(route,at,-10.8)>.1: continue
		steel.beam(base,base+Vector3.UP*6.6,.17,Color("51483d"))
		steel.beam(base+Vector3.UP*6.3-frame.basis.z*.9,base+Vector3.UP*6.3+frame.basis.z*.9,.11,DetailBuilder.INK)
		if RouteLandscape.yard_weight(route,next_at,-10.8)<.1:
			for wire: float in [-.68,.68]:
				var a := base+Vector3.UP*6.42+frame.basis.z*wire
				var b := other+Vector3.UP*6.42+next_frame.basis.z*wire
				var sag := (a+b)*.5-Vector3.UP*.78
				steel.beam(a,sag,.034,DetailBuilder.INK)
				steel.beam(sag,b,.034,DetailBuilder.INK)
	if start>=280 and posmod(start,480)==280:
		var last := Vector3.ZERO
		for n in 10:
			var at := start+8+n*4
			if RouteLandscape.yard_weight(route,at,8.)>.1: break
			var post := RouteLandscape.point(RouteTrack.frame(route,at),at,8.,route)
			steel.beam(post,post+Vector3.UP*1.08,.10,DetailBuilder.RUST)
			if n>0 and n!=6:
				for level: float in [.39,.82]:
					steel.beam(last+Vector3.UP*level,post+Vector3.UP*level,.05,DetailBuilder.STEEL)
			last = post
	steel.finish()
