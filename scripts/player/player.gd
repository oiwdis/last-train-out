class_name Player
extends CharacterBody3D
## The train operator: walking, sprinting, jumping, climbing and vaulting.
##
## Three movement modes keep the physics honest:
## * LOCOMOTION - regular [method CharacterBody3D.move_and_slide] movement. Moving
##   platforms (the train) are handled by Godot's platform velocity inheritance;
##   this script only converts between "relative to the floor" and "world"
##   velocity when the player lands, takes off or changes floor.
## * ATTACHED   - holding a ladder or railing. The player is positioned in the
##   anchor's local space, so anchors mounted on the moving train just work.
## * SCRIPTED   - a short authored move (vault, mantle, grabbing on, topping
##   out), also expressed relative to a reference node that may be moving.

signal state_changed(previous: State, current: State)
signal jumped
signal landed
signal attached(anchor: Interactable)
signal detached(anchor: Interactable)
signal vault_started(kind: String)
signal grab_failed(reason: String)

enum State { IDLE, WALK, SPRINT, JUMP, FALL, CLIMB, HANG, VAULT, MOUNT }
enum Mode { LOCOMOTION, ATTACHED, SCRIPTED, SUSPENDED }
enum MoveStyle { DIRECT, ARC, UP_THEN_OVER }

## A floor-velocity change larger than this in one tick means the player
## stepped onto a different surface (as opposed to the train accelerating).
const PLATFORM_SWITCH_THRESHOLD := 0.6
## Inputs that let go of a ladder/railing are ignored for this long after grabbing.
const MIN_ATTACH_TIME := 0.12
## A reference that moves further than this in one tick was teleported.
const TELEPORT_DISTANCE := 4.0

@export var config: PlayerMovementConfig
## Bodies in this group count as "the train" for diagnostics.
@export var train_group := &"train"

var state := State.IDLE
## Horizontal unit vector the character is facing.
var facing := Vector3.RIGHT
## The only carrying modifier. The original movement configuration is never edited.
var carrying_heavy := false

var _mode := Mode.LOCOMOTION
var _is_sprinting := false
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _interact_buffer_timer := 0.0
var _regrab_timer := 0.0
var _jumping := false
var _jump_cut := false
var _grab_failure_reported := false

# Floor bookkeeping (LOCOMOTION).
var _was_on_floor := false
var _ground_body: Node3D
var _ground_velocity := Vector3.ZERO
## Velocity of the frame the player jumped from; air control is measured against it.
var _air_frame_velocity := Vector3.ZERO

# ATTACHED.
var _anchor: Interactable
var _anchor_local := Vector3.ZERO
var _attached_state := State.CLIMB
var _attach_time := 0.0
var _last_anchor: Interactable
var _blocked_ticks := 0

# SCRIPTED.
var _move_reference: Node3D
var _move_from := Vector3.ZERO
var _move_to := Vector3.ZERO
var _move_style := MoveStyle.DIRECT
var _move_arc := 0.0
var _move_time := 0.0
var _move_duration := 0.3
var _move_exit_velocity := Vector3.ZERO
var _move_display_state := State.VAULT
var _move_attach_anchor: Interactable
var _move_attach_state := State.CLIMB

# Velocity of whatever the player is attached to / moving relative to.
var _reference_velocity := Vector3.ZERO
var _reference_previous_origin := Vector3.ZERO
var _reference_tracked := false

var _suspend_ticks := 0

@onready var input: PlayerInput = $Input
@onready var stamina: PlayerStamina = $Stamina
@onready var interactor: PlayerInteractor = $Interactor
@onready var visual: Node3D = $Visual
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	if config == null:
		config = PlayerMovementConfig.new()
	add_to_group(&"player")
	motion_mode = MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	floor_stop_on_slope = true
	floor_constant_speed = true
	floor_block_on_wall = true
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.25
	platform_on_leave = PLATFORM_ON_LEAVE_ADD_VELOCITY
	interactor.setup(self)


