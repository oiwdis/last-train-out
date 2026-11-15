class_name StationArt
extends Node3D
## Authored industrial dressing. No collision, movement parameters or random layout.
## Details belong to their wall, never float in front of a cutaway.

const D = preload("res://scripts/presentation/detail_builder.gd")


func _ready() -> void:
	var station := get_parent()
	_platform(station)
	_building(station.get_node("WarehouseA"), false)
	_building(station.get_node("WarehouseB"), true)
	_background(station.get_node("Background"))
	_freight(station)
	_dress_crates(station)


func _platform(station: Node3D) -> void:
	var d := D.new(self, "PlatformDetails")
	# Expansion joints, drains, worn edge markings. All flush with existing floors.
	for x in range(-1, 30):
		d.box(Vector3(x, 1.025, -1.82), Vector3(0.35, 0.018, 0.4), D.INK)
		if x % 2 == 0:
			d.box(Vector3(x, 1.012, 0.4), Vector3(0.025, 0.015, 4.4), D.STEEL)
			d.box(Vector3(x, 0.4, 2.805), Vector3(0.025, 0.7, 0.02), D.INK)
	for x in [3.0, 12.0, 26.0]:
		d.box(Vector3(x, 1.018, 2.3), Vector3(0.85, 0.02, 0.28), D.INK)
		for i in 7:
			d.box(Vector3(x - 0.35 + i * 0.11, 1.032, 2.3), Vector3(0.035, 0.02, 0.27), D.STEEL)
	# Enamel boards above the sight line; no new obstacles in the walking lane.
	d.signboard(Vector3(8.4, 3.8, -5.08), "01   /   LAST SERVICE", 4.8, 0.65)
	d.signboard(Vector3(25.5, 3.9, -5.08), "GOODS DEPOT  >", 4.2, 0.65, D.PALE)
	d.lettering(Vector3(14, 0.45, 2.84), "H J   /   PLATFORM 01", 0.32, D.PALE)
	# Abandoned luggage sits on the existing pile rather than adding blockers.
	for x in [5.1, 5.55]:
		d.box(Vector3(x, 1.16, 2.55), Vector3(0.42, 0.24, 0.24), D.RUST)
		d.box(Vector3(x, 1.3, 2.55), Vector3(0.16, 0.05, 0.08), D.INK)
		d.box(Vector3(x - 0.12, 1.17, 2.68), Vector3(0.04, 0.22, 0.015), D.AMBER)
	# Retaining wall piers and recessed brick courses.
	for x in range(-10, 150, 4):
		d.box(Vector3(x, 1.2, -25.05), Vector3(0.35, 2.4, 0.2), D.STEEL)
		d.box(Vector3(x, 2.4, -25.15), Vector3(4.0, 0.12, 0.55), D.INK)
	d.finish()


