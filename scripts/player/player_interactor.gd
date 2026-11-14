class_name PlayerInteractor
extends Node
## Contextual-interaction sensing for the player.
##
## * [Interactable] areas (ladders, railings, ...) are found with a shape query.
## * Vaultable / climbable geometry is found with raycasts plus capsule
##   clearance checks, so any low obstacle works without per-object setup.

const SCAN_STEP := 0.15
const FACE_INSET := 0.1

@export_flags_3d_physics var interactable_mask := 1 << 3
## Geometry that can be vaulted and that blocks the player (world + train).
@export_flags_3d_physics var obstacle_mask := (1 << 0) | (1 << 2)
@export var probe_radius := 0.5
@export var probe_height := 1.9

var _player: Player
var _probe_shape := CapsuleShape3D.new()
var _fit_shape := CapsuleShape3D.new()
var _ground_shape := SphereShape3D.new()


func setup(player: Player) -> void:
	_player = player
	_probe_shape.radius = probe_radius
	_probe_shape.height = probe_height
	_fit_shape.radius = maxf(player.get_body_radius() - 0.04, 0.05)
	_fit_shape.height = maxf(player.get_body_height() - 0.12, _fit_shape.radius * 2.0)


## Best interactable the player is currently able to use, or null.
func find_interactable(excluded: Interactable = null) -> Interactable:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _probe_shape
	query.transform = Transform3D(Basis.IDENTITY, _player.global_position + Vector3.UP * (probe_height * 0.5))
	query.collision_mask = interactable_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var best: Interactable = null
	var best_distance := INF
	for result: Dictionary in _space().intersect_shape(query, 8):
		var candidate := result.get("collider") as Interactable
		if candidate == null or candidate == excluded or not candidate.can_interact(_player):
			continue
		var distance := candidate.get_interaction_distance(_player)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


## Looks for a low obstacle in [param direction] that can be vaulted over or
## climbed onto. Returns an empty Dictionary when there is none, otherwise:
## [code]{ kind: "over" | "onto", end: Vector3, top_y: float, into: Vector3, collider: Object }[/code]
func find_vault(direction: Vector3) -> Dictionary:
	var cfg := _player.config
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return {}
	direction = direction.normalized()
	var feet := _player.global_position
	var radius := _player.get_body_radius()

	# 1. Find a vertical face in front of the player.
	var hit := {}
	for probe: float in [cfg.vault_min_height * 0.9, cfg.vault_min_height + 0.4]:
		var from := feet + Vector3.UP * probe
		hit = _ray(from, from + direction * (radius + cfg.vault_reach))
		if not hit.is_empty():
			break
	if hit.is_empty():
		return {}
	var normal: Vector3 = hit["normal"]
	if absf(normal.y) > 0.35:
		return {}
	var into := Vector3(-normal.x, 0.0, -normal.z).normalized()
	if into.dot(direction) < 0.5:
		return {}
	var face: Vector3 = hit["position"]

	# 2. Find the top of the obstacle just behind that face.
	var scan_top := feet.y + cfg.vault_max_height + 0.3
	var behind := face + into * FACE_INSET
	var top := _ray(Vector3(behind.x, scan_top, behind.z), Vector3(behind.x, feet.y + cfg.vault_min_height, behind.z))
	if top.is_empty() or (top["normal"] as Vector3).y < 0.7:
		return {}
	var top_y: float = (top["position"] as Vector3).y
	if top_y - feet.y > cfg.vault_max_height:
		return {}

	# 3. Measure how deep the obstacle is: thin ones are vaulted over.
	var far_edge := -1.0
	var distance := FACE_INSET + SCAN_STEP
	while distance <= cfg.vault_max_depth + FACE_INSET:
		var p := face + into * distance
		var sample := _ray(Vector3(p.x, scan_top, p.z), Vector3(p.x, top_y - 0.3, p.z))
		if sample.is_empty():
			far_edge = distance
			break
		if (sample["position"] as Vector3).y > top_y + 0.25:
			break  # The obstacle steps up: treat as a ledge to climb, not vault.
		distance += SCAN_STEP

	if far_edge > 0.0:
		var land := face + into * (far_edge + radius + 0.1)
		var ground := _ray(Vector3(land.x, top_y + 0.1, land.z), Vector3(land.x, feet.y - cfg.vault_max_drop, land.z))
		if not ground.is_empty() and (ground["normal"] as Vector3).y > 0.7:
			var end := Vector3(land.x, (ground["position"] as Vector3).y + 0.03, land.z)
			var mid := face + into * (far_edge * 0.5)
			mid.y = top_y + 0.05
			if capsule_fits(end) and capsule_fits(mid):
				return {"kind": "over", "end": end, "top_y": top_y, "into": into, "collider": hit["collider"]}

	# 4. Otherwise climb onto it, if there is room to stand.
	var stand := face + into * (radius + 0.12)
	stand.y = top_y + 0.03
	if capsule_fits(stand):
		return {"kind": "onto", "end": stand, "top_y": top_y, "into": into, "collider": hit["collider"]}
	return {}


## Whether the player's body fits with its feet at [param feet] (world space).
func capsule_fits(feet: Vector3, exclude: Array[RID] = []) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _fit_shape
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * (_fit_shape.height * 0.5 + 0.07))
	query.collision_mask = obstacle_mask
	var excluded: Array[RID] = [_player.get_rid()]
	excluded.append_array(exclude)
	query.exclude = excluded
	return _space().intersect_shape(query, 1).is_empty()


## The body under the player's feet, or null. [param prefer_moving] breaks the
## tie when the player straddles two bodies (platform edge next to the train).
func probe_ground(prefer_moving: bool = false) -> Node3D:
	var radius := _player.get_body_radius() * 0.9
	var query := PhysicsShapeQueryParameters3D.new()
	_ground_shape.radius = radius
	query.shape = _ground_shape
	query.transform = Transform3D(Basis.IDENTITY, _player.global_position + Vector3.UP * (radius - 0.1))
	query.collision_mask = obstacle_mask
	query.exclude = [_player.get_rid()]
	var fallback: Node3D = null
	for result: Dictionary in _space().intersect_shape(query, 4):
		var body := result.get("collider") as Node3D
		if body == null:
			continue
		if (body is AnimatableBody3D) == prefer_moving:
			return body
		if fallback == null:
			fallback = body
	return fallback


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, obstacle_mask, [_player.get_rid()])
	return _space().intersect_ray(query)


func _space() -> PhysicsDirectSpaceState3D:
	return _player.get_world_3d().direct_space_state
