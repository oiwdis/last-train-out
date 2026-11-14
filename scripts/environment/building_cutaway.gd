class_name BuildingCutaway
extends Area3D
## Fades a building's camera-facing wall while the player is inside.
##
## Put the Area3D's shape around the interior and list the wall nodes in
## [member cutaway_roots]. Every MeshInstance3D below those nodes fades out with
## a cheap alpha blend and is then hidden outright, so no transparency is
## rendered once the transition is over. Collision is untouched: the wall still
## blocks movement. Each building owns its own cutaway, so several buildings
## work independently.

signal revealed
signal concealed

const PLAYER_LAYER := 1 << 1

## Nodes whose visuals are cut away (typically the front wall and its windows).
@export var cutaway_roots: Array[NodePath] = []
@export var fade_time := 0.35
## Keep the hidden wall casting shadows so the interior lighting does not change.
@export var keep_shadows := true

var _occupants := 0
## 0 = wall fully visible, 1 = fully cut away.
var _fade := 0.0
var _target := 0.0
var _meshes: Array[MeshInstance3D] = []
var _fade_materials: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_collect.call_deferred()
	set_process(false)


func _process(delta: float) -> void:
	var step := delta / maxf(fade_time, 0.01)
	_fade = move_toward(_fade, _target, step)
	_apply_fade()
	if is_equal_approx(_fade, _target):
		set_process(false)
		if _target >= 1.0:
			revealed.emit()
		else:
			concealed.emit()


func is_cut_away() -> bool:
	return _target >= 1.0


## 0 = wall fully visible, 1 = fully cut away.
func get_fade() -> float:
	return _fade


## Restores the wall immediately (used when the station is reset).
func reset_state() -> void:
	_occupants = 0
	for body in get_overlapping_bodies():
		if body.is_in_group(&"player"):
			_occupants += 1
	_target = 1.0 if _occupants > 0 else 0.0
	_fade = _target
	_apply_fade()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	_occupants += 1
	_set_target(1.0)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	_occupants = maxi(_occupants - 1, 0)
	if _occupants == 0:
		_set_target(0.0)


func _set_target(value: float) -> void:
	_target = value
	set_process(true)


func _collect() -> void:
	_meshes.clear()
	for path in cutaway_roots:
		var root := get_node_or_null(path)
		if root != null:
			_collect_meshes(root)
	for mesh_instance in _meshes:
		if keep_shadows and mesh_instance.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			# A permanent shadow-only twin keeps the lighting stable while the
			# visible mesh fades. It is a sibling, not a child, so hiding the
			# mesh does not hide it.
			var proxy := MeshInstance3D.new()
			proxy.mesh = mesh_instance.mesh
			proxy.transform = mesh_instance.transform
			proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			mesh_instance.get_parent().add_child(proxy, false, Node.INTERNAL_MODE_BACK)
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply_fade()


func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_meshes.append(node)
	for child in node.get_children(true):
		_collect_meshes(child)


func _apply_fade() -> void:
	for mesh_instance in _meshes:
		if not is_instance_valid(mesh_instance):
			continue
		if _fade <= 0.0:
			mesh_instance.material_override = null
			mesh_instance.visible = true
		elif _fade >= 1.0:
			mesh_instance.material_override = null
			mesh_instance.visible = false
		else:
			var fade_material := _get_fade_material(mesh_instance)
			if fade_material != null:
				fade_material.albedo_color.a = 1.0 - _fade
				mesh_instance.material_override = fade_material
			mesh_instance.visible = true


func _get_fade_material(mesh_instance: MeshInstance3D) -> BaseMaterial3D:
	var source := mesh_instance.get_active_material(0) if mesh_instance.material_override == null else null
	if source == null:
		# Already overridden by one of our fade materials.
		return mesh_instance.material_override as BaseMaterial3D
	if not _fade_materials.has(source):
		var copy := source.duplicate() as BaseMaterial3D
		if copy == null:
			return null
		copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fade_materials[source] = copy
	return _fade_materials[source]
