class_name Hud
extends CanvasLayer
## Read-only railway instrument HUD. Real interaction eligibility comes from Player.

@export var prompt_refresh_interval := 0.1
var _player: Player
var _train: Train
var _station: Station
var _journey: Node
var _refresh := 0.0
var _message_time := 0.0
var _location_time := 0.0
var _last_location := ""
var _aboard := false
var _board_time := 0.0
var _stamina_target := 100.0
var _stamina_bar: ProgressBar
var _stamina_label: Label
var _stamina_value: Label
var _prompt: Label
var _prompt_panel: PanelContainer
var _message: Label
var _message_panel: PanelContainer
var _location: Label
var _status: Label
var _speed: Label
var _train_gauge: ProgressBar
var _fill: StyleBoxFlat
var _root: Control


func _ready() -> void:
	_build()


func _build() -> void:
	_root = Control.new()
	_root.name = "Instruments"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = RailTheme.create()
	add_child(_root)
	var location_box := _panel("Location", Vector2(30, 28), Vector2(320, 78))
	var location_rows := _rows(location_box)
	_label(location_rows, "LAST TRAIN OUT     /     TRAIN 07", 11, RailTheme.MUTED)
	_location = _label(location_rows, "01  /  PLATFORM", 20, RailTheme.PAPER)
	var train_box := _panel("Departure", Vector2(-294, 28), Vector2(264, 104), Vector2(1, 0))
	var train_rows := _rows(train_box)
	_label(train_rows, "TRAIN 07     /     DEPARTURE", 11, RailTheme.MUTED)
	var status_row := HBoxContainer.new()
	train_rows.add_child(status_row)
	_status = _label(status_row, "AT PLATFORM", 17, RailTheme.AMBER)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed = _label(status_row, "00 km/h", 13, RailTheme.PAPER)
	_train_gauge = _bar(train_rows, 3)
	_label(train_rows, "CAB · CREW · SUPPLY DECK", 10, RailTheme.MUTED)
	var stamina_box := _panel("Endurance", Vector2(30, -112), Vector2(248, 82), Vector2(0, 1))
	var stamina_rows := _rows(stamina_box)
	var stamina_header := HBoxContainer.new()
	stamina_rows.add_child(stamina_header)
	_stamina_label = _label(stamina_header, "STAMINA", 11, RailTheme.MUTED)
	_stamina_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stamina_value = _label(stamina_header, "100", 16, RailTheme.PAPER)
	_stamina_bar = _bar(stamina_rows, 7)
	_fill = _stamina_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	_stamina_bar.add_theme_stylebox_override("fill", _fill)
	_label(stamina_rows, "SHIFT   /   SPRINT", 10, RailTheme.MUTED)
	_prompt_panel = _panel("Interaction", Vector2(-340, -103), Vector2(680, 42), Vector2(0.5, 1))
	_prompt = _label(_prompt_panel, "", 16, RailTheme.PAPER)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_panel.modulate.a = 0
	_message_panel = _panel("Notice", Vector2(-350, 145), Vector2(700, 43), Vector2(0.5, 0))
	_message = _label(_message_panel, "", 16, RailTheme.AMBER)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_panel.modulate.a = 0
	var reticle := _label(_root, "·", 25, RailTheme.PAPER)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reticle.offset_left = -7
	reticle.offset_top = -18
	reticle.offset_right = 7
	reticle.offset_bottom = 18
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls := _label(_root, "WASD MOVE   MOUSE LOOK   V VIEW   E USE   TAB PACK   G DROP", 11, RailTheme.MUTED)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.offset_left = -610
	controls.offset_top = -42
	controls.offset_right = -30
	controls.offset_bottom = -24
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ignore_mouse(_root)


func _panel(title: String, offset: Vector2, dimensions: Vector2, anchor: Vector2 = Vector2.ZERO) -> PanelContainer:
	var node := PanelContainer.new()
	node.name = title
	_root.add_child(node)
	node.anchor_left = anchor.x
	node.anchor_right = anchor.x
	node.anchor_top = anchor.y
	node.anchor_bottom = anchor.y
	node.offset_left = offset.x
	node.offset_top = offset.y
	node.offset_right = offset.x + dimensions.x
	node.offset_bottom = offset.y + dimensions.y
	return node


func _rows(parent: Node) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	parent.add_child(box)
	return box


