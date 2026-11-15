class_name FogRoute
extends Resource
## Ordered itinerary in route metres, independent of world axes and scene loading.
@export var id := "harlow_line_v1"
@export var segments: Array[FogRouteSegment] = []
@export var stations: Dictionary = {"harlow": 0.0}

func length() -> float:
	var total := 0.0
	for segment in segments:
		total += segment.curve.get_baked_length()
	return total

func locate(progress: float) -> Dictionary:
	var offset := 0.0
	for i in segments.size():
		var size := segments[i].curve.get_baked_length()
		if progress < offset + size or i == segments.size() - 1:
			return {"segment": segments[i].id, "index": i, "distance": progress - offset}
		offset += size
	return {}

func sample(progress: float) -> Vector3:
	var location := locate(progress)
	if location.is_empty():
		return Vector3.ZERO
	var curve := segments[int(location.index)].curve
	var size := curve.get_baked_length()
	var distance := float(location.distance)
	if distance < 0:
		return curve.sample_baked(0) + (curve.sample_baked(minf(0.1, size)) - curve.sample_baked(0)).normalized() * distance
	if distance > size:
		return curve.sample_baked(size) + (curve.sample_baked(size) - curve.sample_baked(maxf(0, size - 0.1))).normalized() * (distance - size)
	return curve.sample_baked(distance, true)

func tangent(progress: float) -> Vector3:
	return (sample(progress + 0.1) - sample(progress - 0.1)).normalized()

## segment_hint resolves crossings/overlapping track. Future route authority supplies it.
func project(point: Vector3, segment_hint: String = "") -> float:
	var best := INF
	var progress := 0.0
	var offset := 0.0
	for segment in segments:
		var curve := segment.curve
		var size := curve.get_baked_length()
		if segment_hint == "" or segment_hint == segment.id:
			var along := curve.get_closest_offset(point)
			var closest := curve.sample_baked(along)
			if segment == segments.front() and along <= 0.001:
				var axis := (curve.sample_baked(minf(0.1, size)) - closest).normalized()
				along = minf((point - closest).dot(axis), 0.0)
				closest += axis * along
			elif segment == segments.back() and along >= size - 0.001:
				var axis := (closest - curve.sample_baked(maxf(0, size - 0.1))).normalized()
				var extra := maxf((point - closest).dot(axis), 0.0)
				along += extra
				closest += axis * extra
			var error := closest.distance_squared_to(point)
			if error < best:
				best = error
				progress = offset + along
		offset += size
	return progress

func signature() -> String:
	var data := id + str(stations)
	for segment in segments:
		data += segment.id + str(segment.next_ids) + str(segment.curve.get_baked_points())
	return data.sha256_text()
