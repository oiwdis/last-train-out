class_name StationBuilding
extends StaticBody3D
## Replaceable modular shell. Open doorway, windows, collision and shelter share dimensions.
@export var dimensions := Vector3(12,4,9)
@export var title := "STORE"
@export var industrial := true
var shelter: FogShelter

func _ready() -> void:
	var w := dimensions.x
	var h := dimensions.y
	var d := dimensions.z
	var wall: Material = preload("res://resources/materials/wall_industrial.tres") if industrial else preload("res://resources/materials/wall_brick.tres")
	var roof := preload("res://resources/materials/roof_metal.tres")
	part(Vector3(0,-0.12,0), Vector3(w,0.24,d), preload("res://resources/materials/floor_interior.tres") if industrial else preload("res://resources/materials/floor_wood.tres"))
	part(Vector3(0,h/2,-d/2),Vector3(w,h,0.24),wall)
	for side in [-1,1]:
		part(Vector3(side*w/2,h/2,0),Vector3(0.24,h,d),wall)
		# Wide walk-through doorway, no invisible collider across it.
		part(Vector3(side*(w/4+0.65),h/2,d/2),Vector3(w/2-1.3,h,0.24),wall)
	part(Vector3(0,h-0.5,d/2),Vector3(2.6,1,0.24),wall)
	part(Vector3(0,h,0),Vector3(w+0.6,0.18,d+0.6),roof)
	var details := DetailBuilder.new(self)
	details.signboard(Vector3(0,h-0.65,d/2+0.15),title,w*0.7,0.65)
	for side in [-1,1]:
		details.box(Vector3(side*w*0.29,2,d/2+0.14),Vector3(w*0.18,1,0.03),Color("435352"))
	details.finish()
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0,h-0.5,0)
	lamp.light_color = Color("e9c59b")
	lamp.light_energy = 1.3
	lamp.omni_range = maxf(w,d)*0.7
	lamp.shadow_enabled = false
	add_child(lamp)
	shelter = FogShelter.new()
	shelter.bounds = AABB(Vector3(-w/2,0,-d/2),Vector3(w,h,d))
	add_child(shelter)

func part(at: Vector3, size: Vector3, material: Material) -> BoxPart:
	var block := BoxPart.new()
	block.square_edges = true
	block.position = at
	block.size = size
	block.material = material
	add_child(block)
	return block
