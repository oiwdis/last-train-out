class_name SupplyUI
extends CanvasLayer
signal open_changed(open: bool)
## A compact field summary; the six-slot ledger opens only when requested.

var selected_slot := 0
var selected_storage: StringName
var storage_mode := false
var _service: ScavengingSystem
var _graphics: GraphicsSettings
var _root: Control
var _shade: ColorRect
var _panel: PanelContainer
var _summary: Label
var _pack_heading: Label
var _hold_heading: Label
var _detail: Label
var _carry: Label
var _slots: Array[Button] = []
var _icons: Array[TextureRect] = []
var _slot_labels: Array[Label] = []
var _storage_scroll: ScrollContainer
var _storage_rows: VBoxContainer
var _storage_ids: Array[StringName] = []
var _deposit: Button
var _withdraw: Button
var _deposit_all: Button
var _quality: OptionButton
var _quality_description: Label
var _progress_panel: PanelContainer
var _progress_label: Label
var _progress_bar: ProgressBar
var _range_timer := 0.0


func _ready() -> void:
	layer = 40
	_build()
	set_process(false)


func bind(service: ScavengingSystem, graphics: GraphicsSettings) -> void:
	_service = service
	_graphics = graphics
	service.inventories.backpack.changed.connect(refresh)
	service.inventories.storage.changed.connect(refresh)
	service.carrying_changed.connect(func(_item: ItemDefinition) -> void: refresh())
	service.storage_requested.connect(func() -> void: open(true))
	service.search_progress.connect(_show_progress)
	service.search_finished.connect(func(_done: bool) -> void: _progress_panel.hide())
	graphics.changed.connect(_quality_changed)
	_quality_changed(graphics.current_index)
	refresh()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = RailTheme.create()
	add_child(_root)
	var summary_panel := PanelContainer.new()
	_root.add_child(summary_panel)
	_place(summary_panel, Vector2(0, 1), Vector2(30, -194), Vector2(248, 70))
	summary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary = _label(summary_panel, "TAB  /  BACKPACK     0 / 6\nABOARD  0 SUPPLIES", 12)
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_panel = PanelContainer.new()
	_root.add_child(_progress_panel)
	_place(_progress_panel, Vector2(0.5, 1), Vector2(-300, -196), Vector2(600, 72))
	_progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress_rows := VBoxContainer.new()
	_progress_panel.add_child(progress_rows)
	_progress_label = _label(progress_rows, "SEARCHING", 14)
	_progress_bar = ProgressBar.new()
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size.y = 7
	var fill := StyleBoxFlat.new()
	fill.bg_color = RailTheme.AMBER
	_progress_bar.add_theme_stylebox_override("fill", fill)
	progress_rows.add_child(_progress_bar)
	_label(progress_rows, "E / ESC cancel · moving or jumping cancels", 11, RailTheme.MUTED)
	_progress_panel.hide()
	_shade = ColorRect.new()
	_shade.color = Color(0.015, 0.025, 0.03, 0.65)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_shade)
	_panel = PanelContainer.new()
	_root.add_child(_panel)
	_place(_panel, Vector2(0.5, 0.5), Vector2(-535, -255), Vector2(1070, 510))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	_panel.add_child(rows)
	var header := HBoxContainer.new()
	rows.add_child(header)
	var title := _label(header, "SUPPLY LEDGER  /  HARLOW JUNCTION", 23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "Close  [Esc]", close)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	rows.add_child(columns)
	var pack := VBoxContainer.new()
	pack.custom_minimum_size.x = 460
	columns.add_child(pack)
	_pack_heading = _label(pack, "BACKPACK", 15, RailTheme.AMBER)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	pack.add_child(grid)
	for i in 6:
		var button := Button.new()
		button.custom_minimum_size = Vector2(148, 101)
		button.pressed.connect(select_slot.bind(i))
		grid.add_child(button)
		_slots.append(button)
		var content := VBoxContainer.new()
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 6
		content.offset_right = -6
		content.offset_top = 6
		content.offset_bottom = -6
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		_icons.append(icon)
		var label := _label(content, "%d / EMPTY" % (i + 1), 13)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slot_labels.append(label)
	var pack_actions := HBoxContainer.new()
	pack.add_child(pack_actions)
	_button(pack_actions, "Drop one  [Q]", func() -> void: _service.drop_slot(selected_slot))
	_button(pack_actions, "Drop stack", func() -> void: _service.drop_slot(selected_slot, true))
	_deposit = _button(pack_actions, "Deposit selected", func() -> void: _service.deposit_slot(selected_slot))
	var hold := VBoxContainer.new()
	hold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(hold)
	_hold_heading = _label(hold, "FIELD NOTES", 15, RailTheme.AMBER)
	_storage_scroll = ScrollContainer.new()
	_storage_scroll.custom_minimum_size = Vector2(490, 205)
	_storage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hold.add_child(_storage_scroll)
	_storage_rows = VBoxContainer.new()
	_storage_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_storage_scroll.add_child(_storage_rows)
	_detail = _label(hold, "Search marked containers to find supplies.", 15)
	_detail.custom_minimum_size = Vector2(480, 190)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hold_actions := HBoxContainer.new()
	hold.add_child(hold_actions)
	_withdraw = _button(hold_actions, "Withdraw selected  [Enter]", _withdraw_selected)
	_deposit_all = _button(hold_actions, "Deposit all + cargo  [R]", func() -> void: _service.deposit_all())
	_carry = _label(rows, "HANDS FREE · heavy cargo is carried separately from the backpack", 14, RailTheme.MUTED)
	var settings := HBoxContainer.new()
	settings.add_theme_constant_override("separation", 12)
	rows.add_child(settings)
	_label(settings, "GRAPHICS  [F2]", 13, RailTheme.MUTED)
	_quality = OptionButton.new()
	for name in ["Low", "Medium", "High"]:
		_quality.add_item(name)
	_quality.item_selected.connect(func(index: int) -> void: _graphics.set_preset(index, true))
	settings.add_child(_quality)
	_quality_description = _label(settings, "", 12, RailTheme.MUTED)
	_quality_description.custom_minimum_size.x = 680
	_quality_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(rows, "1–6 select pack · ↑/↓ select storage · Enter transfer · Q drop one · R deposit all · Tab / Esc close", 12, RailTheme.MUTED)
	_label(rows, "The world keeps moving while this ledger is open. Close it to move.", 11, RailTheme.MUTED)
	_panel.hide()
	_shade.hide()


