class_name CrossingVillage
extends RefCounted
## A road settlement with a recognizable stores frontage and a separate crew yard.
const BRICK := preload("res://resources/materials/wall_brick.tres")
const TIMBER := preload("res://resources/materials/floor_wood.tres")
const ROOF := preload("res://resources/materials/roof_metal.tres")
const CONCRETE := preload("res://resources/materials/platform_concrete.tres")
const BOARD := Color("bec2ac")
const GREEN := Color("41594f")
const RED := Color("915347")

static func build(art: JourneyStationArt) -> void:
	var crossing := DetailBuilder.new(art,"RoadCrossing")
	for z in range(-60,63,9):
		if absi(z)>5:
			crossing.box(Vector3(48,.038,z),Vector3(.10,.012,3.2),BOARD)
	for side: float in [-1.,1.]:
		var at := Vector3(48+side*4.,0,side*6.)
		crossing.panel(at+Vector3.UP*.18,Vector3(1.1,.40,1.0),CONCRETE)
		crossing.box(at+Vector3.UP*.81,Vector3(.55,1.0,.6),GREEN)
		var tip := at+Vector3(-side*1.7,5.7,0)
		var pivot := at+Vector3.UP*1.3
		for n in 8:
			crossing.beam(pivot.lerp(tip,n/8.),pivot.lerp(tip,(n+1)/8.),.14,RED if n%2==0 else BOARD)
		crossing.box(Vector3(48,.042,side*9.7),Vector3(5.9,.012,.21),BOARD)
	for z: float in [-1.2,0.,1.2]:
		crossing.panel(Vector3(48,.036,z),Vector3(6.5,.052,.65),TIMBER)
	crossing.signboard(Vector3(53,2.5,12),"BLACKWATER  /  CROSSING",5.2,.60)
	crossing.finish(170.)
	# Chimneys, eaves, entrance steps and glazed sash distinguish the settlement
	# from the flat-roofed iron depot. The existing door opening stays clear.
	_cottage(art,Vector3(12,0,22),Vector3(12,4,10),true,false)
	_cottage(art,Vector3(82,0,38),Vector3(10,4,9),false,false)
	_cottage(art,Vector3(-26,0,41),Vector3(7.6,3.15,7.0),false,true)
	_cottage(art,Vector3(31,0,40),Vector3(7.3,3.2,7.6),false,true)
	_cottage(art,Vector3(107,0,63),Vector3(8.2,3.3,6.9),false,true)
	var stores := DetailBuilder.new(art,"CrossingStoresFront")
	stores.panel(Vector3(168,-.075,54.9),Vector3(14.3,.15,3.2),CONCRETE)
	stores.panel(Vector3(168,3.1,54.2),Vector3(14.4,.16,2.6),ROOF,Vector3(-.12,0,0))
	for x: float in [161.6,174.4]:
		stores.beam(Vector3(x,.0,55.4),Vector3(x,3.12,55.4),.12,GREEN)
		stores.beam(Vector3(x,2.2,55.4),Vector3(x,3.,54.4),.11,GREEN)
	for x: float in [164.,172.]:
		_window(stores,Vector3(x,1.71,53.16),2.75,1.58)
	stores.signboard(Vector3(168,3.78,53.24),"CROSSING STORES",10.2,.66,BOARD)
	stores.signboard(Vector3(164.5,1.17,55.75),"EVACUATION REGISTER",3.6,.42,DetailBuilder.AMBER)
	art.prop("suitcase",Vector3(162.7,.01,54.8),-.22)
	art.prop("suitcase",Vector3(173.4,.01,55.0),.40)
	art.prop("crate",Vector3(173.2,.01,54.45),.13)
	stores.finish(165.)
	art.station.add_structure_collision(Vector3(168,-.075,54.9),Vector3(14.3,.15,3.2))
	var roadside := DetailBuilder.new(art,"SettlementStreet")
	# The footpath links the occupied side of the station, the road and the shop.
	# The planted verge and two breaks in the kerb leave cache approaches clear.
	for x in range(0,181,3):
		if absi(x-48)>5:
			roadside.panel(Vector3(x,.007,53.1),Vector3(2.98,.06,1.75),CONCRETE)
			roadside.panel(Vector3(x,.046,54.04),Vector3(2.98,.12,.18),CONCRETE)
	for z in range(29,53,3):
		roadside.panel(Vector3(12,.007,z),Vector3(1.72,.06,2.98),CONCRETE)
	for x: float in [-35.,-5.,35.,61.,101.,142.]:
		roadside.panel(Vector3(x,.02,61.85),Vector3(2.8,.13,.22),CONCRETE)
	for x in range(-73,181,9):
		if absi(x-48)>7: roadside.box(Vector3(x,-.012,58),Vector3(3.2,.013,.09),BOARD)
	for x: float in [-57.,-10.,72.,134.,178.]:
		roadside.beam(Vector3(x,-.08,62.6),Vector3(x,4.4,62.6),.14,GREEN)
		roadside.beam(Vector3(x,4.35,62.6),Vector3(x,4.35,61.3),.09,GREEN)
		roadside.cylinder(Vector3(x,4.22,61.3),.26,.20,DetailBuilder.INK)
	for edge: float in [-41.,18.,91.]:
		var last := Vector3.ZERO
		for n in 9:
			var p := Vector3(edge+n*1.7,-.06,50.1)
			roadside.panel(p+Vector3.UP*.60,Vector3(.115,1.32,.115),TIMBER,Vector3(0,0,.11 if n==5 else 0.))
			if n>0 and n!=5:
				for h: float in [.32,.85]:
					roadside.beam(last+Vector3.UP*h,p+Vector3.UP*h,.08,GREEN)
			last = p
	roadside.signboard(Vector3(46,2.3,50),"STORES   →",3.2,.58,BOARD)
	roadside.beam(Vector3(46,0,50),Vector3(46,2.7,50),.12,GREEN)
	roadside.finish(145.)
	_van(art,Vector3(38.,0,59.9))
	art.prop("suitcase",Vector3(35.2,-.01,59.5),-.18)
	art.prop("hand_truck",Vector3(34.7,-.02,60.5),.43)
	var utility := DetailBuilder.new(art,"LineCrewHut")
	utility.panel(Vector3(-65,3.7,32),Vector3(11,.23,10),ROOF,Vector3(-.07,0,0))
	utility.signboard(Vector3(-65,2.9,36.8),"TRACK CREW  /  COAL",6.4,.66)
	for x: float in [-71.8,-70.4]:
		utility.cylinder(Vector3(x,.72,33),.54,1.45,DetailBuilder.STEEL)
	utility.finish(145.)