func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _bar(parent: Node, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("34464b")
	var fill := StyleBoxFlat.new()
	fill.bg_color = RailTheme.AMBER
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


func bind(player: Player, train: Train = null, station: Station = null, journey: Node = null) -> void:
	if is_instance_valid(_player) and _player.stamina.changed.is_connected(_on_stamina_changed):
		_player.stamina.changed.disconnect(_on_stamina_changed)
	_player = player
	_train = train
	_station = station
	_journey = journey
	_aboard = false
	_board_time = 0
	if _player == null:
		return
	_on_stamina_changed(_player.stamina.current, _player.stamina.max_stamina)
	_stamina_bar.value = _stamina_target
	_player.stamina.changed.connect(_on_stamina_changed)
	_refresh_context()


func _process(delta: float) -> void:
	_message_time = maxf(0, _message_time - delta)
	_message_panel.modulate.a = move_toward(_message_panel.modulate.a, minf(_message_time / 0.4, 1), delta * 5)
	if not is_instance_valid(_player):
		return
	_stamina_bar.value = lerpf(_stamina_bar.value, _stamina_target, 1.0 - exp(-14 * delta))
	var exhausted := _player.stamina.is_exhausted
	_fill.bg_color = RailTheme.ALERT if exhausted else RailTheme.AMBER
	_stamina_label.text = "EXHAUSTED / RECOVER" if exhausted else "STAMINA"
	_stamina_label.modulate = RailTheme.ALERT if exhausted else Color.WHITE
	_prompt_panel.modulate.a = move_toward(_prompt_panel.modulate.a, 0.0 if _prompt.text.is_empty() else 1.0, delta * 7)
	_location_time = maxf(_location_time - delta, 0)
	_location.modulate.a = move_toward(_location.modulate.a, 1.0 if _location_time > 0 else 0.72, delta * 2)
	var on_train := _player.is_on_train()
	_board_time = _board_time + delta if on_train else 0.0
	if _board_time >= 0.25 and not _aboard:
		_aboard = true
		show_message("ABOARD  /  HOLD ON", 2.5)
	elif not on_train:
		_aboard = false
	_refresh -= delta
	if _refresh <= 0:
		_refresh = prompt_refresh_interval
		_refresh_context()


func _refresh_context() -> void:
	if not is_instance_valid(_player):
		return
	_prompt.text = _player.get_interaction_prompt()
	_stamina_value.text = "%03d" % roundi(_player.stamina.current / maxf(_player.stamina.max_stamina, 1) * 100)
	if is_instance_valid(_station):
		var location := location_at(_station.to_local(_player.global_position), _player.is_on_train())
		if is_instance_valid(_journey) and not _player.is_on_train():
			var stop: String = _journey.current_station()
			if stop == "ashford": location = "02  /  ASHFORD DEPOT"
			elif stop == "blackwater": location = "03  /  BLACKWATER"
		if location != _last_location:
			_last_location = location
			_location.text = location
			_location.modulate.a = 0.3
			_location_time = 3.0
	if is_instance_valid(_train):
		var at_platform := _train.distance < 0.1
		if is_instance_valid(_journey):
			for progress in _journey.route.stations.values():
				at_platform = at_platform or absf(_train.distance-float(progress)) < 4
		_status.text = departure_status(_train.state, _train.is_at_end_of_track(), at_platform)
		_status.modulate = RailTheme.ALERT if _train.state == Train.State.ACCELERATING and not _aboard else Color.WHITE
		_speed.text = "%02d km/h" % roundi(_train.speed * 3.6)
		_train_gauge.value = 100 * _train.speed / maxf(_train.max_speed, 0.1)


static func departure_status(state: Train.State, at_end: bool, at_platform: bool = true) -> String:
	if at_end and state == Train.State.STOPPED:
		return "END OF LINE"
	if state == Train.State.STOPPED and not at_platform:
		return "STOPPED"
	return ["AT PLATFORM", "DEPARTING", "UNDER WAY", "BRAKING"][state]


## Harlow's named zones follow its authored traversal bounds. The track lane is exterior.
static func location_at(point: Vector3, aboard: bool) -> String:
	if aboard:
		return "07  /  ABOARD THE TRAIN"
	if point.z < -1.4:
		return "00  /  TRACKSIDE"
	if point.x >= 35 and point.x <= 60 and point.z <= 4.6:
		return "A  /  UPPER STORES" if point.y > 3.2 else "A  /  BONDED STORES"
	if point.x >= 70 and point.x <= 100 and point.z <= 4.6:
		return "B  /  SERVICE PASSAGE" if point.x > 81.5 and point.x < 93.5 and point.z < 0.7 else "B  /  TRANSFER HALL"
	if point.x >= 100 and point.x <= 121:
		return "03  /  FREIGHT EXCHANGE"
	if point.x > 121:
		return "00  /  OUTBOUND LINE"
	return "01  /  PLATFORM" if point.x < 33 else "02  /  GOODS YARD"


func show_message(text: String, seconds: float = 2.5) -> void:
	_message.text = text
	_message_time = maxf(seconds, 0)


func get_message() -> String:
	return _message.text if _message_time > 0 else ""


func get_location() -> String:
	return _location.text


func get_departure_status() -> String:
	return _status.text


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_target = current