func _place(control: Control, anchor: Vector2, offset: Vector2, dimensions: Vector2) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + dimensions.x
	control.offset_bottom = offset.y + dimensions.y


func add_camera_settings(camera: ExplorationCamera) -> void:
	var rows := _panel.get_child(0)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 12)
	rows.add_child(strip)
	_label(strip, "CAMERA", 12, RailTheme.MUTED)
	var perspective := OptionButton.new()
	perspective.add_item("First person")
	perspective.add_item("Third person")
	perspective.select(camera.settings.default_perspective)
	strip.add_child(perspective)
	perspective.item_selected.connect(func(index: int) -> void:
		camera.settings.default_perspective = index
		camera.request_perspective(index)
		camera.apply_settings())
	for specification in [["Sensitivity", "sensitivity", 0.0005, 0.01, 0.0005], ["FOV", "first_person_fov", 60, 105, 1], ["Distance", "third_person_distance", 1.2, 5, 0.1], ["Smoothing", "smoothing", 4, 30, 1]]:
		_label(strip, specification[0], 12, RailTheme.MUTED)
		var value := SpinBox.new()
		value.min_value = specification[2]
		value.max_value = specification[3]
		value.step = specification[4]
		value.value = camera.settings.get(specification[1])
		value.custom_minimum_size.x = 90
		strip.add_child(value)
		value.value_changed.connect(func(number: float) -> void:
			camera.settings.set(specification[1], number)
			camera.apply_settings())
	_panel.offset_top = -290
	_panel.offset_bottom = 290