func _physics_process(delta: float) -> void:
	input.sample()
	_regrab_timer = maxf(_regrab_timer - delta, 0.0)
	match _mode:
		Mode.LOCOMOTION:
			_tick_locomotion(delta)
		Mode.ATTACHED:
			_tick_attached(delta)
		Mode.SCRIPTED:
			_tick_scripted(delta)
		Mode.SUSPENDED:
			_tick_suspended()
	stamina.tick(delta, _is_sprinting and _mode == Mode.LOCOMOTION)
	_update_state()
	_update_visual(delta)
	input.end_tick()


# --- Public API --------------------------------------------------------------

func get_state_name() -> String:
	return State.keys()[state]


func is_grounded() -> bool:
	return _mode == Mode.LOCOMOTION and is_on_floor()


## True when standing on, climbing on or clinging to the train.
func is_on_train() -> bool:
	var body := get_ride_body()
	return body != null and body.is_in_group(train_group)


## The body the player is currently carried by (floor or anchor mount), or null.
func get_ride_body() -> Node3D:
	match _mode:
		Mode.LOCOMOTION:
			return _ground_body if is_on_floor() else null
		Mode.ATTACHED:
			return _anchor.get_mount_body() if is_instance_valid(_anchor) else null
		Mode.SCRIPTED:
			if _move_reference is Interactable:
				return (_move_reference as Interactable).get_mount_body()
			return _move_reference
	return null


func is_attached() -> bool:
	return _mode == Mode.ATTACHED or (_mode == Mode.SCRIPTED and _move_attach_anchor != null)


func is_sprinting() -> bool:
	return _is_sprinting and _mode == Mode.LOCOMOTION


## Velocity in world space, regardless of what the player is standing on.
func get_world_velocity() -> Vector3:
	if _mode == Mode.LOCOMOTION and is_on_floor():
		return velocity + _ground_velocity
	return velocity


## Horizontal speed relative to the surface the player stands on (m/s).
func get_horizontal_speed() -> float:
	if _mode == Mode.LOCOMOTION:
		if is_on_floor():
			return Vector2(velocity.x, velocity.z).length()
		return Vector2(velocity.x - _air_frame_velocity.x, velocity.z - _air_frame_velocity.z).length()
	return 0.0


func get_body_radius() -> float:
	return (_collision_shape.shape as CapsuleShape3D).radius


func get_body_height() -> float:
	return (_collision_shape.shape as CapsuleShape3D).height


## Starts climbing [param ladder]. Called by [Ladder].
func begin_climb(ladder: Ladder) -> bool:
	return _begin_attach(ladder, ladder.get_attach_local(global_position), State.CLIMB)


## Starts clinging to [param rail]. Called by [GrabRail].
func begin_hang(rail: GrabRail) -> bool:
	return _begin_attach(rail, rail.get_attach_local(global_position), State.HANG)


## Short hint describing what the interact button would do right now.
func get_interaction_prompt() -> String:
	if input.blocked:
		return ""
	match _mode:
		Mode.ATTACHED:
			if _attached_state == State.CLIMB:
				return "W / S  climb    Space  jump off    E  let go"
			return "W  climb over    A / D  shimmy    Space  jump off    E  let go"
		Mode.LOCOMOTION:
			var choice := _choose_interaction()
			if choice.has("interactable"):
				if carrying_heavy and (choice.interactable as Interactable).requires_free_hands():
					return "G  Drop cargo before climbing / grabbing"
				return "E  %s" % (choice["interactable"] as Interactable).prompt
			if choice.has("vault"):
				if carrying_heavy:
					return "G  Drop cargo before vaulting / climbing"
				return "E  Vault" if choice["vault"]["kind"] == "over" else "E  Climb up"
	return ""


## Instantly moves the player, leaving no stale physics state behind.
func teleport_to(world_position: Vector3, new_facing: Vector3 = Vector3.RIGHT) -> void:
	_force_release()
	global_position = world_position
	velocity = Vector3.ZERO
	_clear_floor_state()
	_air_frame_velocity = Vector3.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_interact_buffer_timer = 0.0
	_jumping = false
	_is_sprinting = false
	facing = new_facing
	reset_physics_interpolation()


