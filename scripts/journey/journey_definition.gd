class_name JourneyDefinition
extends Resource
## Content and pacing, independent of scene lifetime. Distances are baked arc lengths.
@export var id := "harlow_escape_v1"
@export var cruise_speed := 8.0
@export var seed_value := 3001
@export var fog: FogConfig = preload("res://resources/journey/escape_fog.tres")
@export var station_scenes: Array[PackedScene] = []

func build_route() -> FogRoute:
	var route := FogRoute.new()
	route.id = id
	route.stations = {"harlow": 0.0}
	var paths := [
		[Vector3(15,0,-3.5), Vector3(500,0,-3.5), Vector3(900,3,80), Vector3(1300,6,180), Vector3(1615,6,180), Vector3(1815,6,180)],
		[Vector3(1815,6,180), Vector3(2015,6,180), Vector3(2500,14,40), Vector3(2950,2,-80), Vector3(3215,2,-80), Vector3(3415,2,-80)],
		[Vector3(3415,2,-80), Vector3(3615,2,-80), Vector3(4215,2,-80)]]
	var ids := ["harlow_ashford", "ashford_blackwater", "blackwater_escape"]
	var station_ids := ["ashford", "blackwater", "escape"]
	for i in paths.size():
		var segment := FogRouteSegment.new()
		segment.id = ids[i]
		segment.next_ids = PackedStringArray([ids[i+1]]) if i < 2 else PackedStringArray()
		segment.connected_stations = PackedStringArray(["harlow" if i == 0 else station_ids[i-1], station_ids[i]])
		segment.environment_events = {"landmark": ["fuel tower", "hill cutting", "evacuation boundary"][i]}
		segment.curve = Curve3D.new()
		segment.curve.bake_interval = 2.0
		var points: Array = paths[i]
		for j in points.size():
			var before: Vector3 = points[maxi(0,j-1)]
			var after: Vector3 = points[mini(points.size()-1,j+1)]
			var tangent := (after - before).normalized()
			var incoming: float = points[j].distance_to(before) / 3.0
			var outgoing: float = points[j].distance_to(after) / 3.0
			# Station approaches and endpoints stay exactly straight and level.
			if j < 2 or j >= points.size()-2:
				tangent = Vector3.RIGHT
			segment.curve.add_point(points[j], -tangent * incoming, tangent * outgoing)
		route.segments.append(segment)
		route.stations[station_ids[i]] = route.length()
	return route