func _label(parent: Node, text: String, size: int, color: Color = RailTheme.PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func is_open() -> bool:
	return _panel.visible


func open(at_storage: bool = false) -> void:
	_service.cancel_search(false)
	storage_mode = at_storage and _service.storage_in_range()
	_service.player.input.blocked = true
	_service.player.input.clear()
	_panel.show()
	_shade.show()
	set_process(true)
	refresh()
	open_changed.emit(true)


func close() -> void:
	_panel.hide()
	_shade.hide()
	storage_mode = false
	set_process(false)
	if _service != null:
		_service.player.input.blocked = false
		_service.player.input.clear()
	open_changed.emit(false)


func _process(delta: float) -> void:
	_range_timer -= delta
	if _range_timer <= 0:
		_range_timer = 0.1
		if storage_mode and not _service.storage_in_range():
			close()
			_service.notice.emit("Train storage moved out of reach — ledger closed")


func _input(event: InputEvent) -> void:
	if _service == null or not event.is_pressed() or event.is_echo():
		return
	var handled := true
	if event.is_action_pressed(&"inventory_toggle"):
		if is_open():
			close()
		else:
			open()
	elif event.is_action_pressed(&"graphics_cycle"):
		_graphics.cycle()
		_service.notice.emit("Graphics: %s · Tab to view settings" % GraphicsSettings.PRESETS[_graphics.current_index].display_name)
	elif event.is_action_pressed(&"drop_cargo"):
		_service.drop_heavy()
	elif event.is_action_pressed(&"drop_item"):
		_service.drop_slot(selected_slot)
	elif event.is_action_pressed(&"debug_close") and (is_open() or _service.active_search != null):
		close()
		_service.cancel_search()
	elif event is InputEventKey and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
		select_slot(event.physical_keycode - KEY_1)
	elif is_open() and storage_mode and event is InputEventKey and event.physical_keycode == KEY_R:
		_service.deposit_all()
	elif is_open() and storage_mode and event.is_action_pressed(&"ui_accept"):
		if selected_storage.is_empty():
			_service.deposit_slot(selected_slot)
		else:
			_withdraw_selected()
	elif is_open() and (event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_down")):
		var step := -1 if event.is_action_pressed(&"ui_up") else 1
		if storage_mode and not _storage_ids.is_empty():
			var index := _storage_ids.find(selected_storage)
			selected_storage = _storage_ids[posmod(index + step, _storage_ids.size())]
			refresh()
		else:
			select_slot(posmod(selected_slot + step, 6))
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func select_slot(index: int) -> void:
	selected_slot = clampi(index, 0, 5)
	selected_storage = &""
	refresh()


func refresh() -> void:
	if _service == null:
		return
	var backpack := _service.inventories.backpack
	var storage := _service.inventories.storage
	var total := 0
	for amount: int in storage.totals().values():
		total += amount
	var selected := backpack.get_slot(selected_slot)
	var short_name := (selected.item as ItemDefinition).display_name if not selected.is_empty() else "Empty"
	_summary.text = "TAB / PACK  %d / 6 · %.1f kg\n%d: %s · ABOARD %d" % [backpack.used_slots(), backpack.total_weight(), selected_slot + 1, short_name, total]
	_summary.add_theme_font_size_override("font_size", 11)
	if _service.carried != null:
		_summary.text = "CARRY / %s\nG DROP · PACK %d/6 · ABOARD %d" % [_service.carried.item.display_name.to_upper(), backpack.used_slots(), total]
	_pack_heading.text = "BACKPACK  /  %d OF 6 SLOTS  /  %.1f kg" % [backpack.used_slots(), backpack.total_weight()]
	for i in 6:
		var slot := backpack.get_slot(i)
		_icons[i].texture = null if slot.is_empty() else (slot.item as ItemDefinition).icon
		_slot_labels[i].text = "%d / EMPTY\n—" % (i + 1) if slot.is_empty() else "%d / %s\n%d / %d" % [i + 1, (slot.item as ItemDefinition).display_name, slot.amount, (slot.item as ItemDefinition).stack_limit]
		_slots[i].tooltip_text = "Empty slot" if slot.is_empty() else (slot.item as ItemDefinition).tooltip()
		_slots[i].add_theme_stylebox_override("normal", RailTheme.panel(Color("304348") if i == selected_slot else Color("152931"), RailTheme.AMBER if i == selected_slot else Color("40575c")))
	_deposit.visible = storage_mode
	_withdraw.visible = storage_mode
	_deposit_all.visible = storage_mode
	_storage_scroll.visible = storage_mode
	_detail.visible = not storage_mode
	_detail.text = (selected.item as ItemDefinition).tooltip() if not selected.is_empty() else "Search containers marked SUPPLIES.\n\nFarther stores hold better finds. Heavy cargo needs two hands and slows you down.\n\nBring supplies to the marked SUPPLY HOLD on the flat car."
	_hold_heading.text = "TRAIN HOLD  /  %d SUPPLIES · %.1f kg · %d/%d SLOTS" % [total, storage.total_weight(), storage.used_slots(), storage.slot_count] if storage_mode else "FIELD NOTES / SELECTED ITEM"
	_carry.text = "HANDS FREE · heavy cargo is carried separately from the backpack" if _service.carried == null else "CARRYING %s · %.1f kg · 2.5 m/s · G to drop · set down before climbing" % [_service.carried.item.display_name.to_upper(), _service.carried.item.weight]
	if storage_mode and is_open():
		_rebuild_storage()


func _rebuild_storage() -> void:
	for child in _storage_rows.get_children():
		_storage_rows.remove_child(child)
		child.queue_free()
	_storage_ids.clear()
	for id in ItemCatalog.IDS:
		var count := _service.inventories.storage.count(id)
		if count == 0:
			continue
		_storage_ids.append(id)
		var item := ItemCatalog.find(id)
		var button := _button(_storage_rows, "%s    × %d%s" % [item.display_name, count, "    HEAVY" if item.heavy else ""], func() -> void:
			selected_storage = id
			refresh())
		button.icon = item.icon
		button.add_theme_constant_override("icon_max_width", 28)
		button.expand_icon = true
		button.tooltip_text = item.tooltip()
		if selected_storage == id:
			button.add_theme_stylebox_override("normal", RailTheme.panel(Color("304348"), RailTheme.AMBER))
	if not _storage_ids.has(selected_storage):
		selected_storage = &""
	if _storage_ids.is_empty():
		_label(_storage_rows, "The hold is empty. Deposit supplies with R.", 14, RailTheme.MUTED)


func _withdraw_selected() -> void:
	for i in _service.inventories.storage.slot_count:
		var slot := _service.inventories.storage.get_slot(i)
		if not slot.is_empty() and (slot.item as ItemDefinition).id == selected_storage:
			_service.withdraw_slot(i)
			return


func _show_progress(title: String, fraction: float) -> void:
	_progress_panel.show()
	_progress_label.text = "SEARCHING / %s" % title.to_upper()
	_progress_bar.value = fraction * 100


func _quality_changed(index: int) -> void:
	_quality.select(index)
	_quality_description.text = GraphicsSettings.PRESETS[index].description
