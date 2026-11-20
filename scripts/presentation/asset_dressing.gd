class_name AssetDressing
extends Node3D
## Licensed authored props replace the blockout visuals; collision and cache locations stay exact.
const ASSETS := {
	"crate": preload("res://assets/props/wooden_crate_01.glb"),
	"military_crate": preload("res://assets/props/wooden_military_crate.glb"),
	"rack": preload("res://assets/props/worn_metal_rack.glb"),
	"shelf": preload("res://assets/props/steel_frame_shelves_02.glb"),
	"barrel": preload("res://assets/props/Barrel_02.glb"),
	"suitcase": preload("res://assets/props/vintage_suitcase.glb"),
	"drill": preload("res://assets/props/drill_press_01.glb"),
	"cart": preload("res://assets/props/industrial_storage_cart.glb"),
	"hand_truck": preload("res://assets/props/hand_truck.glb"),
	"sconce": preload("res://assets/props/industrial_caged_sconce.glb"),
	"pendant": preload("res://assets/props/caged_hanging_light.glb"),
	"oil_can": preload("res://assets/props/small_oil_can_01.glb"),
	"blowtorch": preload("res://assets/props/brass_blowtorch.glb"),
	"torch": preload("res://assets/props/vintage_flashlight.glb"),
}
var instance_count := 0
var _batches: Dictionary = {}

func build(station: Node3D) -> void:
	for part: BoxPart in station.find_children("*", "BoxPart", true, false):
		if part.material != null and part.material.resource_path.contains("crate_"):
			_replace_crate(part)
	for rack: ShelfRack in station.find_children("*", "ShelfRack", true, false):
		rack._visual_root.hide()
		var tall := rack.height > 2.1
		var dimensions := Vector3(0.5933, 2.1416, 0.5024) if tall else Vector3(0.9154, 1.9, 0.6)
		var count := maxi(1, roundi(rack.length / dimensions.x))
		for i in count:
			var local := Transform3D(Basis.IDENTITY.scaled(Vector3(rack.length / count / dimensions.x, rack.height / dimensions.y, rack.depth / dimensions.z)), Vector3(-rack.length / 2 + (i + 0.5) * rack.length / count, 0, 0))
			_batch("shelf" if tall else "rack", global_transform.affine_inverse() * rack.global_transform * local)
	# Authored equipment belongs to existing work surfaces and wall recesses.
	for entry in [
		["suitcase", Vector3(5.4,1.02,2.4), 0.1], ["suitcase", Vector3(12.6,1.02,2.4), -0.3],
		["hand_truck", Vector3(27.3,1.02,2.0), 0.3],
		["cart", Vector3(41.1,0.03,-0.55), 0.0], ["drill", Vector3(41.1,1.41,-0.55), PI/2],
		["blowtorch", Vector3(41.6,1.41,-0.55), 0.1], ["oil_can", Vector3(40.7,1.41,-0.4), 0.3],
		["hand_truck", Vector3(57.5,0.03,4.35), -0.2], ["barrel", Vector3(59.5,0.03,4.3), 0.0],
		["cart", Vector3(76.5,0.03,-0.55), PI], ["drill", Vector3(76.5,1.41,-0.55), 0.4],
		["oil_can", Vector3(76.9,1.41,-0.55), 0.0], ["hand_truck", Vector3(84.0,0.03,4.3), 0.4],
		["barrel", Vector3(99,0.03,-0.6), 0.0], ["barrel", Vector3(99.7,0.03,-0.6), 0.0],
		["cart", Vector3(106,0.03,10.7), 0.1], ["hand_truck", Vector3(119,0.03,10.7), -0.4],
		["military_crate", Vector3(108,0.03,10.8), 0.0], ["military_crate", Vector3(110,0.03,10.8), 0.0],
	]:
		_batch(entry[0], Transform3D(Basis(Vector3.UP, entry[2]), entry[1]))
	for x in [38.0, 46.0, 54.0, 75.0, 83.0, 94.0]:
		_batch("sconce", Transform3D(Basis.IDENTITY, Vector3(x, 2.9, -0.98)))
	for lamp in station.find_children("*", "Node3D", true, false):
		if lamp.scene_file_path.ends_with("hanging_lamp.tscn"):
			for part in lamp.get_children():
				if part is MeshInstance3D:
					part.hide()
			_batch("pendant", global_transform.affine_inverse() * lamp.global_transform * Transform3D(Basis.IDENTITY, Vector3(0,-0.1,0)))
	for old_name in ["SuitcaseA", "SuitcaseB", "DroppedBag", "LuggageCartBed"]:
		var old := station.get_node_or_null("Platform/" + old_name) as Node3D
		if old != null:
			old.hide()
	_flush()

func _replace_crate(part: BoxPart) -> void:
	part.show_mesh = false
	var old := part.get_node_or_null("CrateDetails") as Node3D
	if old != null:
		old.hide()
	var size := part.size
	var nx := maxi(1, roundi(size.x / 0.85))
	var ny := maxi(1, roundi(size.y / 0.36))
	var nz := maxi(1, roundi(size.z / 0.43))
	var scale := Vector3(size.x / nx / 0.82527, size.y / ny / 0.34962, size.z / nz / 0.40895)
	for x in nx:
		for y in ny:
			for z in nz:
				var at := Vector3((x+0.5)*size.x/nx-size.x/2, y*size.y/ny-size.y/2, (z+0.5)*size.z/nz-size.z/2)
				_batch("crate", global_transform.affine_inverse() * part.global_transform * Transform3D(Basis.IDENTITY.scaled(scale), at))

func _batch(asset: String, transform: Transform3D) -> void:
	# Small spatial batches keep visibility bounds local to each hall/platform section.
	var key := "%s:%d" % [asset, floori(transform.origin.x / 20)]
	if not _batches.has(key):
		_batches[key] = {"asset": asset, "origin": Vector3(floorf(transform.origin.x / 20) * 20, 0, 0), "poses": []}
	transform.origin -= _batches[key].origin
	_batches[key].poses.append(transform)
	instance_count += 1

func _flush() -> void:
	for key: String in _batches:
		var batch: Dictionary = _batches[key]
		var template := (ASSETS[batch.asset] as PackedScene).instantiate() as Node3D
		var meshes := template.find_children("*", "MeshInstance3D", true, false)
		if template is MeshInstance3D:
			meshes.append(template)
		for mesh: MeshInstance3D in meshes:
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.mesh = mesh.mesh
			multi.instance_count = batch.poses.size()
			for index in multi.instance_count:
				multi.set_instance_transform(index, batch.poses[index] * mesh.transform)
			var visual := MultiMeshInstance3D.new()
			visual.name = key.replace(":", "_")
			visual.multimesh = multi
			visual.position = batch.origin
			visual.visibility_range_end = 65
			visual.visibility_range_end_margin = 8
			add_child(visual)
		template.free()
	_batches.clear()

static func place(parent: Node3D, asset: String, at: Vector3, scale := Vector3.ONE, yaw := 0.0) -> Node3D:
	var prop := (ASSETS[asset] as PackedScene).instantiate() as Node3D
	prop.position = at
	prop.scale = scale
	prop.rotation.y = yaw
	parent.add_child(prop)
	return prop
