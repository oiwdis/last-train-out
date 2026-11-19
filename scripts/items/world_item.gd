class_name WorldItem
extends CharacterBody3D
## Non-blocking supplies collide with world/train floors, never with the player.
## Godot's normal moving-platform support carries released cargo on train decks.

var persistent_id := ""
var item: ItemDefinition
var amount := 1
var held := false
var available := true
var interaction: SupplyInteractable
var resting_body: TrainCar
var _was_grounded := false
var _ground_velocity := Vector3.ZERO
var _safe_position := Vector3.ZERO
var _suspend_ticks := 0
var _settled_ticks := 0
var _carrier: Player


func _ready() -> void:
	collision_layer = 0
	collision_mask = 5
	platform_floor_layers = 4
	platform_on_leave = PLATFORM_ON_LEAVE_ADD_VELOCITY
	floor_snap_length = 0.15
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25 if item.heavy else 0.12
	capsule.height = 0.72 if item.heavy else 0.3
	shape.shape = capsule
	shape.position.y = capsule.height / 2
	add_child(shape)
	var visual := item.world_scene.instantiate() as ItemVisual
	add_child(visual)
	visual.configure(item)
	interaction = SupplyInteractable.new()
	interaction.prompt = "%s %s%s" % ["Carry" if item.heavy else "Take", item.display_name,
		" · HEAVY" if item.heavy else " ×%d" % amount]
	add_child(interaction)
	if item.heavy:
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.text = "HEAVY / TWO HANDS"
		label.position.y = 1.0
		label.font_size = 28
		label.pixel_size = 0.0045
		label.modulate = Color("e9b568")
		label.no_depth_test = false
		label.name = "CargoLabel"
		add_child(label)
	_safe_position = global_position


func hold(player: Player) -> void:
	_carrier = player
	player.carried_visual = self
	held = true
	available = false
	interaction.enabled = false
	collision_mask = 0
	set_physics_process(false)
	_clear_floor()
	reparent(player.carry_anchor if player.carry_anchor != null else player.visual)
	position = Vector3.ZERO if player.carry_anchor != null else Vector3(0, 0.65, 0.48)
	rotation = Vector3.ZERO
	get_node("CargoLabel").hide()
	reset_physics_interpolation()


func release(parent: Node3D, at: Vector3, initial_velocity: Vector3) -> void:
	if is_instance_valid(_carrier):
		_carrier.carried_visual = null
	_carrier = null
	reparent(parent)
	global_position = at
	global_rotation = Vector3.ZERO
	_clear_floor()
	velocity = initial_velocity
	held = false
	available = true
	interaction.enabled = true
	collision_mask = 5
	get_node("CargoLabel").show()
	set_physics_process(true)
	reset_physics_interpolation()


func retire() -> void:
	if is_instance_valid(_carrier):
		_carrier.carried_visual = null
	_carrier = null
	available = false
	interaction.enabled = false
	collision_mask = 0
	hide()
	set_physics_process(false)
	queue_free()


func reset_on_train(at: Vector3) -> void:
	global_position = at
	_clear_floor()
	_suspend_ticks = 3
	reset_physics_interpolation()


func _clear_floor() -> void:
	var saved_transform := global_transform
	velocity = Vector3.ZERO
	motion_mode = MOTION_MODE_FLOATING
	move_and_slide()
	motion_mode = MOTION_MODE_GROUNDED
	# Leaving a remembered platform may add its old velocity and move the body.
	global_transform = saved_transform
	velocity = Vector3.ZERO
	_was_grounded = false
	_ground_velocity = Vector3.ZERO
	resting_body = null
	_settled_ticks = 0


func _physics_process(delta: float) -> void:
	if _suspend_ticks > 0:
		velocity = Vector3.ZERO
		_suspend_ticks -= 1
		if _suspend_ticks == 0:
			_clear_floor()
		return
	if not is_on_floor():
		velocity.y = maxf(velocity.y - 20 * delta, -25)
	else:
		velocity.x = move_toward(velocity.x, 0, 12 * delta)
		velocity.z = move_toward(velocity.z, 0, 12 * delta)
	move_and_slide()
	if is_on_floor():
		var platform := get_platform_velocity()
		if not _was_grounded:
			velocity.x -= platform.x
			velocity.z -= platform.z
		elif platform.distance_to(_ground_velocity) > 0.6:
			velocity.x += _ground_velocity.x - platform.x
			velocity.z += _ground_velocity.z - platform.z
		_ground_velocity = platform
		_safe_position = global_position
		for i in get_slide_collision_count():
			var hit := get_slide_collision(i)
			if hit.get_normal().y > 0.7:
				resting_body = hit.get_collider() as TrainCar
		_settled_ticks = _settled_ticks + 1 if resting_body == null and velocity.length() < 0.02 else 0
		if _settled_ticks > 30:
			set_physics_process(false)
	else:
		resting_body = null
		_settled_ticks = 0
	_was_grounded = is_on_floor()
	if global_position.y < -20:
		global_position = _safe_position + Vector3.UP * 0.15
		_clear_floor()
		reset_physics_interpolation()
