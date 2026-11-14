class_name CutawayWall
extends StaticBody3D
## A wall that can be cut away so the camera sees past it.
##
## [CutawayTrigger] volumes request the cut while the player is inside them;
## the wall fades out when at least one request is active and fades back when
## none are left. Several triggers may share a wall (for example "player is
## inside the building" and "player is passing behind the building").
##
## Only the visuals change: every MeshInstance3D below this node fades with a
## cheap alpha blend and is then hidden outright, so nothing transparent is
## drawn once the transition is over. Collision stays active.

signal cut_away_changed(is_cut: bool)

@export var fade_time := 0.35
## Keep the hidden wall casting shadows so the interior lighting does not change.
@export var keep_shadows := true

var _requests: Dictionary = {}
## 0 = fully visible, 1 = fully cut away.
var _fade := 0.0
var _target := 0.0
var _meshes: Array[MeshInstance3D] = []
var _fade_materials: Dictionary = {}
var _source_alpha: Dictionary = {}


func _ready() -> void:
	add_to_group(&"station_resettable")
	set_process(false)
	_collect.call_deferred()


func _process(delta: float) -> void:
	_fade = move_toward(_fade, _target, delta / maxf(fade_time, 0.01))
	_apply_fade()
	if is_equal_approx(_fade, _target):
		set_process(false)


## Asks for the wall to be cut away. [param key] identifies the requester.
func request_cut(key: Object) -> void:
	_requests[key.get_instance_id()] = true
	_update_target()


func release_cut(key: Object) -> void:
	_requests.erase(key.get_instance_id())
	_update_target()


func is_cut_away() -> bool:
	return _target >= 1.0


## 0 = fully visible, 1 = fully cut away.
func get_fade() -> float:
	return _fade


## Jumps straight to the wanted state (used when the station is reset).
func reset_state() -> void:
	_fade = _target
	_apply_fade()
	set_process(false)


func _update_target() -> void:
	var wanted := 1.0 if not _requests.is_empty() else 0.0
	if is_equal_approx(wanted, _target):
		return
	_target = wanted
	set_process(true)
	cut_away_changed.emit(_target >= 1.0)


func _collect() -> void:
	_meshes.clear()
	_collect_meshes(self)
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
				fade_material.albedo_color.a = _source_alpha.get(fade_material, 1.0) * (1.0 - _fade)
				mesh_instance.material_override = fade_material
			mesh_instance.visible = true


func _get_fade_material(mesh_instance: MeshInstance3D) -> BaseMaterial3D:
	if mesh_instance.material_override != null:
		return mesh_instance.material_override as BaseMaterial3D
	var source := mesh_instance.get_active_material(0) as BaseMaterial3D
	if source == null:
		return null
	if not _fade_materials.has(source):
		var copy := source.duplicate() as BaseMaterial3D
		copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fade_materials[source] = copy
		_source_alpha[copy] = source.albedo_color.a
	return _fade_materials[source]
