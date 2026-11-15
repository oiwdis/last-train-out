class_name FogHUD
extends CanvasLayer
## Remains visible above inventory panels; no modal UI freezes the fog.
var system: FogSystem
var player_id := ""
var status: Label
var details: Label
var warning: Label
var debug: Label
var panel: PanelContainer
var _refresh := 0.0

func bind(authority: FogSystem, id: String) -> void:
	system = authority
	player_id = id
	layer = 45
	panel = PanelContainer.new()
	panel.theme = RailTheme.create()
	panel.position = Vector2(30, 118)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 17)
	column.add_child(status)
	details = Label.new()
	details.add_theme_font_size_override("font_size", 13)
	column.add_child(details)
	warning = Label.new()
	warning.add_theme_color_override("font_color", RailTheme.AMBER)
	warning.add_theme_font_size_override("font_size", 13)
	column.add_child(warning)
	debug = Label.new()
	debug.visible = false
	debug.add_theme_font_size_override("font_size", 12)
	column.add_child(debug)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3:
			debug.visible = not debug.visible
		if event.physical_keycode == KEY_R and system.players[player_id].exposure.dead:
			system.game.reset_station()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_refresh -= delta
	if _refresh > 0 or not system.players.has(player_id):
		return
	_refresh = 0.1
	var dose := system.players[player_id].exposure as FogExposure
	var sim := system.simulation
	var state := int(sim.danger(minf(dose.progress, system.train_progress)))
	var gap := minf(dose.progress, system.train_progress) - sim.front
	status.text = ["FOG DISTANT", "FOG APPROACHING", "FOG CRITICAL · RETURN TO TRAIN", "FOG EXPOSURE · SEEK SHELTER"][state]
	status.modulate = RailTheme.MUTED if state == 0 else (RailTheme.AMBER if state == 1 else RailTheme.ALERT)
	panel.modulate.a = 0.8 if state == 0 else 1.0
	details.text = "Escape route: ~%d m clear" % (maxi(0, roundi(gap / 10)) * 10) if gap > 0 else "Escape route engulfed · keep steam up"
	if dose.exposure > 0.5 or dose.health < 99.9:
		details.text += "\nHealth %d%% · Exposure %d%% · %s" % [ceili(dose.health), roundi(dose.exposure), dose.shelter]
	warning.text = ""
	if sim.pending_event != "":
		warning.text = "%s IN %ds" % [sim.pending_event.to_upper(), ceili(sim.warning_left)]
	elif sim.event != "":
		warning.text = "%s · %ds" % [sim.event.to_upper(), ceili(sim.event_left)]
	if system.fuel != null and (system.fuel.amount < 20 or system.game.player.is_on_train()):
		warning.text += "\nBoiler %d%% · E at bunker to burn stored coal" % roundi(100 * system.fuel.amount / system.config.fuel_capacity)
	warning.visible = warning.text != ""
	if dose.dead:
		status.text = "LOST IN THE FOG"
		details.text = "The railway keeps moving. Your run has ended."
		warning.text = "R · begin a new run"
		warning.visible = true
	debug.text = "F3 DEBUG · seed %d · %s\nfront %.2f m · train %.2f · player %.2f\nspeed %.3f m/s · time %.1f · cover %.2f\nsegment %s" % [sim.seed_value, sim.station_id, sim.front, system.train_progress, dose.progress, sim.speed, sim.elapsed, dose.protection, str(system.route.locate(sim.front))]
