class_name WorkerPose
extends SkeletonModifier3D
## Small visual-only two-bone corrections after authored animation evaluation.
## Contact points live on the supporting body, so a moving train cannot drag feet.

var worker: WorkerAnimator
var contacts: Dictionary = {}
var grip_targets: Dictionary = {}
var rendered_tips: Dictionary = {}
var _chains: Dictionary = {}
var _last_heights: Dictionary = {}
var _grip_weight := 0.0

func configure(owner_rig: WorkerAnimator) -> void:
	worker = owner_rig
	for side in ["Left", "Right"]:
		for kind in ["leg", "arm"]:
			var parts := ["UpLeg", "Leg", "Foot"] if kind == "leg" else ["Arm", "ForeArm", "Hand"]
			var indices: Array[int] = []
			for part in parts:
				indices.append(worker.skeleton.find_bone("mixamorig_" + side + part))
			_chains[side + kind] = indices

func _process_modification() -> void:
	# SceneTree.reload_current_scene detaches the old hierarchy before freeing it.
	# Skeletons can request a final modifier update during that teardown; no
	# world-space contacts may be read once either rig or player has left the tree.
	if not is_inside_tree() or not is_instance_valid(worker) or not is_instance_valid(worker.player) or not worker.player.is_inside_tree() or not worker.is_visible_in_tree():
		return
	var skeleton := get_skeleton()
	if skeleton == null or not skeleton.is_inside_tree():
		return
	var delta := minf(get_process_delta_time(), .05)
	if not worker.first_person:
		_plant_feet(skeleton, delta)
	_align_cargo(skeleton, delta)
	if not worker.player.carrying_heavy:
		_align_interaction(skeleton)
		if not worker.first_person:
			_align_ladder(skeleton)
	# Snapshot the rendered pose before SkeletonModifier3D restores animation
	# state. Diagnostics must measure what the skin sees, not next frame's input.
	for side in ["Left", "Right"]:
		for kind in ["leg", "arm"]:
			rendered_tips[side+kind] = skeleton.to_global(skeleton.get_bone_global_pose(_chains[side+kind][2]).origin)

func _align_interaction(skeleton: Skeleton3D) -> void:
	if worker._action_remaining <= 0 or worker.current_state not in [&"operate", &"pickup"]:
		return
	var progress := 1.0-worker._action_remaining/maxf(worker._action_duration,.001)
	var weight := sin(progress*PI)
	var target := skeleton.to_local(worker.player.get_presentation_focus())
	var pole := skeleton.to_local(worker.to_global(Vector3(-.45,.85,.12)))
	_solve(skeleton,_chains["Rightarm"],target,pole,weight)

func _align_ladder(skeleton: Skeleton3D) -> void:
	var ladder := worker.player.get_traversal_anchor() as Ladder
	if ladder == null or worker.player.state != Player.State.CLIMB:
		return
	contacts.clear()
	for side in ["Left", "Right"]:
		var chain: Array[int] = _chains[side+"arm"]
		var hand := ladder.to_local(skeleton.to_global(skeleton.get_bone_global_pose(chain[2]).origin))
		# Correct the authored alternating reach to actual rung geometry. Preserve
		# the swing between rungs instead of snapping the whole hand every frame.
		var rung := clampf(roundf((hand.y-.22)/Ladder.RUNG_SPACING)*Ladder.RUNG_SPACING+.22,.22,ladder.height-.05)
		var contact_weight := 1.0-smoothstep(.035,.13,absf(hand.y-rung))
		var sign := 1.0 if side == "Left" else -1.0
		var point := ladder.to_global(Vector3(-sign*ladder.width*.32,rung,.12))
		var pole := skeleton.to_local(ladder.to_global(Vector3(-sign*.65,rung-.4,.5)))
		_solve(skeleton,chain,skeleton.to_local(point),pole,contact_weight)

