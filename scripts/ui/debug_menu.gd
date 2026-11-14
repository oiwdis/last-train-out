class_name DebugMenu
extends CanvasLayer
## In-game debug panel, toggled with F1 (or `) and closed with Esc.
##
## The menu never changes gameplay objects itself: it emits request signals and
## the Game script decides what they mean. It only reads the player and train
## to show live diagnostics. No control takes keyboard focus, so movement keys
## keep driving the player while the panel is open.

signal train_start_requested
signal train_stop_requested
signal train_reset_requested
signal departure_mode_selected(index: int)
signal max_speed_changed(value: float)
signal player_reset_requested
signal stamina_reset_requested
signal station_reset_requested
signal fog_surge_requested

const DIAGNOSTIC_ROWS: Array[String] = [
	"FPS",
	"Player speed",
	"Stamina",
	"Movement state",
	"Grounded",
	"On train",
	"Train speed",
	"Train state",
	"Departure mode",
]

@export var start_open := false
## Seconds between diagnostics refreshes.
@export var refresh_interval := 0.1

var _player: Player
var _train: Train
var _mode_buttons: Array[Button] = []
var _values: Dictionary = {}
var _refresh_timer := 0.0

@onready var _panel: Control = %Panel
@onready var _mode_row: Container = %ModeRow
@onready var _speed_slider: HSlider = %SpeedSlider
@onready var _speed_value: Label = %SpeedValue
@onready var _diagnostics: GridContainer = %Diagnostics


func _ready() -> void:
	_panel.theme = RailTheme.create()
	(%StartButton as Button).pressed.connect(func() -> void: train_start_requested.emit())
	(%StopButton as Button).pressed.connect(func() -> void: train_stop_requested.emit())
	(%ResetTrainButton as Button).pressed.connect(func() -> void: train_reset_requested.emit())
	(%ResetPlayerButton as Button).pressed.connect(func() -> void: player_reset_requested.emit())
	(%ResetStaminaButton as Button).pressed.connect(func() -> void: stamina_reset_requested.emit())
	(%ResetStationButton as Button).pressed.connect(func() -> void: station_reset_requested.emit())
	(%FogButton as Button).pressed.connect(func() -> void: fog_surge_requested.emit())
	_speed_slider.value_changed.connect(_on_speed_slider_changed)
	for row in DIAGNOSTIC_ROWS:
		var name_label := Label.new()
		name_label.text = row
		name_label.modulate = Color(0.72, 0.78, 0.85)
		_diagnostics.add_child(name_label)
		var value_label := Label.new()
		value_label.text = "-"
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_diagnostics.add_child(value_label)
		_values[row] = value_label
	_release_focus_recursively(_panel)
	set_open(start_open)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle"):
		set_open(not is_open())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_close") and is_open():
		set_open(false)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not is_open():
		return
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = refresh_interval
		_refresh()


## Gives the menu the objects it reports on.
func bind(player: Player, train: Train) -> void:
	_player = player
	_train = train
	for button in _mode_buttons:
		button.queue_free()
	_mode_buttons.clear()
	if _train == null:
		return
	var group := ButtonGroup.new()
	for i in _train.departure_modes.size():
		var mode := _train.departure_modes[i]
		var button := Button.new()
		button.text = "%s  (%s s)" % [mode.display_name, String.num(mode.time_to_full_speed, 1)]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.button_pressed = mode == _train.current_mode
		button.pressed.connect(func() -> void: departure_mode_selected.emit(i))
		_mode_row.add_child(button)
		_mode_buttons.append(button)
	_speed_slider.set_value_no_signal(_train.max_speed)
	_update_speed_label(_train.max_speed)
	if not _train.mode_changed.is_connected(_on_train_mode_changed):
		_train.mode_changed.connect(_on_train_mode_changed)
	_refresh()


func is_open() -> bool:
	return _panel.visible


func set_open(open: bool) -> void:
	_panel.visible = open
	_refresh_timer = 0.0


## Current text of a diagnostics row (used by tests).
func get_diagnostic(row: String) -> String:
	var label: Label = _values.get(row)
	return label.text if label != null else ""


func _refresh() -> void:
	_set_value("FPS", str(int(Engine.get_frames_per_second())))
	if _player != null and is_instance_valid(_player):
		var world_speed := Vector2(_player.get_world_velocity().x, _player.get_world_velocity().z).length()
		_set_value("Player speed", "%.2f m/s  (world %.1f)" % [_player.get_horizontal_speed(), world_speed])
		_set_value("Stamina", "%d / %d%s" % [
			roundi(_player.stamina.current),
			roundi(_player.stamina.max_stamina),
			"  (exhausted)" if _player.stamina.is_exhausted else "",
		])
		_set_value("Movement state", _player.get_state_name())
		_set_value("Grounded", "yes" if _player.is_grounded() else "no")
		_set_value("On train", "yes" if _player.is_on_train() else "no")
	if _train != null and is_instance_valid(_train):
		_set_value("Train speed", "%.2f m/s  (%.0f km/h)" % [_train.speed, _train.speed * 3.6])
		_set_value("Train state", Train.State.keys()[_train.state])
		_set_value("Departure mode", _train.current_mode.display_name)


func _set_value(row: String, text: String) -> void:
	var label: Label = _values.get(row)
	if label != null and label.text != text:
		label.text = text


func _on_speed_slider_changed(value: float) -> void:
	_update_speed_label(value)
	max_speed_changed.emit(value)


func _update_speed_label(value: float) -> void:
	_speed_value.text = "%.1f m/s" % value


func _on_train_mode_changed(mode: DepartureMode) -> void:
	if _train == null:
		return
	var index := _train.departure_modes.find(mode)
	for i in _mode_buttons.size():
		_mode_buttons[i].set_pressed_no_signal(i == index)


func _release_focus_recursively(node: Node) -> void:
	if node is Control:
		(node as Control).focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_release_focus_recursively(child)
