class_name DepotYard
extends RefCounted
## Freight arrives under the overhead runner, passes the coal screens and exits
## the loading bays. Keep the platform, door centerlines and coal caches clear.
const RUST := Color("724635")
const FRAME := Color("3d4a48")
const PAINT := Color("b49653")
const CONCRETE := preload("res://resources/materials/platform_concrete.tres")
const CORRUGATED := preload("res://resources/materials/roof_metal.tres")
const TIMBER := preload("res://resources/materials/floor_wood.tres")

static func build(art: JourneyStationArt) -> void:
	var bay := DetailBuilder.new(art,"FreightLoadingBays")
	for x: float in [13.,31.]:
		bay.panel(Vector3(x,.49,33.6),Vector3(6.6,.98,3.9),CONCRETE)
		art.solid(Vector3(x,.49,33.6),Vector3(6.6,.98,3.9))
		bay.panel(Vector3(x,4.65,32.6),Vector3(8.1,.13,5.7),CORRUGATED,Vector3(-.09,0,0))
		for side: float in [-2.95,2.95]:
			var foot := Vector3(x+side,1.,35.1)
			bay.beam(foot,foot+Vector3.UP*3.7,.16,FRAME)
			bay.beam(foot+Vector3.UP*2.9,foot+Vector3(0,3.6,-1.1),.13,RUST)
			bay.box(foot+Vector3(0,.50,.1),Vector3(.19,.38,.08),PAINT)
		for offset: float in [-2.1,-.8,.5]:
			art.prop("crate",Vector3(x+offset,1.,33.8),offset*.04)
		art.prop("military_crate",Vector3(x-1.45,1.63,33.7),.03)
	bay.signboard(Vector3(22,4.4,31.24),"CONSIGNMENTS  /  02",8.,.7)
	bay.finish(175.)
	var tip := DetailBuilder.new(art,"CoalTipple")
	for x: float in [-5.,3.]:
		# Riveted elevated screens, a discharge neck and cross-braced legs.
		var center := Vector3(x,0,-14.)
		for dx: float in [-1.8,1.8]:
			for dz: float in [-1.9,1.9]:
				tip.beam(center+Vector3(dx,0,dz),center+Vector3(dx,9.,dz),.22,FRAME)
				art.solid(center+Vector3(dx,4.5,dz),Vector3(.22,9.,.22))
		tip.beam(center+Vector3(-1.8,.3,1.9),center+Vector3(1.8,5.8,1.9),.15,RUST)
		tip.beam(center+Vector3(1.8,.3,1.9),center+Vector3(-1.8,5.8,1.9),.15,RUST)
		tip.cylinder(center+Vector3.UP*6.4,1.0,2.8,RUST,Vector3.ZERO,2.55)
		tip.cylinder(center+Vector3.UP*8.6,2.55,1.8,FRAME)
		tip.cylinder(center+Vector3.UP*9.85,2.62,.75,RUST,Vector3.ZERO,.38)
		tip.box(center+Vector3.UP*4.7,Vector3(1.4,.75,1.4),DetailBuilder.INK)
		for ring: float in [7.95,9.15]:
			tip.cylinder(center+Vector3.UP*ring,2.61,.08,PAINT)
	var a := Vector3(-19,2.,-14)
	var b := Vector3(-4,9.1,-14)
	for z: float in [-.82,.82]:
		var side := Vector3.BACK*z
		tip.beam(a+side,b+side,.18,RUST)
		tip.beam(a+side+Vector3.UP*1.1,b+side+Vector3.UP*1.1,.13,FRAME)
		for n in 9:
			var t := n/9.
			tip.beam(a.lerp(b,t)+side,a.lerp(b,(n+1)/9.)+side+Vector3.UP*1.1,.09,FRAME)
	tip.beam(a,b,1.0,DetailBuilder.INK)
	tip.finish(240.)
	var runner := DetailBuilder.new(art,"TransferGantry")
	for x: float in [42.,68.]:
		for z: float in [15.,28.]:
			runner.beam(Vector3(x,0,z),Vector3(x,8.6,z),.34,FRAME)
			art.solid(Vector3(x,4.3,z),Vector3(.34,8.6,.34))
			runner.beam(Vector3(x,.2,z+1.7),Vector3(x,3.2,z),.18,RUST)
			runner.panel(Vector3(x,.23,z),Vector3(1.4,.46,1.4),CONCRETE)
		runner.beam(Vector3(x,8.55,14.),Vector3(x,8.55,29.),.50,FRAME)
	for z: float in [16.,27.]:
		runner.beam(Vector3(40,8.9,z),Vector3(70,8.9,z),.24,RUST)
		runner.beam(Vector3(40,10.2,z),Vector3(70,10.2,z),.20,FRAME)
		for n in 10:
			runner.beam(Vector3(40+n*3,8.9,z),Vector3(43+n*3,10.2,z),.15,FRAME)
	runner.box(Vector3(50,9.4,21.5),Vector3(2.1,1.1,11.4),PAINT)
	runner.beam(Vector3(50,9.,21.5),Vector3(50,4.0,21.5),.065,DetailBuilder.INK)
	runner.box(Vector3(50,4.,21.5),Vector3(.52,.46,.42),RUST)
	runner.finish(230.)
	var work := DetailBuilder.new(art,"WorkshopFittings")
	work.panel(Vector3(122,4.75,44.7),Vector3(12.,.15,4.2),CORRUGATED,Vector3(-.08,0,0))
	work.panel(Vector3(118,.95,34.9),Vector3(5.4,.16,1.25),TIMBER)
	for x: float in [115.6,120.4]:
		work.beam(Vector3(x,0,34.9),Vector3(x,.9,34.9),.14,FRAME)
	for i in 4:
		work.cylinder(Vector3(106,.28+i*.38,38),.19,4.3,RUST,Vector3(0,0,PI/2.))
	art.prop("oil_can",Vector3(119,1.04,34.9),.22)
	art.prop("blowtorch",Vector3(117.6,1.04,34.9),-.4)
	art.prop("cart",Vector3(113.5,.01,46),.20)
	art.prop("barrel",Vector3(132.5,.01,45),-.1)
	work.finish(135.)
	for x: float in [42.,58.,74.]:
		EnvironmentArt.place(art,EnvironmentArt.CONTAINER,Vector3(x,0,-12.),"FreightConsignment",Vector3(2.,1.185,1.2))
	var spur := Track.new()
	spur.name = "LoadingSiding"
	spur.position = Vector3(51.,-.08,-21.)
	spur.length = 28.
	art.add_child(spur)
	EnvironmentArt.place(art,EnvironmentArt.BOX_VAN,Vector3(63,.02,-21.),"SidingBoxVan")
	var phone := DetailBuilder.new(art,"ServiceFence")
	for i in 12:
		var x := 5.+i*4.
		phone.beam(Vector3(x,0,-22),Vector3(x,2.1,-22),.10,FRAME)
		if i != 5:
			phone.beam(Vector3(x,1.63,-22),Vector3(x+4,1.63,-22),.07,FRAME)
			phone.beam(Vector3(x,.63,-22),Vector3(x+4,.63,-22),.06,RUST)
	phone.finish(120.)