func _building(building: Node3D, depot_b: bool) -> void:
	var length := 30.0 if depot_b else 25.0
	var height := 5.5 if depot_b else 7.4
	var front := D.new(building.get_node("FrontWall"), "FacadeDetails")
	var back := D.new(building.get_node("BackWall"), "InteriorDetails")
	var structure := D.new(building, "RoofDetails")
	var accent := Color("718d8a") if depot_b else Color("a98160")
	for x in range(1, int(length), 4):
		front.box(Vector3(x, height / 2, 4.89), Vector3(0.16, height, 0.16), D.STEEL)
		back.box(Vector3(x, height / 2, -1.10), Vector3(0.12, height, 0.08), D.STEEL)
		# Roof trusses are above the highest traversable floor, including jump clearance.
		structure.beam(Vector3(x, height - 0.08, -1.0), Vector3(x, height - 0.35, 4.5), 0.1, D.INK)
	# Panel ribs / brick courses add scale without dense prop clutter.
	for y in range(1, int(height * 5)):
		front.box(Vector3(length / 2, y * 0.2, 4.864), Vector3(length, 0.018, 0.014), D.STEEL if depot_b else Color("483f3b"))
	for y in [0.45, 3.25, height - 0.1]:
		front.box(Vector3(length / 2, y, 4.95), Vector3(length, 0.08, 0.12), accent)
	back.box(Vector3(length / 2, height - 0.65, -1.06), Vector3(length, 0.08, 0.08), D.RUST)
	back.box(Vector3(length / 2, 0.45, -1.10), Vector3(length, 0.5, 0.03), accent.darkened(0.45))
	# Flaked plaster, repair plates and exposed brick are flush with solid wall spans.
	for patch in [Vector3(9.5, 1.05, -1.055), Vector3(20.5, 4.4, -1.055)]:
		back.box(patch, Vector3(1.35, 0.5, 0.018), Color("394748"))
		for row in 3:
			for brick in 4 - row:
				back.box(patch + Vector3(-0.5 + brick * 0.3 + (row % 2) * 0.14, row * 0.14 - 0.2, 0.018), Vector3(0.27, 0.11, 0.025), DetailBuilder.RUST.darkened(0.22))
		back.beam(patch + Vector3(0.6, 0.2, 0.02), patch + Vector3(0.85, 0.6, 0.02), 0.018, DetailBuilder.INK)
	# Sparse scraps and worn aisle paint lie flat; route silhouettes remain unobstructed.
	for x in range(2, int(length), 3):
		structure.box(Vector3(x, 0.035, 3.9), Vector3(0.7, 0.008, 0.06), accent.darkened(0.15))
	for i in 7:
		structure.box(Vector3(2 + i * 3.4, 0.038, 3.4 + (i % 2) * 0.4), Vector3(0.22, 0.008, 0.15), Color("9d9e8d"), Vector3(0, i * 0.8, 0))
	# All original windows stay legible and acquire actual frames and mullions.
	for wall: Node3D in [building.get_node("FrontWall"), building.get_node("BackWall")]:
		var wd := front if wall.name == &"FrontWall" else back
		for child in wall.get_children():
			if not (child is BoxVisual or child is BoxPart):
				continue
			if not (String(child.name).begins_with("Window") or String(child.name).begins_with("Glass")):
				continue
			var p: Vector3 = child.position
			var s: Vector3 = child.size
			p.z += 0.06 if wall.name == &"FrontWall" else 0.14
			_window(wd, p, s)
	front.signboard(Vector3(length / 2, height - 1.0, 5.04), "B  /  TRANSFER HALL" if depot_b else "A  /  BONDED STORES", 8.5, 0.85, D.PALE)
	back.signboard(Vector3(11.0 if depot_b else 15.5, 4.3 if depot_b else 2.4, -0.98), "B / 02    TRANSFER" if depot_b else "A / 01    STORES", 4.8, 0.75, accent)
	if depot_b:
		var room := D.new(building.get_node("BackRoomFront"), "DetourSigns")
		room.signboard(Vector3(13, 2.68, 0.94), "SERVICE  >", 1.3, 0.38, D.AMBER)
		room.signboard(Vector3(17.4, 1.9, 0.94), "MAIN AISLE CLOSED", 4.0, 0.65, D.AMBER)
		for i in 6:
			room.box(Vector3(15 + i * 0.65, 0.7, 0.93), Vector3(0.28, 0.1, 0.02), D.AMBER, Vector3(0, 0, -0.5))
		room.finish()
		back.signboard(Vector3(19.5, 2.1, -0.98), "KEEP MOVING  >", 3.0, 0.5, D.PALE)
		# Broken conduit and panels fixed to existing walls.
		back.beam(Vector3(24, 4, -1.02), Vector3(26.4, 3.5, -1.02), 0.06, D.RUST)
		back.box(Vector3(25.5, 1.6, -0.98), Vector3(1, 1.4, 0.12), D.INK)
		back.lettering(Vector3(25.5, 1.65, -0.9), "DANGER", 0.15, D.AMBER)
	else:
		back.signboard(Vector3(7.7, 5.3, -0.98), "DISPATCH / UPPER STORES", 5.3, 0.6, D.PALE)
		back.signboard(Vector3(3.7, 2.4, -0.98), "UPPER FLOOR  >", 3.4, 0.5, D.AMBER)
		for x in [14.0, 20.5]:
			back.box(Vector3(x, 1.7, -1.02), Vector3(1.0, 1.2, 0.04), Color("c0b096"))
			back.lettering(Vector3(x, 1.8, -0.97), "EVACUATE\nBY RAIL", 0.18, D.INK)
	# Sawtooth skylights change the silhouette; existing flat roofs remain collision truth.
	for x in range(2, int(length), 5):
		structure.box(Vector3(x, height + 0.55, 0.6), Vector3(3.8, 0.12, 2.3), D.STEEL, Vector3(-0.3, 0, 0))
		structure.box(Vector3(x, height + 0.42, 1.7), Vector3(3.8, 0.7, 0.08), Color("496b78"))
		for dx in [-1.3, 0, 1.3]:
			structure.box(Vector3(x + dx, height + 0.42, 1.76), Vector3(0.07, 0.75, 0.05), D.INK)
	front.finish()
	back.finish()
	structure.finish()


