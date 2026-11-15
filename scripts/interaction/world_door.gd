class_name WorldDoor
extends Interactable
## The closed collider belongs to its supporting body, including a moving train.

@export var width := 1.1
@export var height := 2.2
@export var starts_open := true
var is_open := true
var _panel: Node3D
var _target_shape: CollisionShape3D
var _collider: CollisionShape3D
var _closed_transform: Transform3D
var _latch: AudioStreamPlayer3D
var _motion: Tween


func _ready() -> void:
	super()
	var area := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width + 0.25, height, 0.36)
	area.shape = shape
	area.position.y = height / 2
	_target_shape = area
	add_child(area)
	_panel = Node3D.new()
	_panel.position.x = -width / 2
	add_child(_panel)
	var visual := BoxVisual.new()
	visual.size = Vector3(width, height, 0.07)
	visual.position = Vector3(width / 2, height / 2, 0)
	visual.material = preload("res://resources/materials/train_body.tres")
	_panel.add_child(visual)
	var details := DetailBuilder.new(_panel)
	details.box(Vector3(width - 0.12, height * 0.48, 0.07), Vector3(0.04, 0.19, 0.04), DetailBuilder.AMBER)
	details.box(Vector3(width / 2, height * 0.73, 0.045), Vector3(width * 0.66, height * 0.24, 0.025), Color("32494d"))
	details.finish()
	_collider = CollisionShape3D.new()
	var solid := BoxShape3D.new()
	solid.size = Vector3(width, height, 0.09)
	_collider.shape = solid
	_closed_transform = transform * Transform3D(Basis.IDENTITY, Vector3(0, height / 2, 0))
	_collider.transform = _closed_transform
	get_parent().add_child.call_deferred(_collider)
	is_open = starts_open
	_collider.disabled = is_open
	_panel.rotation.y = -PI / 2 if is_open else 0
	_align_target()
	_update_prompt()
	if DisplayServer.get_name() != "headless":
		_latch = AudioStreamPlayer3D.new()
		_latch.stream = preload("res://assets/audio/latch.wav")
		_latch.volume_db = -10
		_latch.max_distance = 12
		add_child(_latch)


func can_interact(player: Player) -> bool:
	return enabled and player.global_position.distance_to(global_position) < 2.2


func interact(player: Player) -> bool:
	if not can_interact(player):
		return false
	if is_open:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _collider.shape
		query.transform = get_parent().global_transform * _closed_transform
		query.collision_mask = 2
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return false # Never close a door through a person.
	is_open = not is_open
	if _latch != null:
		_latch.play()
	_collider.set_deferred("disabled", is_open)
	_stop_motion()
	_motion = create_tween()
	_motion.tween_property(_panel, "rotation:y", -PI / 2 if is_open else 0.0, 0.3)
	_update_prompt()
	return true


func _update_prompt() -> void:
	prompt = "Close door" if is_open else "Open door"


func reset_state() -> void:
	_stop_motion()
	is_open = starts_open
	_collider.set_deferred("disabled", is_open)
	_panel.rotation.y = -PI / 2 if is_open else 0
	_align_target()
	_update_prompt()


func _stop_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null


func _process(_delta: float) -> void:
	_align_target()


func _align_target() -> void:
	# The ray target follows the visible hinged panel, including while it moves.
	var desired := _panel.transform * Transform3D(Basis.IDENTITY, Vector3(width / 2, height / 2, 0))
	if _target_shape.transform != desired:
		_target_shape.transform = desired
