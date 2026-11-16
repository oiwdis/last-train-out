class_name ExplorationCamera
extends Node3D
## A render-interpolated eye with a swept sphere boom. Switching changes presentation only.

signal perspective_changed(perspective: int)
signal settings_changed

enum Perspective { FIRST_PERSON, THIRD_PERSON }
const EYE_HEIGHT := 1.6
const CAMERA_RADIUS := 0.18

var settings := CameraSettings.new()
var perspective := Perspective.THIRD_PERSON
var yaw := 0.0
var pitch := -0.10
var player: Player
var camera: Camera3D
var first_person_anchor: Node3D
var _third_person_anchor: Node3D
var _first_person_hands: Node3D
var _menu_sources: Dictionary = {}
var _queued_perspective := -1
var _boom := 3.2
var _sphere := SphereShape3D.new()
var _last_player_position := Vector3.ZERO
var _collision_distance := 3.2


func bind(who: Player, eye: Camera3D) -> void:
	player = who
	camera = eye
	settings.load_preferences()
	perspective = settings.default_perspective as Perspective
	_sphere.radius = CAMERA_RADIUS
	camera.near = 0.06
	camera.far = 350
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.input.camera_relative = true
	player.interactor.aim_camera = camera
	player.teleported.connect(_on_teleported)
	_third_person_anchor = Node3D.new()
	_third_person_anchor.name = "CarryAnchor"
	_third_person_anchor.position = Vector3(0, 0.76, 0.42)
	player.visual.add_child(_third_person_anchor)
	first_person_anchor = Node3D.new()
	first_person_anchor.name = "FirstPersonCarryAnchor"
	first_person_anchor.position = Vector3(0, -0.66, -0.62)
	first_person_anchor.rotation.y = PI
	camera.add_child(first_person_anchor)
	_first_person_hands = Node3D.new()
	_first_person_hands.name = "FirstPersonHands"
	camera.add_child(_first_person_hands)
	_make_hands()
	_boom = settings.third_person_distance if perspective == Perspective.THIRD_PERSON else 0.0
	_last_player_position = player.global_position
	_update_presentation()
	_refresh_mouse()
	snap_to_target()


func _exit_tree() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"perspective_toggle") and not event.is_echo():
		request_perspective(1 - perspective)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _menu_sources.is_empty() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.screen_relative)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _menu_sources.is_empty():
		_refresh_mouse()
	elif event.is_action_pressed(&"debug_close") and _menu_sources.is_empty():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func look(relative: Vector2) -> void:
	yaw = wrapf(yaw - relative.x * settings.sensitivity, -PI, PI)
	pitch = clampf(pitch - relative.y * settings.sensitivity, deg_to_rad(-75), deg_to_rad(75))
	player.input.camera_yaw = yaw


func aim_at(point: Vector3) -> void:
	var direction := point - (player.global_position + Vector3.UP * EYE_HEIGHT)
	if direction.length_squared() < 0.001:
		return
	yaw = atan2(-direction.x, -direction.z)
	# Solve the shoulder offset too, so the centre reticle targets the requested point.
	var shoulder := 0.32 * minf(_boom / settings.third_person_distance, 1.0)
	yaw += asin(clampf(shoulder / maxf(Vector2(direction.x, direction.z).length(), 0.01), -0.95, 0.95))
	direction -= Basis(Vector3.UP, yaw).x * shoulder
	pitch = clampf(atan2(direction.y, Vector2(direction.x, direction.z).length()), deg_to_rad(-75), deg_to_rad(75))
	player.input.camera_yaw = yaw
	snap_to_target()


func request_perspective(value: int) -> void:
	value = clampi(value, 0, 1)
	if player._mode == Player.Mode.SCRIPTED:
		_queued_perspective = value
		return
	if value == perspective:
		return
	perspective = value as Perspective
	_update_presentation()
	perspective_changed.emit(perspective)


