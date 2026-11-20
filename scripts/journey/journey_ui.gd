class_name JourneyUI
extends CanvasLayer
## Route ledger doubles as pause/save menu. Inventory alone never pauses danger.
var journey: JourneyController
var summary: Label
var ledger: Label
var message: Label
var panel: PanelContainer
var seed_input: SpinBox
var difficulty: OptionButton
var return_button: Button
var _elapsed := 0.0

func bind(owner_journey: JourneyController) -> void:
	journey = owner_journey
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = RailTheme.create()
	add_child(root)
	var strip := PanelContainer.new()
	strip.position = Vector2(370,28)
	strip.size = Vector2(570,88)
	strip.add_theme_stylebox_override("panel",RailTheme.panel())
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(strip)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size.x = 525
	summary.add_theme_font_size_override("font_size",14)
	strip.add_child(summary)
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760,530)
	panel.add_theme_stylebox_override("panel",RailTheme.panel())
	center.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	ledger = Label.new()
	ledger.custom_minimum_size = Vector2(690,210)
	ledger.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(ledger)
	var settings := HBoxContainer.new()
	rows.add_child(settings)
	var seed_label := Label.new()
	seed_label.text = "New journey seed"
	settings.add_child(seed_label)
	seed_input = SpinBox.new()
	seed_input.max_value = 999999999
	seed_input.value = journey.game.fog_system.scenario_seed
	settings.add_child(seed_input)
	difficulty = OptionButton.new()
	for title in ["Gentle", "Standard", "Severe"]:
		difficulty.add_item(title)
	difficulty.select(1)
	settings.add_child(difficulty)
	var actions := HBoxContainer.new()
	rows.add_child(actions)
	button(actions,"Save Game",func() -> void: message.text = JourneySave.write_file(journey))
	button(actions,"Continue Game",func() -> void: message.text = journey.continue_game())
	button(actions,"New Game",func() -> void: journey.new_game(int(seed_input.value),[0.75,1.0,1.25][difficulty.selected]))
	button(actions,"Restart Mission",func() -> void: journey.new_game(journey.game.fog_system.simulation.seed_value,journey.game.fog_system.config.difficulty))
	return_button = button(rows,"Return to journey  ·  J",func() -> void: toggle(false))
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 690
	rows.add_child(message)
	panel.hide()
	_refresh()

func button(parent: Node, title: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = title
	control.pressed.connect(action)
	parent.add_child(control)
	return control

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_J:
		# Preparation owns the temporary pause. Opening the ledger underneath its
		# cover would leave a visible ledger with an unpaused world on completion.
		if journey.game.graphics.is_preparing():
			get_viewport().set_input_as_handled()
			return
		toggle(not panel.visible)
		get_viewport().set_input_as_handled()

func toggle(open: bool) -> void:
	if not open and journey.mission.status != "active":
		return
	panel.visible = open
	journey.game.camera_rig.exploration.set_menu_open(&"journey",open)
	get_tree().paused = open
	_refresh()

func show_results() -> void:
	toggle(true)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.25:
		_elapsed = 0
		_refresh()

func _refresh() -> void:
	if journey == null or not journey.ready_to_play:
		return
	var fog := journey.game.fog_system
	var train := journey.game.train
	var mission := journey.mission
	var target := journey.stops[journey.next_stop]
	summary.text = "THE HARLOW ESCAPE  ·  %s  ·  J route / save\n%s\nNext: %s · %.0f m · boiler %.0f / %.0f" % [journey.current_station().to_upper(),mission.objective(),target.capitalize(),maxf(0,journey.route.stations[target]-train.distance),fog.fuel.amount,fog.config.fuel_capacity]
	var lines := "THE HARLOW ESCAPE  /  %s\nWorld paused while this ledger is open.\n\n" % mission.status.to_upper()
	for id: String in MissionState.STATIONS:
		lines += "%s · %.2f km · %s%s\n" % [id.capitalize(),journey.route.stations[id]/1000.0,"visited" if mission.visited.has(id) else "ahead"," · ENGULFED" if fog.simulation.front >= journey.route.stations[id] else ""]
	var total := 0
	for amount in mission.collected.values():
		total += int(amount)
	lines += "\nTime %02d:%02d · Distance %.2f km · Supplies collected %d\nPeak exposure %.0f%% · Exposure time %.0fs\n\n%s" % [int(fog.simulation.elapsed)/60,int(fog.simulation.elapsed)%60,train.distance/1000,total,mission.peak_exposure,mission.exposure_seconds,mission.objective()]
	ledger.text = lines
	return_button.disabled = mission.status != "active"
	return_button.text = "Return to journey  ·  J" if mission.status == "active" else "Journey ended · choose New Game or Restart Mission"
