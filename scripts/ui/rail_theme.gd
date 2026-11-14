class_name RailTheme
extends RefCounted
## A single restrained palette and control vocabulary for player and developer UI.

const PAPER := Color("e0e5dc")
const MUTED := Color("a1b4b9")
const AMBER := Color("e9b568")
const ALERT := Color("ed8c72")
const PANEL := Color(0.035, 0.065, 0.08, 0.94)


static func panel(fill: Color = PANEL, border: Color = Color("40575c")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", AMBER)
	theme.set_stylebox("normal", "Button", panel(Color("152931")))
	theme.set_stylebox("hover", "Button", panel(Color("263e46"), AMBER))
	theme.set_stylebox("pressed", "Button", panel(Color("304348"), AMBER))
	theme.set_stylebox("panel", "PanelContainer", panel())
	return theme