func apply_settings(persist: bool = true) -> void:
	settings.sanitize()
	if persist:
		settings.save_preferences()
	settings_changed.emit()


func set_menu_open(source: StringName, open: bool) -> void:
	if open:
		_menu_sources[source] = true
	else:
		_menu_sources.erase(source)
	_refresh_mouse()


func _refresh_mouse() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _menu_sources.is_empty() else Input.MOUSE_MODE_VISIBLE


func physics_tick(_delta: float) -> void:
	if _queued_perspective >= 0 and player._mode != Player.Mode.SCRIPTED:
		var requested := _queued_perspective
		_queued_perspective = -1
		request_perspective(requested)
	player.input.camera_yaw = yaw
	if perspective == Perspective.FIRST_PERSON and player._mode == Player.Mode.LOCOMOTION:
		player.facing = -Basis(Vector3.UP, yaw).z


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var distance := settings.third_person_distance if perspective == Perspective.THIRD_PERSON else 0.0
	_boom = lerpf(_boom, distance, 1.0 - exp(-settings.smoothing * delta))
	# The interpolated player and train share the same render time, including between ticks.
	_place_camera(player.get_global_transform_interpolated().origin, delta)
	_update_hand_visibility()


func snap_to_target() -> void:
	if not is_instance_valid(player) or camera == null:
		return
	_place_camera(player.global_position)


func _on_teleported(_point: Vector3, facing: Vector3) -> void:
	yaw = atan2(-facing.x, -facing.z)
	player.input.camera_yaw = yaw
	_last_player_position = player.global_position
	snap_to_target()


func _place_camera(feet: Vector3, delta: float = 0) -> void:
	var pivot := feet + Vector3.UP * EYE_HEIGHT
	var orientation := Basis.from_euler(Vector3(pitch, yaw, 0))
	var offset := orientation.z * _boom
	if _boom > 0.02:
		offset += orientation.x * minf(_boom / settings.third_person_distance, 1.0) * 0.32
	var destination := pivot + offset
	if offset.length_squared() > 0.0001:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _sphere
		query.transform = Transform3D(Basis.IDENTITY, pivot)
		query.motion = offset
		query.collision_mask = 5
		query.exclude = [player.get_rid()]
		var fractions := player.get_world_3d().direct_space_state.cast_motion(query)
		if fractions.size() > 0:
			destination = pivot + offset * maxf(fractions[0] - 0.015, 0.0)
	var allowed := pivot.distance_to(destination)
	if delta > 0 and allowed > _collision_distance:
		allowed = lerpf(_collision_distance, allowed, 1.0 - exp(-settings.smoothing * delta))
		destination = pivot + offset.normalized() * allowed
	_collision_distance = allowed
	camera.global_transform = Transform3D(orientation, destination)
	camera.fov = lerpf(settings.first_person_fov, 72.0, clampf(_boom / settings.third_person_distance, 0, 1))
	# Retracting all the way inside a wall must never expose the inside of the head.
	player.visual.visible = perspective == Perspective.THIRD_PERSON and _collision_distance > 0.45


func _update_presentation() -> void:
	player.set_carry_anchor(first_person_anchor if perspective == Perspective.FIRST_PERSON else _third_person_anchor)
	_update_hand_visibility()


func _update_hand_visibility() -> void:
	var arms := _first_person_hands.get_node_or_null("FirstPersonWorker") as WorkerAnimator
	var action := arms != null and arms._action_remaining > 0 and arms.current_state in [&"pickup", &"drop", &"operate"]
	_first_person_hands.visible = perspective == Perspective.FIRST_PERSON and (player.carrying_heavy or action)


func _make_hands() -> void:
	var arms := WorkerAnimator.new()
	arms.name = "FirstPersonWorker"
	arms.position = Vector3(0, -EYE_HEIGHT + 0.32, -0.2)
	arms.rotation.y = PI
	_first_person_hands.add_child(arms)
	arms.bind(player, true)