func _window(d: DetailBuilder, p: Vector3, s: Vector3) -> void:
	for direction in [-1.0, 1.0]:
		d.box(p + Vector3(direction * s.x * 0.5, 0, 0), Vector3(0.07, s.y + 0.1, 0.08), D.INK)
		d.box(p + Vector3(0, direction * s.y * 0.5, 0), Vector3(s.x + 0.12, 0.07, 0.08), D.PALE.darkened(0.3))
	d.box(p, Vector3(0.045, s.y, 0.06), D.INK)
	d.box(p, Vector3(s.x, 0.04, 0.06), D.INK)


func _background(background: Node3D) -> void:
	var d := D.new(background, "CityDetails")
	# The imported facade supplies masonry, windows and cornices. Keep a clock
	# mounted on the solid storey band, below the new pitched roof.
	d.cylinder(Vector3(12, 4.35, -6.97), 0.42, 0.14, D.INK, Vector3(PI / 2, 0, 0))
	d.cylinder(Vector3(12, 4.35, -6.88), 0.37, 0.03, D.PALE, Vector3(PI / 2, 0, 0))
	d.beam(Vector3(12, 4.35, -6.85), Vector3(12, 4.63, -6.85), 0.025, D.INK)
	d.beam(Vector3(12, 4.35, -6.84), Vector3(12.2, 4.2, -6.84), 0.025, D.INK)
	# Gabled mill roofs, chimneys and sparse dark windows break up the old blocks.
	var masonry := preload("res://resources/materials/wall_brick.tres").duplicate() as StandardMaterial3D
	masonry.albedo_color = Color(.45,.48,.5)
	for child in background.get_children():
		if not child is BoxVisual:
			continue
		var title := String(child.name)
		if title.begins_with("SkylineWindow"):
			child.hide()
		if not (title.begins_with("Block") or title.begins_with("Factory") or title.begins_with("Shed")):
			continue
		var p: Vector3 = child.position
		var s: Vector3 = child.size
		# The existing envelopes stay cheap, but use metre-scaled masonry and
		# continuous closed roofs instead of disconnected tilted roof strips.
		child.mesh = FabricatedMesh.box(s,masonry)
		var roof := MeshInstance3D.new()
		roof.name = "ContinuousGabledRoof"
		roof.mesh = FabricatedMesh.gabled_roof(Vector2(s.x+.4,s.z+.4),minf(s.z*.22,2.0),preload("res://resources/materials/roof_metal.tres"))
		roof.position.y = s.y*.5
		roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		child.add_child(roof)
		var front_z := p.z + s.z / 2 + 0.04
		for x in range(int(-s.x / 2) + 2, int(s.x / 2), 4):
			for y in range(3, int(s.y) - 1, 3):
				d.box(Vector3(p.x + x, y, front_z), Vector3(1.25, 1.4, 0.03), Color("24343d"))
				if title.begins_with("Factory") or title in ["ShedA","ShedB"]:
					d.box(Vector3(p.x+x,y-.73,front_z+.02),Vector3(1.38,.09,.09),Color("535951"))
					d.box(Vector3(p.x+x,y,front_z+.03),Vector3(.04,1.4,.035),Color("535951"))
		d.box(Vector3(p.x + s.x * 0.28, s.y + 1.8, p.z), Vector3(0.8, 3.6, 0.8), D.INK)
	# Cable runs sag between the existing poles, safely behind the train envelope.
	for x in range(-20, 150, 25):
		for segment in 10:
			var a := segment / 10.0
			var b := (segment + 1) / 10.0
			d.beam(Vector3(x + a * 25, 6.9 - sin(a * PI) * 0.65, -6.3), Vector3(x + b * 25, 6.9 - sin(b * PI) * 0.65, -6.3), 0.025, D.INK)
	# Water tower cross-bracing and cylindrical tank replace its square silhouette.
	(background.get_node("WaterTowerTank") as Node3D).hide()
	d.cylinder(Vector3(-9, 9.2, -9), 2.2, 3.6, D.STEEL)
	for y in [7.6, 9.0, 10.8]:
		d.cylinder(Vector3(-9, y, -9), 2.25, 0.09, D.INK)
	d.cylinder(Vector3(-9, 11.25, -9), 2.4, 0.7, D.INK, Vector3.ZERO, 0.15)
	d.beam(Vector3(-10.6, 1, -7.4), Vector3(-7.4, 7.4, -7.4), 0.12, D.INK)
	d.beam(Vector3(-7.4, 1, -7.4), Vector3(-10.6, 7.4, -7.4), 0.12, D.INK)
	d.finish()


