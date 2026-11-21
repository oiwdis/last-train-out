class_name RouteLandscape
extends RefCounted
## Cross sections share their exact rim at adjoining chunks. Outside the
## track shoulder they run north/south, so wide terrain cannot fold on a bend.
const OFFSETS := [-440.,-250.,-150.,-85.,-46.,-24.,-13.,-8.,-5.,-3.5,-2.,0.,2.,3.5,5.,8.,13.,24.,46.,85.,150.,250.,440.]
const MATERIAL := preload("res://resources/materials/railway_verge.tres")

static func yard_weight(route: FogRoute, progress: float, offset: float) -> float:
	# Harlow's original working yard and the two station aprons have their own
	# authored floors. Lower the landscape under those footprints only.
	var harlow := _rectangle(progress,offset,-105.,170.,-23.,29.)
	var depot := _rectangle(progress-float(route.stations.ashford),offset,-160.,260.,-67.,103.)
	var crossing := _rectangle(progress-float(route.stations.blackwater),offset,-160.,260.,-67.,103.)
	return maxf(harlow,maxf(depot,crossing))

static func _rectangle(x: float, z: float, x0: float, x1: float, z0: float, z1: float) -> float:
	var outside := maxf(maxf(x0-x,x-x1), maxf(z0-z,z-z1))
	return 1.-smoothstep(0.,18.,outside)

static func height(progress: float, offset: float, yard: float) -> float:
	var width := absf(offset)
	var shoulder := smoothstep(1.4,3.5,width)
	var ditch := exp(-pow((width-5.0)/2.65,2.0))
	var meadow := smoothstep(5.,29.,width)
	var hill := sin(progress*.012+offset*.032)*.85 + sin(progress*.039-offset*.053)*.36
	var ridge := smoothstep(19.,155.,width)*(3.5+5.*sin(progress*.0065+offset*.021)+3.2*sin(progress*.004-offset*.046))
	var field := -.07 - .74*shoulder - .81*ditch + meadow*(hill+ridge)
	return lerpf(field,-.11,yard)

static func point(frame: Transform3D, progress: float, offset: float, route: FogRoute) -> Vector3:
	var near_offset := clampf(offset,-18.,18.)
	var p := frame.origin + frame.basis.z*near_offset + Vector3.BACK*(offset-near_offset)
	p.y += height(progress,offset,yard_weight(route,progress,offset))
	return p

static func build(frames: Array[Transform3D], start: int, step: int, route: FogRoute) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var tangents := PackedFloat32Array()
	var indices := PackedInt32Array()
	var columns := OFFSETS.size()
	for i in frames.size():
		var along := float(start+i*step)
		for j in columns:
			var side: float = OFFSETS[j]
			var vertex := point(frames[i],along,side,route)
			vertices.append(vertex)
			uvs.append(Vector2(vertex.x,vertex.z)/12.)
			var v := .86 + .075*sin(along*.022+side*.047) + .055*cos(side*.105-along*.013)
			var wet := exp(-pow((absf(side)-5.)/2.5,2.))
			colors.append(Color(v,v*.985,v*.91).lerp(Color(.47,.45,.38),wet*.65))
			var dy := height(along+1.,side,yard_weight(route,along+1.,side))-height(along-1.,side,yard_weight(route,along-1.,side))
			var across := point(frames[i],along,side+1.,route)-point(frames[i],along,side-1.,route)
			var forward := frames[i].basis.x + Vector3.UP*dy*.5
			normals.append(across.cross(forward).normalized())
			var t := forward.normalized()
			tangents.append_array(PackedFloat32Array([t.x,t.y,t.z,1.]))
			if i+1 < frames.size() and j+1 < columns:
				var k := i*columns+j
				indices.append_array(PackedInt32Array([k,k+columns,k+1,k+1,k+columns,k+columns+1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,MATERIAL)
	return mesh
