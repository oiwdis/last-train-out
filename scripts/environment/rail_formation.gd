class_name RailFormation
extends RefCounted
## A metre-scaled rail profile swept through the same frames as the running gear.

const WEB := preload("res://resources/materials/rail_web.tres")
const BALLAST := preload("res://resources/materials/ballast.tres")

static func running_rails(frames: Array[Transform3D], start: float, step: float, gauge: float, height: float, head: Material) -> ArrayMesh:
	var foot := maxf(.012, height - .058)
	var profile := PackedVector2Array([
		Vector2(-.073,foot), Vector2(-.073,foot+.009), Vector2(-.014,foot+.016),
		Vector2(-.014,height-.024), Vector2(-.035,height-.021), Vector2(-.038,height-.007),
		Vector2(-.029,height), Vector2(.029,height), Vector2(.038,height-.007),
		Vector2(.035,height-.021), Vector2(.014,height-.024), Vector2(.014,foot+.016),
		Vector2(.073,foot+.009), Vector2(.073,foot)])
	var surfaces: Array[SurfaceTool] = [SurfaceTool.new(), SurfaceTool.new()]
	for surface in surfaces:
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var offsets := PackedInt32Array([0,0])
	for side: float in [-gauge * .5, gauge * .5]:
		for edge in profile.size()-1:
			var polished := edge >= 5 and edge <= 7
			var group := int(polished)
			_strip(surfaces[group], offsets[group], frames, start, step, profile[edge]+Vector2(side,0), profile[edge+1]+Vector2(side,0))
			offsets[group] += frames.size()*2
	var rails := ArrayMesh.new()
	for i in surfaces.size():
		surfaces[i].set_material(head if i == 1 else WEB)
		surfaces[i].commit(rails)
	return rails

static func ballast(frames: Array[Transform3D], start: float, step: float, width: float, material: Material) -> ArrayMesh:
	var profile := PackedVector2Array([Vector2(-width*.62,-.12),Vector2(-width*.46,.026),
		Vector2(width*.46,.026),Vector2(width*.62,-.12)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge in profile.size()-1:
		_strip(surface, edge*frames.size()*2, frames,start,step,profile[edge],profile[edge+1])
	surface.set_material(FabricatedMesh.planar_material(material))
	return surface.commit()

static func _strip(surface: SurfaceTool, first: int, frames: Array[Transform3D], start: float, step: float, a: Vector2, b: Vector2) -> void:
	var slope := b-a
	var normal := Vector3(0,slope.x,-slope.y).normalized()
	for i in frames.size():
		var frame := frames[i]
		for p: Vector2 in [a,b]:
			surface.set_normal(frame.basis * normal)
			var tangent := frame.basis.x
			surface.set_tangent(Plane(tangent,1))
			surface.set_uv(Vector2((start+i*step)*.8,p.x*.8))
			surface.add_vertex(frame * Vector3(0,p.y,p.x))
		if i > 0:
			var base := first + (i-1)*2
			for offset in [0,2,1,1,2,3]:
				surface.add_index(base+offset)
