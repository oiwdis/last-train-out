@tool
class_name Track
extends Node3D
## Visual-only straight railway track: two rails, sleepers and a ballast strip.
##
## Local frame: the track starts at the origin and runs toward +X, with the
## top of the rails at y = [member rail_height]. There is no collision - the
## train is moved by script, and the player simply walks on the ground.

@export var length := 100.0:
	set(value):
		length = maxf(value, 1.0)
		_rebuild()

## Distance between the rail centres.
@export var gauge := 1.5:
	set(value):
		gauge = maxf(value, 0.3)
		_rebuild()

@export var rail_height := 0.1:
	set(value):
		rail_height = maxf(value, 0.02)
		_rebuild()

@export var sleeper_spacing := 0.7:
	set(value):
		sleeper_spacing = maxf(value, 0.2)
		_rebuild()

@export var ballast_width := 2.9:
	set(value):
		ballast_width = maxf(value, 0.0)
		_rebuild()

@export var rail_material: Material:
	set(value):
		rail_material = value
		_rebuild()

@export var sleeper_material: Material:
	set(value):
		sleeper_material = value
		_rebuild()

@export var ballast_material: Material:
	set(value):
		ballast_material = value
		_rebuild()

var _visual_root: Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _visual_root != null:
		_visual_root.queue_free()
	_visual_root = Node3D.new()
	add_child(_visual_root, false, Node.INTERNAL_MODE_BACK)

	if ballast_width > 0.0:
		var ballast := MeshInstance3D.new()
		var ballast_mesh := BoxMesh.new()
		ballast_mesh.size = Vector3(length, 0.02, ballast_width)
		ballast_mesh.material = ballast_material
		ballast.mesh = ballast_mesh
		ballast.position = Vector3(length * 0.5, 0.01, 0.0)
		ballast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual_root.add_child(ballast)

	# A railway rail has a wide foot, narrow web and rounded running head.
	var section := SurfaceTool.new()
	section.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := maxf(rail_height - 0.04, 0.035)
	for profile in [Vector3(0.15, 0.2, 0.1), Vector3(0.025, 0.5, 0.45), Vector3(0.075, 0.3, 0.85)]:
		section.append_from(FabricatedMesh.box(Vector3(length, height * profile.y, profile.x), rail_material), 0,
			Transform3D(Basis.IDENTITY, Vector3(0, 0.04 + height * profile.z, 0)))
	var rail_mesh := section.commit()
	rail_mesh.surface_set_material(0, rail_material)
	for side: float in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.position = Vector3(length * 0.5, 0, side * gauge * 0.5)
		rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual_root.add_child(rail)

	# Sleepers share one draw call through a MultiMesh.
	var count := int(length / sleeper_spacing)
	if count <= 0:
		return
	var sleeper_mesh := BoxMesh.new()
	sleeper_mesh.size = Vector3(0.24, 0.05, gauge + 0.8)
	sleeper_mesh.material = sleeper_material
	var sleeper_poses: Array[Transform3D] = []
	for i in count:
		var x := sleeper_spacing * (float(i) + 0.5)
		sleeper_poses.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.035, 0.0)))
	_instance_sections(sleeper_mesh, sleeper_poses, 100.0)
	# Repeated base plates and fastening bolts share a single draw call.
	var fastener := SurfaceTool.new()
	fastener.begin(Mesh.PRIMITIVE_TRIANGLES)
	var plate := BoxMesh.new()
	plate.size = Vector3(0.19, 0.012, 0.24)
	fastener.append_from(plate, 0, Transform3D.IDENTITY)
	var bolt := CylinderMesh.new()
	bolt.top_radius = 0.016
	bolt.bottom_radius = 0.016
	bolt.height = 0.025
	bolt.radial_segments = 6
	bolt.rings = 1
	for side in [-0.095, 0.095]:
		fastener.append_from(bolt, 0, Transform3D(Basis.IDENTITY, Vector3(0,0.015,side)))
	var fastener_mesh := fastener.commit()
	fastener_mesh.surface_set_material(0, rail_material)
	var plate_poses: Array[Transform3D] = []
	for i in count:
		for side in 2:
			plate_poses.append(Transform3D(Basis.IDENTITY, Vector3(sleeper_spacing*(i+0.5),0.061,(side*2-1)*gauge*0.5)))
	_instance_sections(fastener_mesh, plate_poses, 55.0)


func _instance_sections(mesh: Mesh, poses: Array[Transform3D], distance: float) -> void:
	# A single track-length MultiMesh submits every tiny fastener, including those
	# hundreds of metres away. Local bounds let normal frustum/distance culling work.
	var sections: Dictionary = {}
	for pose in poses:
		var section := floori(pose.origin.x / 20.0)
		if not sections.has(section):
			sections[section] = []
		pose.origin.x -= section * 20.0
		sections[section].append(pose)
	for section: int in sections:
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = mesh
		instances.instance_count = sections[section].size()
		for index in instances.instance_count:
			instances.set_instance_transform(index, sections[section][index])
		var visual := MultiMeshInstance3D.new()
		visual.position.x = section * 20.0
		visual.multimesh = instances
		visual.visibility_range_end = distance
		visual.visibility_range_end_margin = 10.0
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual_root.add_child(visual)