## Freezes the player in place for a few physics ticks (used while the train is
## teleported underneath them), then resumes normal movement.
func suspend(ticks: int) -> void:
	_force_release()
	velocity = Vector3.ZERO
	_suspend_ticks = maxi(ticks, 1)
	_mode = Mode.SUSPENDED


# --- Locomotion --------------------------------------------------------------

func _tick_locomotion(delta: float) -> void:
	# Contextual interaction, buffered so a grab can be pressed slightly early.
	if input.interact_pressed:
		_interact_buffer_timer = config.interact_buffer_time
		_grab_failure_reported = false
	if _interact_buffer_timer > 0.0:
		_interact_buffer_timer -= delta
		if _try_interact():
			_interact_buffer_timer = 0.0
			if _mode != Mode.LOCOMOTION:
				return

	var on_floor := is_on_floor()
	var has_input := input.move.length_squared() > 0.01
	if has_input:
		facing = Vector3(input.move.x, 0.0, input.move.y).normalized()

	_is_sprinting = input.sprint_held and has_input and stamina.can_sprint() and not carrying_heavy
	var target_speed := config.sprint_speed if _is_sprinting else config.walk_speed
	if carrying_heavy:
		target_speed = 2.5
	var target := Vector3(input.move.x, 0.0, input.move.y * config.depth_speed_scale) * target_speed

	# Horizontal movement. On the floor `velocity` is relative to the floor
	# (Godot adds the platform's motion itself); in the air it is world space.
	if on_floor:
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		var speeding_up := has_input and horizontal.dot(target) > 0.0 and horizontal.length() <= target.length() + 0.1
		var rate := config.ground_acceleration if speeding_up else config.ground_deceleration
		horizontal = horizontal.move_toward(target, rate * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		var relative := Vector3(velocity.x - _air_frame_velocity.x, 0.0, velocity.z - _air_frame_velocity.z)
		var rate := config.air_acceleration if has_input else config.air_deceleration
		relative = relative.move_toward(target, rate * delta)
		velocity.x = _air_frame_velocity.x + relative.x
		velocity.z = _air_frame_velocity.z + relative.z

	# Jump with coyote time and input buffering.
	if on_floor:
		_coyote_timer = config.coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	if input.jump_pressed:
		_jump_buffer_timer = config.jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_do_jump()
		on_floor = false

	# Variable jump height and gravity.
	if _jumping and velocity.y > 0.0 and not input.jump_held and not _jump_cut:
		velocity.y = minf(velocity.y, config.get_jump_release_velocity())
		_jump_cut = true
	if not on_floor:
		var gravity := config.get_rise_gravity() if velocity.y > 0.0 else config.get_fall_gravity()
		velocity.y = maxf(velocity.y - gravity * delta, -config.max_fall_speed)

	move_and_slide()
	_after_move()


func _do_jump() -> void:
	velocity.y = config.get_jump_velocity()
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_jumping = true
	_jump_cut = false
	jumped.emit()


## Reconciles velocity frames after move_and_slide().
func _after_move() -> void:
	var on_floor := is_on_floor()
	if on_floor:
		var platform_velocity := get_platform_velocity()
		platform_velocity.y = 0.0
		if not _was_on_floor:
			# Landed: airborne velocity was world space, floor velocity is relative.
			velocity.x -= platform_velocity.x
			velocity.z -= platform_velocity.z
			_jumping = false
			landed.emit()
		elif platform_velocity.distance_to(_ground_velocity) > PLATFORM_SWITCH_THRESHOLD:
			# Walked onto a surface moving at a different speed (platform <-> train):
			# keep the world velocity continuous so the feet "skid" realistically.
			velocity.x += _ground_velocity.x - platform_velocity.x
			velocity.z += _ground_velocity.z - platform_velocity.z
		_ground_velocity = platform_velocity
		_ground_body = interactor.probe_ground(platform_velocity.length() > 0.05)
	else:
		if _was_on_floor:
			# Left the floor: Godot has just added the platform velocity to `velocity`.
			_air_frame_velocity = _ground_velocity
		_ground_velocity = Vector3.ZERO
		_ground_body = null
		if velocity.y <= 0.0:
			_jumping = false
	_was_on_floor = on_floor


# --- Interaction -------------------------------------------------------------

func _try_interact() -> bool:
	var choice := _choose_interaction()
	var target := choice.get("interactable") as Interactable
	if carrying_heavy and (choice.has("vault") or (target != null and target.requires_free_hands())):
		grab_failed.emit("hands_full")
		return true
	if choice.has("interactable"):
		return (choice["interactable"] as Interactable).interact(self)
	if choice.has("vault"):
		_begin_vault(choice["vault"])
		return true
	return false


## Decides what the interact button means right now. Returns a Dictionary with
## either an "interactable" or a "vault" entry, or nothing at all.
##
## An obstacle the player is heading for beats an interactable that lies behind
## them, so vaulting a crate next to a ladder does not grab the ladder instead.
func _choose_interaction() -> Dictionary:
	var blocked: Interactable = _last_anchor if _regrab_timer > 0.0 else null
	var target := interactor.find_interactable(blocked)
	var heading := facing
	if input.move.length_squared() > 0.01:
		heading = Vector3(input.move.x, 0.0, input.move.y).normalized()
	var vault := interactor.find_vault(heading)
	if target != null:
		var offset := target.get_interaction_point(self) - global_position
		offset.y = 0.0
		var behind := offset.length() > 0.3 and offset.normalized().dot(heading) < -0.2
		if not (behind and not vault.is_empty()):
			return {"interactable": target}
	if not vault.is_empty():
		return {"vault": vault}
	# Nothing ahead: try where the character is looking, then "into the scene"
	# (where the train runs), so boarding works without precise aiming.
	for direction: Vector3 in [facing, Vector3.FORWARD]:
		if direction.is_equal_approx(heading):
			continue
		vault = interactor.find_vault(direction)
		if not vault.is_empty():
			return {"vault": vault}
	return {}


func _begin_vault(vault: Dictionary) -> void:
	var into: Vector3 = vault["into"]
	var end: Vector3 = vault["end"]
	var top_y: float = vault["top_y"]
	var collider := vault["collider"] as Node3D
	var reference: Node3D = collider if _is_moving_body(collider) else null
	var reference_velocity := _get_body_velocity(reference)
	var relative := get_world_velocity() - reference_velocity
	var approach_speed := clampf(Vector3(relative.x, 0.0, relative.z).dot(into), config.walk_speed, config.sprint_speed)
	var start := global_position

	_enter_kinematic_mode()
	_reference_velocity = reference_velocity
	facing = into
	if vault["kind"] == "over":
		var distance := Vector3(end.x - start.x, 0.0, end.z - start.z).length()
		var duration := clampf(distance / approach_speed, 0.24, config.vault_duration + 0.14)
		var arc := maxf(top_y + 0.2 - (start.y + end.y) * 0.5, 0.2)
		_start_scripted(reference, start, end, MoveStyle.ARC, arc, duration, into * approach_speed, State.VAULT)
	else:
		var rise := maxf(end.y - start.y, 0.0)
		var duration := config.mantle_duration * clampf(0.55 + 0.45 * rise / config.vault_max_height, 0.55, 1.0)
		_start_scripted(reference, start, end, MoveStyle.UP_THEN_OVER, 0.0, duration, into * config.walk_speed * 0.4, State.VAULT)
	vault_started.emit(vault["kind"])


func _begin_attach(anchor: Interactable, local_target: Vector3, attached_state: State) -> bool:
	if carrying_heavy:
		grab_failed.emit("hands_full")
		return false
	if _mode != Mode.LOCOMOTION:
		return false
	if anchor == _last_anchor and _regrab_timer > 0.0:
		return false
	var anchor_velocity := anchor.get_velocity()
	if config.max_grab_relative_speed > 0.0:
		var relative := get_world_velocity() - anchor_velocity
		relative.y = 0.0
		if relative.length() > config.max_grab_relative_speed:
			if not _grab_failure_reported:
				_grab_failure_reported = true
				grab_failed.emit("too_fast")
			return false
	var start := global_position
	var distance := anchor.to_local(start).distance_to(local_target)
	var duration := clampf(config.grab_blend_time * (0.6 + distance), config.grab_blend_time * 0.6, config.grab_blend_time * 2.2)
	_enter_kinematic_mode()
	_reference_velocity = anchor_velocity
	_start_scripted(anchor, start, anchor.to_global(local_target), MoveStyle.DIRECT, 0.0, duration, Vector3.ZERO, State.MOUNT, anchor, attached_state)
	return true


# --- Attached (ladder / railing) ----------------------------------------------

func _tick_attached(delta: float) -> void:
	if not is_instance_valid(_anchor) or not _anchor.is_inside_tree() or not _anchor.enabled:
		_detach(Vector3.ZERO)
		return
	_track_reference(_anchor, delta)
	_attach_time += delta
	_is_sprinting = false
	var can_let_go := _attach_time >= MIN_ATTACH_TIME
	var outward := _anchor.global_basis.z
	outward.y = 0.0
	outward = outward.normalized()

	if input.interact_pressed and can_let_go:
		_detach(Vector3.ZERO)
		return
	if input.jump_pressed and can_let_go:
		var push := outward * config.detach_jump_speed
		if absf(input.move.x) > 0.3:
			push = Vector3(signf(input.move.x), 0.0, 0.0) * config.detach_jump_speed * 1.2
		_jumping = true
		_jump_cut = false
		jumped.emit()
		_detach(push + Vector3.UP * config.get_jump_velocity() * 0.9)
		return

	var mounted := false
	if _attached_state == State.CLIMB:
		mounted = _tick_ladder(_anchor as Ladder, delta)
	else:
		mounted = _tick_rail(_anchor as GrabRail, delta)
	if mounted:
		return

	global_position = _anchor.to_global(_anchor_local)
	velocity = _reference_velocity
	facing = -outward

	# Safety net: if the world scrapes the player off a moving anchor, let go
	# rather than being dragged through geometry.
	if _reference_velocity.length() > 0.5:
		var exclude: Array[RID] = []
		var mount := _anchor.get_mount_body()
		if mount != null:
			exclude.append(mount.get_rid())
		_blocked_ticks = 0 if interactor.capsule_fits(global_position, exclude) else _blocked_ticks + 1
		if _blocked_ticks >= 2:
			_detach(outward * 2.0 - _reference_velocity * 0.6)
	else:
		_blocked_ticks = 0


## Returns true when the player started climbing off the top.
func _tick_ladder(ladder: Ladder, delta: float) -> bool:
	var climb := -input.move.y  # "Into the scene" doubles as "up" on a ladder.
	var top := ladder.get_max_climb()
	_anchor_local.y = clampf(_anchor_local.y + climb * config.climb_speed * delta, 0.0, top)
	if climb > 0.3 and _anchor_local.y >= top - 0.001 and ladder.top_exit:
		var exit_local := ladder.get_top_exit_local()
		if interactor.capsule_fits(ladder.to_global(exit_local)):
			_mount_from_anchor(exit_local, MoveStyle.UP_THEN_OVER, 0.0)
			return true
	elif climb < -0.3 and _anchor_local.y <= 0.001 and _attach_time >= MIN_ATTACH_TIME:
		_detach(Vector3.ZERO)
		return true
	return false


## Returns true when the player started climbing over the railing.
func _tick_rail(rail: GrabRail, delta: float) -> bool:
	var wish := Vector3(input.move.x, 0.0, input.move.y)
	var along_axis := rail.global_basis.x.normalized()
	var inward := -rail.global_basis.z.normalized()
	var limit := rail.get_shimmy_limit()
	_anchor_local.x = clampf(_anchor_local.x + wish.dot(along_axis) * config.shimmy_speed * delta, -limit, limit)
	if rail.climb_over and wish.dot(inward) > 0.5:
		var exit_local := rail.get_exit_local(_anchor_local.x)
		if interactor.capsule_fits(rail.to_global(exit_local)):
			_mount_from_anchor(exit_local, MoveStyle.ARC, rail.foot_drop + 0.3)
			return true
	return false


## Scripted move from the current hold position to [param exit_local] (anchor space).
func _mount_from_anchor(exit_local: Vector3, style: MoveStyle, arc: float) -> void:
	var anchor := _anchor
	_anchor = null
	_last_anchor = anchor
	_regrab_timer = config.regrab_cooldown
	detached.emit(anchor)
	_start_scripted(anchor, anchor.to_global(_anchor_local), anchor.to_global(exit_local), style, arc, config.mount_time, Vector3.ZERO, State.MOUNT)


func _detach(extra_velocity: Vector3) -> void:
	var anchor := _anchor
	_anchor = null
	_last_anchor = anchor
	_regrab_timer = config.regrab_cooldown
	_blocked_ticks = 0
	if anchor != null:
		detached.emit(anchor)
	_release_to_locomotion(extra_velocity)


# --- Scripted moves ----------------------------------------------------------

## Starts a scripted move between two world-space points. When [param reference]
## is set, both points are stored in its local space so the move follows it.
func _start_scripted(
	reference: Node3D,
	from_world: Vector3,
	to_world: Vector3,
	style: MoveStyle,
	arc: float,
	duration: float,
	exit_velocity: Vector3,
	display_state: State,
	attach_anchor: Interactable = null,
	attach_state: State = State.CLIMB
) -> void:
	_mode = Mode.SCRIPTED
	_move_reference = reference
	_move_from = reference.to_local(from_world) if reference != null else from_world
	_move_to = reference.to_local(to_world) if reference != null else to_world
	_move_style = style
	_move_arc = arc
	_move_time = 0.0
	_move_duration = maxf(duration, 0.05)
	_move_exit_velocity = exit_velocity
	_move_display_state = display_state
	_move_attach_anchor = attach_anchor
	_move_attach_state = attach_state
	_reference_tracked = false
	_is_sprinting = false


func _tick_scripted(delta: float) -> void:
	if _move_reference != null and (not is_instance_valid(_move_reference) or not _move_reference.is_inside_tree()):
		_move_reference = null
		_move_attach_anchor = null
		_release_to_locomotion(Vector3.ZERO)
		return
	_track_reference(_move_reference, delta)
	_move_time = minf(_move_time + delta / _move_duration, 1.0)
	var local := _sample_move(_move_time)
	global_position = _move_reference.to_global(local) if _move_reference != null else local
	velocity = _reference_velocity
	if _move_time < 1.0:
		return
	if _move_attach_anchor != null:
		_anchor = _move_attach_anchor
		_anchor_local = _move_to
		_attached_state = _move_attach_state
		_attach_time = 0.0
		_blocked_ticks = 0
		_move_attach_anchor = null
		_mode = Mode.ATTACHED
		attached.emit(_anchor)
	else:
		_release_to_locomotion(_move_exit_velocity)


func _sample_move(t: float) -> Vector3:
	var horizontal_t := t
	var vertical_t := t
	match _move_style:
		MoveStyle.DIRECT:
			horizontal_t = smoothstep(0.0, 1.0, t)
			vertical_t = horizontal_t
		MoveStyle.UP_THEN_OVER:
			# Rise first, then move in: reads as pulling up onto a ledge.
			vertical_t = 1.0 - (1.0 - t) * (1.0 - t)
			horizontal_t = t * t
	var point := Vector3(
		lerpf(_move_from.x, _move_to.x, horizontal_t),
		lerpf(_move_from.y, _move_to.y, vertical_t),
		lerpf(_move_from.z, _move_to.z, horizontal_t)
	)
	point.y += _move_arc * 4.0 * t * (1.0 - t)
	return point


## Returns control to move_and_slide() with a world-space velocity.
func _release_to_locomotion(extra_velocity: Vector3) -> void:
	velocity = _reference_velocity + extra_velocity
	_air_frame_velocity = Vector3(_reference_velocity.x, 0.0, _reference_velocity.z)
	_move_reference = null
	_was_on_floor = false
	_coyote_timer = 0.0
	_interact_buffer_timer = 0.0
	_mode = Mode.LOCOMOTION


## Hands the body over to scripted/attached positioning. Captures the current
## world velocity and makes the engine forget the floor it was standing on.
func _enter_kinematic_mode() -> void:
	var world_velocity := get_world_velocity()
	_clear_floor_state()
	velocity = world_velocity
	_jumping = false
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_interact_buffer_timer = 0.0


## CharacterBody3D remembers its floor/platform between move_and_slide() calls.
## After the body has been positioned by hand that memory is stale and would
## apply the old platform's motion once more. A zero-length move in FLOATING
## mode (where no floor exists) clears it; the transform is restored afterwards.
func _clear_floor_state() -> void:
	var saved_transform := global_transform
	var saved_velocity := velocity
	motion_mode = MOTION_MODE_FLOATING
	velocity = Vector3.ZERO
	move_and_slide()
	motion_mode = MOTION_MODE_GROUNDED
	global_transform = saved_transform
	velocity = saved_velocity
	_was_on_floor = false
	_ground_body = null
	_ground_velocity = Vector3.ZERO


func _force_release() -> void:
	if _anchor != null:
		var anchor := _anchor
		_anchor = null
		detached.emit(anchor)
	_move_attach_anchor = null
	_move_reference = null
	_reference_velocity = Vector3.ZERO
	_blocked_ticks = 0
	_mode = Mode.LOCOMOTION


func _tick_suspended() -> void:
	velocity = Vector3.ZERO
	_suspend_ticks -= 1
	if _suspend_ticks <= 0:
		_clear_floor_state()
		_mode = Mode.LOCOMOTION


func _track_reference(reference: Node3D, delta: float) -> void:
	if reference == null:
		_reference_velocity = Vector3.ZERO
		return
	var origin := reference.global_position
	if _reference_tracked and delta > 0.0:
		if origin.distance_to(_reference_previous_origin) > TELEPORT_DISTANCE:
			# The reference was teleported (e.g. train reset): keep the last
			# good velocity and avoid interpolating across the jump.
			reset_physics_interpolation.call_deferred()
		else:
			_reference_velocity = (origin - _reference_previous_origin) / delta
	_reference_previous_origin = origin
	_reference_tracked = true


func _is_moving_body(body: Node3D) -> bool:
	return body is AnimatableBody3D or body is RigidBody3D


func _get_body_velocity(body: Node3D) -> Vector3:
	if body is PhysicsBody3D and _is_moving_body(body):
		return PhysicsServer3D.body_get_state((body as PhysicsBody3D).get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY)
	return Vector3.ZERO


# --- State & presentation ----------------------------------------------------

func _update_state() -> void:
	var next := state
	match _mode:
		Mode.ATTACHED:
			next = _attached_state
		Mode.SCRIPTED:
			next = _move_display_state
		Mode.SUSPENDED:
			next = State.IDLE
		Mode.LOCOMOTION:
			if is_on_floor():
				var speed := Vector2(velocity.x, velocity.z).length()
				if speed < 0.2:
					next = State.IDLE
				elif _is_sprinting and speed > config.walk_speed + 0.3:
					next = State.SPRINT
				else:
					next = State.WALK
			else:
				next = State.JUMP if velocity.y > 0.0 else State.FALL
	if next != state:
		var previous := state
		state = next
		state_changed.emit(previous, next)


func _update_visual(delta: float) -> void:
	if visual == null:
		return
	var target_yaw := atan2(facing.x, facing.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-14.0 * delta))
	var lean := 0.0
	if state == State.SPRINT:
		lean = 0.22
	elif state == State.WALK:
		lean = 0.07
	elif state == State.JUMP:
		lean = 0.1
	visual.rotation.x = lerpf(visual.rotation.x, lean, 1.0 - exp(-10.0 * delta))
