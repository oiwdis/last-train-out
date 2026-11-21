class_name FogPresentation
extends Node3D
## Wind-bent banks provide parallax. Observer-local distance fog attenuates real geometry.
## The authority still owns every danger threshold, event, damage tick and save value.
var system: FogSystem
var player_id := ""
var layers: Array[MeshInstance3D] = []
var environment: Environment
var base_density := 0.004
var base_light := Color.WHITE
var base_sky_affect := 0.18
var audio: FogAudio
var _blend := 0.0
var _drawn_front := INF

func bind(authority: FogSystem, id: String) -> void:
	system = authority
	player_id = id
	environment = system.game.station.get_node("Atmosphere").get_environment()
	base_density = environment.fog_density
	base_light = environment.fog_light_color
	base_sky_affect = environment.fog_sky_affect
	for i in 6:
		var mesh := MeshInstance3D.new()
		mesh.mesh = _bank_mesh(i)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/fog/fog_front.gdshader")
		material.set_shader_parameter("density_field",preload("res://assets/environment/fog_density.png"))
		material.set_shader_parameter("phase",float(i)*.317)
		material.set_shader_parameter("opacity",[.58,.72,.55,.64,.51,.58][i])
		material.render_priority = 6-i
		mesh.material_override = material
		add_child(mesh)
		if i == 0:
			# The actual front starts beyond camera range. Prepare its shader with a
			# temporary render proxy, never by moving the dangerous front or player.
			mesh.add_to_group("render_warmup_material")
		layers.append(mesh)
	system.game.graphics.changed.connect(_quality)
	_quality(system.game.graphics.current_index)
	audio = FogAudio.new()
	add_child(audio)
	audio.bind(system, player_id)

## Separate bowed sections put wisps in front of the denser bank. Leading
## and trailing vertices cross the rail at different distances across the valley.
static func _bank_mesh(layer: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var phase := float(layer)*2.39
	var span := 114.+layer*10.
	for col in 19:
		var u := col/18.
		var side := (u*2.-1.)*span
		var bow := sin(side*.037+phase)*6.2 + cos(side*.081-phase)*2.4
		for row in 3:
			var v := row*.5
			var top := 22.+layer*2.+6.*sin(side*.024+phase)
			surface.set_uv(Vector2(u,v))
			surface.set_normal(Vector3.BACK)
			surface.add_vertex(Vector3(side,-3.+v*top,bow+(v*v)*5.))
		if col>0:
			for row in 2:
				var k := (col-1)*3+row
				for offset in [0,3,1,1,3,4]:
					surface.add_index(k+offset)
	return surface.commit()

func _quality(index: int) -> void:
	for i in layers.size():
		layers[i].visible = i < [2, 4, 6][index]
		(layers[i].material_override as ShaderMaterial).set_shader_parameter("detail", [0.,.73,1.][index])

func _process(delta: float) -> void:
	if not system.players.has(player_id):
		return
	var sim := system.simulation
	var dose := system.players[player_id].exposure as FogExposure
	var gap := dose.progress - sim.front
	# Visibility is local to the observer, never global while the front is distant.
	var edge := 1. - smoothstep(-5.,system.config.visibility_falloff_distance,gap)
	var depth := smoothstep(0.,84.,-gap)
	var target := edge*(.53+.47*depth)
	if sim.event == "dense" and gap < system.config.approach_distance:
		target = maxf(target, 0.55)
	_blend = move_toward(_blend, target, delta * 0.6)
	# Each Environment setter submits the complete fog state to the renderer.
	if not environment.fog_enabled:
		environment.fog_enabled = true
	var density := lerpf(base_density, system.config.visibility_density, _blend*_blend)
	if not is_equal_approx(environment.fog_density, density):
		environment.fog_density = density
	var color := base_light.lerp(Color(0.54, 0.61, 0.60), _blend)
	if environment.fog_light_color != color:
		environment.fog_light_color = color
	var sky_affect := lerpf(base_sky_affect,.83,_blend)
	if not is_equal_approx(environment.fog_sky_affect,sky_affect):
		environment.fog_sky_affect = sky_affect
	if _drawn_front == sim.front:
		return
	_drawn_front = sim.front
	for i in layers.size():
		var progress := sim.front + 6. - i * 16.
		var transform := layers[i].global_transform
		transform.origin = system.route.sample(progress)
		var axis := system.route.tangent(progress)
		if axis.length_squared() > 0.1:
			transform.basis = Basis.looking_at(axis, Vector3.UP)
		layers[i].global_transform = transform
