extends TestSuite


func test_location_labels_cover_track_detour_and_yard() -> void:
	check_eq(Hud.location_at(Vector3(50, 4, -3.5), true), "07  /  ABOARD THE TRAIN", "boarding wins over warehouse position")
	check_eq(Hud.location_at(Vector3(50, 0, -3.5), false), "00  /  TRACKSIDE", "track is not a warehouse")
	check_eq(Hud.location_at(Vector3(88, 0, 0), false), "B  /  SERVICE PASSAGE", "back-room detour identified")
	check_eq(Hud.location_at(Vector3(110, 3.8, 0), false), "03  /  FREIGHT EXCHANGE", "freight roofs belong to yard")


func test_departure_labels_do_not_promise_a_countdown() -> void:
	check_eq(Hud.departure_status(Train.State.STOPPED, true), "END OF LINE", "end of track is explicit")
	check_eq(Hud.departure_status(Train.State.STOPPED, false, false), "STOPPED", "a stopped train is not always at platform")
	check_eq(Hud.departure_status(Train.State.ACCELERATING, false), "DEPARTING", "acceleration has no invented countdown")
