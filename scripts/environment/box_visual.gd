@tool
class_name BoxVisual
extends MeshInstance3D
## Visual-only gray-box block (no collision). Counterpart of [BoxPart] for
## decoration such as window panes, trim and background silhouettes.

@export var size := Vector3.ONE:
	set(value):
		size = value.max(Vector3(0.01, 0.01, 0.01))
		_rebuild()

@export var material: Material:
	set(value):
		material = value
		_rebuild()


func _ready() -> void:
	mesh = BoxMesh.new()
	_rebuild()


func _rebuild() -> void:
	var box := mesh as BoxMesh
	if box == null:
		return
	box.size = size
	box.material = material
