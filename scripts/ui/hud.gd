class_name Hud
extends CanvasLayer
## Minimal play HUD: stamina bar, contextual interaction prompt and short
## status messages. Deliberately tiny - the real HUD belongs to a later milestone.

@export var prompt_refresh_interval := 0.1

var _player: Player
var _prompt_timer := 0.0
var _message_time := 0.0

@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _prompt: Label = %Prompt
@onready var _message: Label = %Message


func _ready() -> void:
	_prompt.text = ""
	_message.text = ""
	_message.modulate.a = 0.0


func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		_message.modulate.a = clampf(_message_time / 0.4, 0.0, 1.0)
	if _player == null or not is_instance_valid(_player):
		return
	_prompt_timer -= delta
	if _prompt_timer <= 0.0:
		_prompt_timer = prompt_refresh_interval
		var text := _player.get_interaction_prompt()
		if _prompt.text != text:
			_prompt.text = text
	# Fade the bar out while it is full so it only draws attention when it matters.
	var stamina := _player.stamina
	var wanted_alpha := 0.25 if stamina.current >= stamina.max_stamina else 1.0
	_stamina_bar.modulate.a = move_toward(_stamina_bar.modulate.a, wanted_alpha, delta * 3.0)
	_stamina_bar.self_modulate = Color(1.0, 0.45, 0.35) if stamina.is_exhausted else Color.WHITE


func bind(player: Player) -> void:
	_player = player
	if _player == null:
		return
	_stamina_bar.max_value = _player.stamina.max_stamina
	_stamina_bar.value = _player.stamina.current
	if not _player.stamina.changed.is_connected(_on_stamina_changed):
		_player.stamina.changed.connect(_on_stamina_changed)


## Shows a short status line at the top of the screen.
func show_message(text: String, seconds: float = 2.5) -> void:
	_message.text = text
	_message_time = seconds
	_message.modulate.a = 1.0


func get_message() -> String:
	return _message.text if _message_time > 0.0 else ""


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