func _freight(station: Node3D) -> void:
	var d := D.new(self, "FreightDetails")
	# Crane belongs behind the track: a distinct silhouette without obstructing jumps.
	for x in [102.0, 120.0]:
		d.box(Vector3(x, 5, -7), Vector3(0.35, 10, 0.4), D.RUST)
		d.beam(Vector3(x, 6, -7), Vector3(x + (2 if x < 110 else -2), 9.3, -7), 0.15, D.STEEL)
	d.box(Vector3(111, 9.8, -7), Vector3(20, 0.6, 0.5), D.RUST)
	for x in range(102, 120, 2):
		d.beam(Vector3(x, 9.5, -6.7), Vector3(x + 2, 10.1, -6.7), 0.07, D.INK)
	d.box(Vector3(110, 7.2, -7), Vector3(0.05, 5, 0.05), D.INK)
	d.signboard(Vector3(111, 8.7, -6.65), "03   /   FREIGHT EXCHANGE", 8.5, 0.8, D.PALE)
	d.finish()
	for index in 2:
		var car := station.get_node("FreightCarA" if index == 0 else "FreightCarB") as Node3D
		var cd := D.new(car, "FreightCarDetails")
		for x in range(-3, 4):
			cd.box(Vector3(x, 2.1, 1.36), Vector3(0.07, 2.8, 0.06), D.STEEL)
		cd.box(Vector3(0.4, 2.05, 1.4), Vector3(2.2, 2.4, 0.06), D.RUST if index == 0 else D.STEEL)
		cd.beam(Vector3(-0.7, 0.9, 1.46), Vector3(1.5, 3.2, 1.46), 0.08, D.INK)
		cd.signboard(Vector3(0.4, 2.3, 1.48), "HJ / 084" if index == 0 else "HJ / 112", 1.9, 0.42, D.PALE)
		cd.finish()


func _dress_crates(node: Node) -> void:
	# Existing solid crates gain slats/straps. Their exact collision geometry is untouched.
	for child in node.get_children():
		_dress_crates(child)
	if not node is BoxPart:
		return
	var part := node as BoxPart
	if part.material == null or not part.material.resource_path.contains("crate_"):
		return
	var d := D.new(part, "CrateDetails")
	var s := part.size
	for side in [-1.0, 1.0]:
		d.box(Vector3(side * s.x * 0.34, 0, s.z * 0.5 + 0.012), Vector3(0.045, s.y, 0.025), D.INK)
		d.box(Vector3(side * s.x * 0.34, s.y * 0.5 + 0.012, 0), Vector3(0.045, 0.025, s.z), D.INK)
	for i in range(1, 4):
		d.box(Vector3(0, s.y * (i / 4.0 - 0.5), s.z * 0.5 + 0.014), Vector3(s.x, 0.018, 0.015), D.INK)
	d.box(Vector3(0, 0, s.z * 0.5 + 0.03), Vector3(s.x * 0.23, s.y * 0.2, 0.015), D.PALE.darkened(0.2))
	d.finish()
