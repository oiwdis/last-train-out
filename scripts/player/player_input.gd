class_name PlayerInput
extends Node
## Samples the Input Map once per physics tick.
##
## The Player only ever reads these fields, so automated tests and scripted
## demos can drive the character by setting [member scripted] and writing the
## fields directly instead of faking key events.

## x: right (+) / left (-).  y: out of the scene (+, toward the camera) / into the scene (-).
var move := Vector2.ZERO
var sprint_held := false
var jump_held := false
## True only on the tick the jump button went down.
var jump_pressed := false
## True only on the tick the interact button went down.
var interact_pressed := false

## When true the fields are left untouched by [method sample].
var scripted := false
## Inventory/settings panels release keys instead of pausing the moving world.
var blocked := false


func sample() -> void:
	if blocked:
		clear()
		return
	if scripted:
		return
	move = Input.get_vector(&"move_left", &"move_right", &"move_in", &"move_out")
	sprint_held = Input.is_action_pressed(&"sprint")
	jump_held = Input.is_action_pressed(&"jump")
	jump_pressed = Input.is_action_just_pressed(&"jump")
	interact_pressed = Input.is_action_just_pressed(&"interact")


## Clears one-tick edge flags. Called by the Player after it consumed them.
func end_tick() -> void:
	jump_pressed = false
	interact_pressed = false


## Releases everything (used when control is taken away, e.g. on reset).
func clear() -> void:
	move = Vector2.ZERO
	sprint_held = false
	jump_held = false
	jump_pressed = false
	interact_pressed = false


# --- Scripted helpers (tests / demo recordings) -----------------------------

func script_move(x: float, depth: float = 0.0, sprint: bool = false) -> void:
	scripted = true
	move = Vector2(x, depth).limit_length(1.0)
	sprint_held = sprint


func script_jump(hold: bool = true) -> void:
	scripted = true
	jump_pressed = true
	jump_held = hold


func script_interact() -> void:
	scripted = true
	interact_pressed = true
