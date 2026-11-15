class_name SupplyInteractable
extends Interactable
## Supplies use the existing interaction query, with explicit reach and occlusion checks.

var action: Callable
@export var reach := 1.65


func _ready() -> void:
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.85
	collider.shape = sphere
	collider.position.y = 0.65
	add_child(collider)
	super._ready()
	# Supply use has no relative-speed gate. Parent transforms already update its area.
	set_physics_process(false)


func can_interact(player: Player) -> bool:
	return enabled and is_reachable(player)


func is_reachable(player: Player) -> bool:
	var offset := global_position - player.global_position
	if absf(offset.y) > 1.1 or Vector2(offset.x, offset.z).length() > reach:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.85,
		global_position + Vector3.UP * 0.65, 5, [player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func interact(player: Player) -> bool:
	return bool(action.call(player)) if action.is_valid() and can_interact(player) else false
