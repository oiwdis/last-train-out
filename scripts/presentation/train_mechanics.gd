class_name TrainMechanics
extends Node3D
## Visual mechanism only. Reads Train, never applies forces or changes controls.
## Axle positions measured from the adapted Schuller model, in car-local metres.
const AXLES := [-.468, .754, 2.005]
const WHEEL_RADIUS := .606
const AXLE_HEIGHT := Track.STANDARD_RAIL_HEIGHT + WHEEL_RADIUS
const ROD_PLANE := Track.STANDARD_GAUGE/2 + .1
const CRANK_RADIUS := .24
const CONNECTING_LENGTH := 2.25
var rods: Array[Dictionary] = []
var gauges: Array[Node3D] = []
var gauge_values := Vector3.ZERO

func _ready() -> void:
	var metal := preload("res://resources/materials/metal_dark.tres").duplicate() as StandardMaterial3D
	metal.albedo_color = Color("8c9897")
	metal.roughness = .4
	for side in [-1.0,1.0]:
		for axle in 2:
			rods.append({"side":side,"axle":axle,"mesh":_rod(AXLES[axle+1]-AXLES[axle],metal)})
		rods.append({"side":side,"axle":2,"mesh":_rod(CONNECTING_LENGTH,metal)})
		var slide := MeshInstance3D.new()
		slide.mesh = FabricatedMesh.box(Vector3(.17,.13,.12),metal)
		add_child(slide)
		rods.append({"side":side,"axle":3,"mesh":slide})
	for index in 3:
		var pivot := Node3D.new()
		pivot.name = ["SpeedNeedle","RegulatorNeedle","BrakeNeedle"][index]
		pivot.position = Vector3(-1.712,2.52,(index-1)*.63)
		add_child(pivot)
		var needle := MeshInstance3D.new()
		needle.mesh = FabricatedMesh.box(Vector3(.009,.095,.007),preload("res://resources/materials/metal_dark.tres"))
		needle.position.y = .039
		pivot.add_child(needle)
		gauges.append(pivot)
		var label := Label3D.new()
		label.text = ["km/h\n0       144","REGULATOR\n0       100%","BRAKE\n0       100%"][index]
		label.font_size = 32
		label.pixel_size = .00065
		label.outline_size = 0
		label.modulate = Color("242b2b")
		label.no_depth_test = false
		label.shaded = true
		label.position = pivot.position+Vector3(-.004,-.045,0)
		label.rotation.y = -PI/2
		add_child(label)
	update_mechanism(0,null)

func _rod(length: float, material: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(FabricatedMesh.planar_material(material))
	surface.append_from(FabricatedMesh.box(Vector3(length,.052,.035),material),0,Transform3D.IDENTITY)
	var bearing := CylinderMesh.new()
	bearing.top_radius = .066
	bearing.bottom_radius = .066
	bearing.height = .052
	bearing.radial_segments = 20
	bearing.rings = 1
	var cap := CylinderMesh.new()
	cap.top_radius = .028
	cap.bottom_radius = .028
	cap.height = .075
	cap.radial_segments = 6
	cap.rings = 1
	for sign in [-1.0,1.0]:
		var transform := Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(sign*length*.5,0,0))
		surface.append_from(bearing,0,transform)
		surface.append_from(cap,0,transform)
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	add_child(mesh)
	return mesh

static func crank(phase: float, side: float, axle: int) -> Vector3:
	# Quartering prevents both cylinders reaching dead centre simultaneously.
	var angle: float = -phase/WHEEL_RADIUS + (PI/2 if side>0 else 0)
	return Vector3(AXLES[axle]+cos(angle)*CRANK_RADIUS,AXLE_HEIGHT+sin(angle)*CRANK_RADIUS,side*ROD_PLANE)

static func crosshead(pin: Vector3) -> Vector3:
	var offset := pin.y-AXLE_HEIGHT
	return Vector3(pin.x+sqrt(CONNECTING_LENGTH*CONNECTING_LENGTH-offset*offset),AXLE_HEIGHT,pin.z)

func update_mechanism(phase: float, train: Train) -> void:
	for entry in rods:
		var start := crank(phase,entry.side,entry.axle if entry.axle<2 else 1)
		var end := crank(phase,entry.side,entry.axle+1) if entry.axle<2 else crosshead(start)
		if entry.axle>=2:
			start.z += entry.side*.075
			end.z += entry.side*.075
		var mesh := entry.mesh as MeshInstance3D
		mesh.position = end if entry.axle==3 else (start+end)*.5
		mesh.rotation.z = 0 if entry.axle==3 else atan2(end.y-start.y,end.x-start.x)
	if train == null:
		return
	# Existing gameplay exposes speed and regulator/brake states, not pressure.
	gauge_values = Vector3(clampf(train.speed/40.0,0,1),1 if train.state in [Train.State.ACCELERATING,Train.State.CRUISING] else 0,1 if train.state in [Train.State.BRAKING,Train.State.STOPPED] else 0)
	for index in 3:
		gauges[index].rotation.x = deg_to_rad(-130.0+260.0*gauge_values[index])
