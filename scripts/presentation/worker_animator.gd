class_name WorkerAnimator
extends Node3D
## Visual-only, skinned character. Motion always comes from Player's proven controller.
## AnimationPlayer's per-bone crossfade is the equivalent state/blending system here.
const MODEL := preload("res://assets/characters/railway_survivor.glb")
const LOOPS := [&"idle", &"walk", &"jog", &"sprint", &"fall", &"carry", &"carry_walk", &"climb", &"hang", &"fp_carry", &"fp_carry_walk"]
var player: Player
var animation: AnimationPlayer
var skeleton: Skeleton3D
var model: Node3D
var current_state: StringName = &"idle"
var first_person := false
var _action_remaining := 0.0
var _teleport_cooldown := 0.4

func bind(who: Player, arms_only := false) -> void:
	player = who
	first_person = arms_only
	model = MODEL.instantiate()
	add_child(model)
	animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.visible = mesh.name.begins_with("FP") == first_person
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if material != null and material.resource_name.contains("Aksel"):
				material.normal_scale = 0.22
		if first_person:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for clip in LOOPS:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	# The hidden FP rig keeps its arm roots below the eye even between actions,
	# so its first visible crossfade never sweeps shoulders through the camera.
	animation.play(&"fp_carry" if first_person else &"idle")
	animation.advance(0)
	player.landed.connect(func() -> void:
		if _teleport_cooldown <= 0:
			play_action(&"land", 0.24))
	player.teleported.connect(func(_at: Vector3, _facing: Vector3) -> void:
		_teleport_cooldown = 0.4
		_action_remaining = 0.0
		_change(&"idle", 1.0, true))
	player.presentation_action.connect(play_action)
	if not first_person:
		_add_equipment()

func _add_equipment() -> void:
	var socket := BoneAttachment3D.new()
	socket.name = "UtilityBelt"
	skeleton.add_child(socket)
	for index in skeleton.get_bone_count():
		if skeleton.get_bone_name(index).ends_with("Hips"):
			socket.bone_name = skeleton.get_bone_name(index)
	var belt := SurfaceTool.new()
	belt.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 48:
		var a := index * TAU / 48
		var b := (index + 1) * TAU / 48
		var p0 := Vector3(cos(a)*0.205, 0.035, sin(a)*0.145)
		var p1 := Vector3(cos(b)*0.205, 0.035, sin(b)*0.145)
		for p in [p0, p1, p1+Vector3.UP*.045, p0, p1+Vector3.UP*.045, p0+Vector3.UP*.045]:
			belt.add_vertex(p)
	belt.generate_normals()
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color("443329")
	leather.roughness = 0.82
	leather.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := MeshInstance3D.new()
	mesh.mesh = belt.commit()
	mesh.material_override = leather
	socket.add_child(mesh)
	var torch := AssetDressing.place(socket, "torch", Vector3(0.2,-0.05,-0.12), Vector3.ONE * 0.75)
	torch.rotation.x = PI / 2

func _physics_process(delta: float) -> void:
	if player == null or animation == null:
		return
	_action_remaining = maxf(0, _action_remaining - delta)
	_teleport_cooldown = maxf(0, _teleport_cooldown - delta)
	if _action_remaining > 0 and player._mode == Player.Mode.LOCOMOTION:
		return
	var next := locomotion_clip(player.state, player.carrying_heavy, player.get_horizontal_speed())
	var speed := player.get_horizontal_speed()
	var rate := 1.0
	if next in [&"walk", &"carry_walk"]:
		rate = clampf(speed / 1.65, 0.5, 2.0)
	elif next == &"sprint":
		rate = clampf(speed / 6.0, 0.65, 1.4)
	elif next == &"climb":
		rate = 1.6 if player.input.move.length() > 0.01 else 0.0
	_change(next, rate)

static func locomotion_clip(state: Player.State, heavy: bool, speed: float) -> StringName:
	match state:
		Player.State.CLIMB: return &"climb"
		Player.State.HANG, Player.State.MOUNT: return &"hang"
		Player.State.VAULT: return &"vault"
		Player.State.JUMP: return &"jump"
		Player.State.FALL: return &"fall"
	if heavy:
		return &"carry_walk" if speed > 0.12 else &"carry"
	if state == Player.State.SPRINT:
		return &"sprint"
	return &"walk" if speed > 0.12 else &"idle"

func play_action(clip: StringName, seconds := 0.7) -> void:
	if animation == null or not animation.has_animation(clip):
		return
	_action_remaining = seconds
	_change(clip, 1.0, true)

func _change(clip: StringName, rate: float, restart := false) -> void:
	if current_state != clip or restart:
		var presentation_clip := StringName("fp_" + String(clip)) if first_person and animation.has_animation("fp_" + String(clip)) else clip
		if first_person and not String(presentation_clip).begins_with("fp_"):
			presentation_clip = &"fp_carry"
		animation.play(presentation_clip, 0.16)
		current_state = clip
	animation.speed_scale = rate