func _plant_feet(skeleton: Skeleton3D, delta: float) -> void:
	var player := worker.player
	if not player.is_grounded() or worker._teleport_cooldown > 0 or player.state in [Player.State.CLIMB, Player.State.VAULT, Player.State.HANG, Player.State.MOUNT]:
		contacts.clear()
		_last_heights.clear()
		return
	for side in ["Left", "Right"]:
		var chain: Array[int] = _chains[side + "leg"]
		var foot := skeleton.to_global(skeleton.get_bone_global_pose(chain[2]).origin)
		var knee := skeleton.to_global(skeleton.get_bone_global_pose(chain[1]).origin)
		var hip := skeleton.to_global(skeleton.get_bone_global_pose(chain[0]).origin)
		var reach := hip.distance_to(knee)+knee.distance_to(foot)-.003
		var query := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * .28, foot - Vector3.UP * .45, 5, [player.get_rid()])
		var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			contacts.erase(side)
			continue
		var clearance: float = foot.y - hit.position.y
		var rising: float = (clearance - float(_last_heights.get(side, clearance))) / maxf(delta, .001)
		_last_heights[side] = clearance
		var stationary := player.get_horizontal_speed() < .15
		var can_plant := stationary or (clearance < .145 and rising < .18)
		if contacts.has(side):
			var contact: Dictionary = contacts[side]
			if not is_instance_valid(contact.body) or contact.body != hit.collider:
				contacts.erase(side)
			else:
				var target: Vector3 = contact.body.to_global(contact.local)
				if (not stationary and clearance > .18 and rising > .1) or hip.distance_to(target) > reach or Vector2(foot.x-target.x,foot.z-target.z).length() > .42:
					contacts.erase(side)
		if not contacts.has(side) and can_plant:
			var target: Vector3 = hit.position + Vector3.UP * .085
			if hip.distance_to(target) <= reach:
				contacts[side] = {"body":hit.collider,"local":hit.collider.to_local(target),"weight":0.0}
		if contacts.has(side):
			var contact: Dictionary = contacts[side]
			contact.weight = move_toward(float(contact.weight), 1.0, delta * 12)
			var sign := 1.0 if side == "Left" else -1.0
			var pole := skeleton.to_local(player.visual.to_global(Vector3(sign*.17,.65,.75)))
			_solve(skeleton, chain, skeleton.to_local(contact.body.to_global(contact.local)), pole, contact.weight)

static func cargo_grip(item: ItemDefinition, left: bool) -> Vector3:
	var width := .27
	var height := .34
	if item.id == &"machine_component":
		width = .29
		height = .32
	elif item.id == &"fuel_drum":
		width = .28
		height = .39
	# Wrist sits behind the side contact; the authored finger arc wraps forward.
	return Vector3(width if left else -width, height, -.11)

func _align_cargo(skeleton: Skeleton3D, delta: float) -> void:
	var cargo := worker.player.carried_visual as WorldItem
	var active_grip := is_instance_valid(cargo) and cargo.held
	_grip_weight = move_toward(_grip_weight, 1.0 if active_grip else 0.0, delta * 8)
	grip_targets.clear()
	if not active_grip:
		return
	for side in ["Left", "Right"]:
		var left: bool = side == "Left"
		var target := cargo.to_global(cargo_grip(cargo.item, left))
		grip_targets[side] = target
		var sign := 1.0 if left else -1.0
		var pole := skeleton.to_local(worker.to_global(Vector3(sign*.5,.75,.05)))
		_solve(skeleton, _chains[side + "arm"], skeleton.to_local(target), pole, _grip_weight)

static func _solve(skeleton: Skeleton3D, chain: Array[int], target: Vector3, pole: Vector3, weight: float) -> void:
	if chain.has(-1) or weight <= 0:
		return
	var a := skeleton.get_bone_global_pose(chain[0]).origin
	var b := skeleton.get_bone_global_pose(chain[1]).origin
	var c := skeleton.get_bone_global_pose(chain[2]).origin
	var tip_rotation := skeleton.get_bone_global_pose(chain[2]).basis.orthonormalized().get_rotation_quaternion()
	var upper := a.distance_to(b)
	var lower := b.distance_to(c)
	var offset := target-a
	var distance := clampf(offset.length(), absf(upper-lower)+.002, upper+lower-.002)
	var axis := offset.normalized()
	var bend := (pole-a) - axis * (pole-a).dot(axis)
	if bend.length_squared() < .00001:
		bend = (b-a) - axis * (b-a).dot(axis)
	if bend.length_squared() < .00001:
		return
	var along := (upper*upper-lower*lower+distance*distance)/(2*distance)
	var elbow := a + axis*along + bend.normalized()*sqrt(maxf(0,upper*upper-along*along))
	_rotate(skeleton,chain[0],b-a,elbow-a,weight)
	b = skeleton.get_bone_global_pose(chain[1]).origin
	c = skeleton.get_bone_global_pose(chain[2]).origin
	_rotate(skeleton,chain[1],c-b,a+axis*distance-b,weight)
	# Moving the elbow/knee must not roll the authored palm or boot with it.
	# Preserve the end effector's animation orientation in skeleton space.
	var current := skeleton.get_bone_global_pose(chain[2]).basis.orthonormalized().get_rotation_quaternion()
	var parent_basis := skeleton.get_bone_global_pose(chain[1]).basis
	var local := parent_basis.inverse()*Basis(current.slerp(tip_rotation,weight))
	skeleton.set_bone_pose_rotation(chain[2],local.orthonormalized().get_rotation_quaternion())

static func _rotate(skeleton: Skeleton3D, index: int, from: Vector3, to: Vector3, weight: float) -> void:
	if from.length_squared() < .00001 or to.length_squared() < .00001:
		return
	var pose := skeleton.get_bone_global_pose(index)
	var rotation := Quaternion.IDENTITY.slerp(Quaternion(from.normalized(),to.normalized()),weight)
	var parent := skeleton.get_bone_parent(index)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var local := parent_basis.inverse()*Basis(rotation)*pose.basis
	skeleton.set_bone_pose_rotation(index,local.orthonormalized().get_rotation_quaternion())
