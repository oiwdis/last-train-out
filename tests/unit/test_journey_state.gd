extends TestSuite
var definition: JourneyDefinition
var route: FogRoute

func before_each() -> void:
	definition = load("res://resources/journey/harlow_escape.tres")
	route = definition.build_route()

func test_route_itinerary_has_unique_linked_segments() -> void:
	check_eq(route.segments.size(),3,"three connected legs")
	check_eq(route.segments[0].next_ids[0],route.segments[1].id,"future branch link")
	check_greater(route.length(),4200,"curves count arc length")
	check_eq(route.locate(route.stations.blackwater).segment,"blackwater_escape","boundary chooses outgoing leg")

func test_route_samples_project_back_through_curves_and_elevation() -> void:
	for s in range(0,int(route.length()),71):
		check_near(route.project(route.sample(s)),s,0.08,"arc-length projection round trip")
	check_greater(route.sample(2500).y,10,"hill has real elevation")

func test_rail_frames_are_orthonormal_and_continuous() -> void:
	var last := RouteTrack.frame(route,0)
	for s in range(1,int(route.length()),3):
		var t := RouteTrack.frame(route,s)
		check_near(t.basis.determinant(),1,0.001,"right-handed train frame")
		check_greater(t.basis.x.dot(last.basis.x),0.99,"no turn discontinuities")
		last = t

func test_station_approaches_are_level_and_straight() -> void:
	for id in ["ashford","blackwater"]:
		var at: float = route.stations[id]
		for offset in [-60,0,60]:
			check_near(route.tangent(at+offset).dot(Vector3.RIGHT),1,0.001,"straight platform approach")

func test_arrivals_do_not_reset_seeded_fog_events() -> void:
	var a := FogSimulation.new(definition.fog,route,5301)
	var b := FogSimulation.new(definition.fog,route,5301)
	a.advance(180)
	b.advance(180)
	var before := a.snapshot()
	a.enter_station("ashford")
	check_eq(a.rng.state,b.rng.state,"arrival retains RNG state")
	check_eq(a.front,b.front,"arrival retains front")
	check_eq(a.elapsed,b.elapsed,"arrival retains time")
	check_eq(a.pending_event,b.pending_event,"warning continues")
	check_eq(a.event,b.event,"active event continues")
	check_eq(a.next_event,b.next_event,"schedule retained")
	check(before.elapsed > 0,"scenario was advanced")

func test_mission_requires_real_station_objectives() -> void:
	var mission := MissionState.new()
	mission.evaluate(route.length(),route.length(),true,true)
	check_eq(mission.status,"incomplete","driving straight through is not completion")

func test_mission_results_capture_completed_objectives() -> void:
	var mission := completed()
	mission.evaluate(route.length()-1,route.length(),true,true)
	check_eq(mission.status,"escaped","all objectives and escape")
	check_eq(mission.results(1250,route.length()).stations_visited.size(),3,"results carry stable station IDs")

func test_mission_death_and_abandoned_train_cannot_win() -> void:
	var mission := completed()
	mission.evaluate(800,route.length(),false,true)
	check_eq(mission.status,"failed","death records failure")
	mission = completed()
	mission.evaluate(route.length(),route.length(),true,false)
	check_eq(mission.status,"incomplete","must escape aboard")

func test_mission_json_round_trip_and_invalid_values() -> void:
	var mission := completed()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(mission.snapshot()))
	var restored := MissionState.new()
	check(restored.restore(saved),"JSON numbers accepted")
	check_eq(restored.snapshot(),mission.snapshot(),"exact ledger restored")
	saved.visited.append("unknown")
	check(not restored.restore(saved),"unknown station rejected")
	check_eq(restored.snapshot(),mission.snapshot(),"failure is atomic")

func test_starting_fuel_requires_scavenging() -> void:
	var minimum_burn := route.length()/definition.cruise_speed*definition.fog.fuel_per_second
	check_greater(minimum_burn,definition.fog.initial_fuel+definition.fog.fuel_per_sack,"Harlow alone cannot fuel mission")
	check_less(minimum_burn,definition.fog.initial_fuel+3*definition.fog.fuel_per_sack,"three coal sacks cover efficient travel")

func test_persistence_validation_rejects_nonfinite_and_fractional_counts() -> void:
	check(not JourneySave.number(NAN,0,100),"NaN rejected")
	check(not JourneySave.number("42",0,100),"string number rejected")
	check(not JourneySave.integer(1.5,0,10),"fractional item rejected")
	check(not JourneySave.vector([1,2]),"malformed vector rejected")

func completed() -> MissionState:
	var mission := MissionState.new()
	mission.visited = ["harlow","ashford","blackwater"]
	mission.record_supply("harlow_coal","coal_sack",1)
	mission.record_supply("blackwater_food","canned_food",2)
	mission.record_supply("blackwater_medicine","medicine",1)
	mission.refuels = {"harlow":1,"ashford":2}
	mission.note_read = true
	return mission