static func _cottage(art: JourneyStationArt, at: Vector3, size: Vector3, station: bool, new_shell: bool) -> void:
	var d := DetailBuilder.new(art,"CrossingHouse")
	if new_shell:
		d.panel(at+Vector3.UP*size.y*.5,size,BRICK)
		art.station.add_structure_collision(at+Vector3.UP*size.y*.5,size)
	var slope := .39
	var span := size.z*.5+.42
	for side: float in [-1.,1.]:
		d.panel(at+Vector3(0,size.y+span*.20,side*span*.5),Vector3(size.x+.90,.18,span/cos(slope)),ROOF,Vector3(side*slope,0,0))
		d.panel(at+Vector3(side*size.x*.34,size.y+.95,-size.z*.24),Vector3(.60,2.0,.64),BRICK)
	var face := at+Vector3(0,0,size.z*.5+.17)
	# Closed triangles beneath both roof slopes meet the outer wall at the eaves.
	for side: float in [-1.,1.]:
		_gable(d,at+Vector3(side*size.x*.5,size.y,0),size.z*.5,span*.40,side)
	for x: float in [-size.x*.3,size.x*.30]:
		_window(d,face+Vector3(x,1.9,.0),1.54,1.55)
	if new_shell:
		d.panel(face+Vector3.UP*1.05,Vector3(1.12,2.1,.09),TIMBER)
		d.box(face+Vector3(.37,.95,.07),Vector3(.1,.08,.07),DetailBuilder.AMBER)
	else:
		d.panel(face+Vector3(0,2.85,.64),Vector3(3.8,.15,1.6),ROOF,Vector3(-.13,0,0))
	if station:
		d.signboard(face+Vector3(0,3.58,.06),"BLACKWATER CROSSING",9.,.66,BOARD)
		EnvironmentArt.place(art,EnvironmentArt.BENCH,face+Vector3(4.1,.01,1.2),"StationBench")
	d.finish(185.)

static func _gable(d: DetailBuilder, center: Vector3, radius: float, rise: float, side: float) -> void:
	var shape := SurfaceTool.new()
	shape.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Vector3 in [Vector3(0,0,side*radius),Vector3(0,rise,0),Vector3(0,0,-side*radius)]:
		shape.set_normal(Vector3.RIGHT*side)
		shape.add_vertex(p)
	d.mesh(shape.commit(),center,Color("746658"))

static func _window(d: DetailBuilder, at: Vector3, width: float, height: float) -> void:
	d.box(at,Vector3(width,height,.075),Color("414f51"))
	for side: float in [-1.,1.]:
		d.box(at+Vector3(side*width*.5,0,.045),Vector3(.085,height+.12,.09),BOARD)
		d.box(at+Vector3(0,side*height*.5,.045),Vector3(width+.15,.08,.09),BOARD)
	d.box(at+Vector3(0,0,.055),Vector3(.054,height,.07),BOARD)
	d.box(at+Vector3(0,.03,.055),Vector3(width,.06,.07),BOARD)

static func _van(art: JourneyStationArt, at: Vector3) -> void:
	var d := DetailBuilder.new(art,"AbandonedDeliveryVan")
	d.panel(at+Vector3(-.6,1.28,0),Vector3(2.9,1.68,1.85),preload("res://resources/materials/environment_painted_steel.tres"))
	d.box(at+Vector3(1.25,.80,0),Vector3(1.55,.76,1.84),GREEN)
	d.box(at+Vector3(1.22,1.45,0),Vector3(1.4,.64,1.71),Color("47575a"))
	d.box(at+Vector3(1.2,1.82,0),Vector3(1.48,.11,1.83),GREEN)
	for side: float in [-1.,1.]:
		d.box(at+Vector3(1.22,1.46,side*.86),Vector3(.085,.67,.07),GREEN)
		d.box(at+Vector3(2.04,.91,side*.59),Vector3(.05,.19,.29),BOARD)
		for x: float in [-1.34,1.39]:
			d.cylinder(at+Vector3(x,.4,side*.85),.40,.23,DetailBuilder.INK,Vector3(PI/2.,0,0))
			d.cylinder(at+Vector3(x,.40,side*.98),.19,.04,DetailBuilder.STEEL,Vector3(PI/2.,0,0))
	d.box(at+Vector3(2.1,.48,0),Vector3(.14,.14,1.97),DetailBuilder.STEEL)
	d.finish(125.)
	art.station.add_structure_collision(at+Vector3(0,1.05,0),Vector3(4.15,1.50,1.85))
