class_name DetailBuilder
extends RefCounted
## Collision-free art, batched by material within each independently cuttable part.
## StandardMaterial3D and MeshInstance3D deliberately use the existing wall fade.

const INK := Color("17282f")
const STEEL := Color("405862")
const PALE := Color("bbc6be")
const AMBER := Color("e9ab59")
const RUST := Color("815044")

var root: Node3D
var _batches: Dictionary = {}
var _materials: Dictionary = {}
var _unit_box: Mesh


func _init(parent: Node3D, title: String = "Details") -> void:
	_unit_box = FabricatedMesh.unit_box()
	root = Node3D.new()
	root.name = title
	root.add_to_group(&"presentation_detail")
	parent.add_child(root)


func material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s/%s" % [color.to_html(), emission]
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.82
		if emission > 0.0:
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = emission
		_materials[key] = mat
	return _materials[key]


func box(at: Vector3, size: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> void:
	var mat := material(color)
	if not _batches.has(mat):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[mat] = surface
	var transform := Transform3D(Basis.from_euler(rotation).scaled_local(size), at)
	(_batches[mat] as SurfaceTool).append_from(_unit_box, 0, transform)


func beam(a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var middle := (a + b) * 0.5
	var direction := b - a
	# All structural braces lie in XY or XZ; look_at handles both without scale tricks.
	var mat := material(color)
	if not _batches.has(mat):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[mat] = surface
	var basis := Basis.looking_at(direction.normalized(), Vector3.UP if absf(direction.normalized().y) < 0.99 else Vector3.RIGHT)
	(_batches[mat] as SurfaceTool).append_from(_unit_box, 0,
		Transform3D(basis.scaled_local(Vector3(width, width, direction.length())), middle))


func mesh(shape: Mesh, at: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO, emission: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	# Put material on the mesh, not an override: CutawayWall owns temporary overrides.
	shape.surface_set_material(0, material(color, emission))
	instance.mesh = shape
	instance.position = at
	instance.rotation = rotation
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)
	return instance


func cylinder(at: Vector3, radius: float, height: float, color: Color, rotation: Vector3 = Vector3.ZERO, top: float = -1.0) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius if top < 0.0 else top
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 12
	shape.rings = 1
	var mat := material(color)
	if not _batches.has(mat):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[mat] = surface
	(_batches[mat] as SurfaceTool).append_from(shape, 0, Transform3D(Basis.from_euler(rotation), at))


func lettering(at: Vector3, text: String, height: float, color: Color = PALE) -> MeshInstance3D:
	var shape := TextMesh.new()
	shape.text = text
	shape.font = ThemeDB.fallback_font
	shape.font_size = 64
	shape.pixel_size = height / 64.0
	shape.depth = 0.0
	return mesh(shape, at, color, Vector3.ZERO, 0.25)


func signboard(at: Vector3, text: String, width: float, height: float = 0.65, color: Color = AMBER) -> void:
	box(at, Vector3(width, height, 0.06), INK)
	box(at + Vector3(0, -height * 0.46, 0.04), Vector3(width, 0.025, 0.02), color)
	lettering(at + Vector3(0, -height * 0.05, 0.04), text, height * 0.43, color)


func finish() -> void:
	for mat: Material in _batches:
		var shape := (_batches[mat] as SurfaceTool).commit()
		shape.surface_set_material(0, mat)
		var instance := MeshInstance3D.new()
		instance.mesh = shape
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(instance)
	_batches.clear()
