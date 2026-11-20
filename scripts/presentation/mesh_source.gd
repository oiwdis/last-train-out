class_name CpuMeshSource
extends Mesh
## SurfaceTool reads this CPU-only source through Mesh's virtual interface.
## Never assign it to a rendered instance: commit the assembled SurfaceTool.
## This preserves native append_from transforms/indexing without uploading and
## downloading an intermediate ArrayMesh for every decorative box or rung.
var arrays: Array

func _init(source: Array = []) -> void:
	arrays = source

func _get_surface_count() -> int: return 1
func _surface_get_arrays(_surface: int) -> Array: return arrays
func _surface_get_array_len(_surface: int) -> int: return arrays[Mesh.ARRAY_VERTEX].size()
func _surface_get_array_index_len(_surface: int) -> int: return arrays[Mesh.ARRAY_INDEX].size()
func _surface_get_primitive_type(_surface: int) -> int: return Mesh.PRIMITIVE_TRIANGLES
func _surface_get_material(_surface: int) -> Material: return null
func _surface_get_format(_surface: int) -> int:
	var format := 0
	for slot in arrays.size():
		if arrays[slot] != null and not arrays[slot].is_empty(): format |= 1 << slot
	return format
