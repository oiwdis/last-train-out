class_name FogRouteSegment
extends Resource
## Stable IDs and outgoing links permit future branch selection. The current
## simulation follows an explicitly selected itinerary; it never picks a branch.
@export var id := "main"
@export var curve: Curve3D
@export var next_ids: PackedStringArray = []

@export var connected_stations: PackedStringArray = []
@export var environment_events: Dictionary = {}
