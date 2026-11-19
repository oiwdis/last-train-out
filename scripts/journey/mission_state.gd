class_name MissionState
extends RefCounted
## Server-owned run ledger; no scene references, UI or future reward economy.
const STATIONS := ["harlow", "ashford", "blackwater"]
var status := "active"
var visited: Array = ["harlow"]
var collected: Dictionary = {}
var refuels: Dictionary = {}
var note_read := false
var peak_exposure := 0.0
var exposure_seconds := 0.0

func record_supply(cache_id: String, item_id: String, amount: int) -> void:
	if amount <= 0 or status != "active":
		return
	var station := cache_id.get_slice("_",0)
	# Original Harlow cache IDs predate station prefixes.
	if station not in STATIONS:
		station = "harlow"
	var key := station + "/" + item_id
	collected[key] = int(collected.get(key,0)) + amount

func objective_index() -> int:
	if not refuels.has("harlow") or not _supplies_at("harlow"):
		return 0
	if not visited.has("ashford") or not refuels.has("ashford"):
		return 1
	if not visited.has("blackwater") or not note_read or int(collected.get("blackwater/canned_food",0)) < 1 or int(collected.get("blackwater/medicine",0)) < 1:
		return 2
	return 3

func _supplies_at(station: String) -> bool:
	for key: String in collected:
		if key.begins_with(station + "/"):
			return true
	return false

func objective() -> String:
	return ["Prepare Harlow: search supplies, carry coal to the hold, then stoke the boiler.",
		"Reach Ashford. Collect coal, deposit it in the hold and stoke the boiler.",
		"Reach Blackwater. Collect food and medicine; read the evacuation log at Crossing Stores.",
		"Return aboard and escape east beyond Blackwater."][objective_index()]

func evaluate(distance: float, finish: float, alive: bool, aboard: bool) -> void:
	if status != "active":
		return
	if not alive:
		status = "failed"
	elif distance >= finish - 2.0:
		status = "escaped" if objective_index() == 3 and aboard else "incomplete"

func snapshot() -> Dictionary:
	return {"status":status,"visited":visited.duplicate(),"collected":collected.duplicate(),
		"refuels":refuels.duplicate(),"note":note_read,"peak":peak_exposure,"exposure_seconds":exposure_seconds}

func restore(data: Dictionary) -> bool:
	if data.get("status") not in ["active","failed","escaped","incomplete"] or not data.get("visited") is Array or not data.get("collected") is Dictionary or not data.get("refuels") is Dictionary or not data.get("note") is bool:
		return false
	if not JourneySave.number(data.get("peak"),0,100) or not JourneySave.number(data.get("exposure_seconds"),0,1000000):
		return false
	var seen := {}
	for id in data.visited:
		if id not in STATIONS or seen.has(id):
			return false
		seen[id] = true
	if not seen.has("harlow"):
		return false
	for key in data.collected:
		if not key is String or key.get_slice("/",0) not in STATIONS or ItemCatalog.find(key.get_slice("/",1)) == null or not JourneySave.integer(data.collected[key],0,100000):
			return false
	for key in data.refuels:
		if key not in STATIONS or not JourneySave.integer(data.refuels[key],1,10000):
			return false
	status = data.status
	visited = data.visited.duplicate()
	collected = {}
	for key in data.collected:
		collected[key] = int(data.collected[key])
	refuels = {}
	for key in data.refuels:
		refuels[key] = int(data.refuels[key])
	note_read = data.note
	peak_exposure = data.peak
	exposure_seconds = data.exposure_seconds
	return true

func results(elapsed: float, distance: float) -> Dictionary:
	return {"version":1,"mission":"harlow_escape_v1","status":status,"time_survived":elapsed,
		"stations_visited":visited.duplicate(),"supplies_collected":collected.duplicate(),
		"distance":distance,"peak_exposure":peak_exposure,"exposure_seconds":exposure_seconds}
