class_name ForestHUD
extends CanvasLayer
## Readable game controls and clear lettering over the forest.

signal lan_requested
signal host_requested
signal join_requested(address: String)
signal lan_start_requested
signal leave_requested
signal message_shown(message: String)

signal start_requested
signal resume_requested
signal restart_requested
signal pause_requested
signal next_requested
signal sound_toggled(muted: bool)
signal motion_toggled(reduced: bool)
signal equipment_toggled(item_id: StringName, equipped: bool)

const TEXT_FONT := preload("res://assets/fonts/DejaVuSans.ttf")
const BOLD_FONT := preload("res://assets/fonts/DejaVuSans-Bold.ttf")
const TEXT := Color("f5f0d9")
const QUIET_TEXT := Color("d1ddc6")
const GOLD := Color("efc16f")
const FOREST := Color("203c34")
const EDGE := Color("738c60")

var lan_session := false
var lan_host := false
var lobby_visible := false

var muted := false:
	set(value):
		muted = value
		if is_instance_valid(_sound_toggle):
			_sound_toggle.set_pressed_no_signal(not muted)

var reduced_motion := false:
	set(value):
		reduced_motion = value
		if is_instance_valid(_motion_toggle):
			_motion_toggle.set_pressed_no_signal(reduced_motion)

var _lan_error: Label
var _best := 0.0
var _screen: Control
var _overlay: Control
var _header: Control
var _footer: Control
var _acorn_label: Label
var _gem_label: Label
var _time_label: Label
var _zone_label: Label
var _jump_label: Label
var _chapter_label: Label
var _equipment_label: Label
var _equipment: ForestEquipment
var _equipment_toggles: Dictionary = {}
var _equipment_details: Dictionary = {}
var _equipment_scrolls: Dictionary = {}
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _sound_toggle: CheckButton
var _motion_toggle: CheckButton
var _boss_band: PanelContainer
var _boss_count: Label
var _boss_hint: Label
var _chapter_index := 0
var _chapter_title := "Emberwood"
var _required_acorns := 3
var _boss_requested := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen = Control.new()
	# Smooth font sampling keeps normal-sized text readable at fractional scales.
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	_build_header()
	_build_footer()
	_build_toast()
	_build_boss_ledger()
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.add_child(_overlay)
	_overlay.hide()


func show_title(best: float) -> void:
	_best = best
	var menu := _open_menu(Vector2(680, 432), 0.25)
	menu.position.y = 74
	var title := _label("Emberwood", 38, GOLD, true)
	title.name = "GameTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(680, 50)
	menu.add_child(title)
	_center_text(menu, "%d levels. Find 3 acorns in each." % ForestChapters.TITLES.size(), 20, 77)
	_center_text(menu, "Earn weapons and armor at campfires.", 18, 111, QUIET_TEXT)
	var start := _button("Start adventure", true)
	start.position = Vector2(222, 169)
	start.size.x = 236
	start.pressed.connect(func() -> void: start_requested.emit())
	menu.add_child(start)
	var multiplayer_button := _button("LAN co-op · 2–4 players", false)
	multiplayer_button.position = Vector2(190, 224)
	multiplayer_button.size.x = 300
	multiplayer_button.pressed.connect(func() -> void: lan_requested.emit())
	menu.add_child(multiplayer_button)
	var settings := CenterContainer.new()
	settings.position = Vector2(0, 286)
	settings.size = Vector2(680, 44)
	settings.add_child(_settings())
	menu.add_child(settings)
	var controls := _readability_band(Vector2(0, 562), Vector2(1152, 86), 0.66)
	_overlay.add_child(controls)
	_center_text(controls, "A D or ← →: move     Space: jump twice     Shift: dash", 18, 12)
	_center_text(
		controls,
		"J: use weapon after bow reward     R: retry     Esc: gear / pause     M: sound",
		18,
		45
	)
	if best > 0:
		_center_text(menu, "Best time: " + _format_time(best), 17, 344, QUIET_TEXT)
	start.grab_focus()


func show_pause() -> void:
	var column := _menu_column(Vector2(940, 590), 0.82)
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_add_centered(column, "Paused", 28, true)
	_add_centered(
		column, "Team paused · host chooses shared gear" if lan_session else _chapter_title, 19
	)
	var resume := _button("Keep exploring", true)
	resume.pressed.connect(func() -> void: resume_requested.emit())
	column.add_child(resume)
	column.add_child(_equipment_menu())
	var restart := _button("Restart all chapters", false)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	restart.disabled = lan_session and not lan_host
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)
	actions.add_child(restart)
	if lan_session:
		var leave := _button("Close LAN game" if lan_host else "Leave LAN game", false)
		leave.pressed.connect(func() -> void: leave_requested.emit())
		actions.add_child(leave)
	column.add_child(actions)
	column.add_child(_settings())
	resume.grab_focus()
	_reveal_equipped_items.call_deferred()


func update_equipment(equipment: ForestEquipment, dash_ready: bool) -> void:
	_equipment = equipment
	var dash_text := "Dash: ready" if dash_ready else "Dash: wait or land"
	var weapon_text := "Weapon: locked"
	var armor_text := "Armor: locked"
	var weapon := equipment.active_weapon()
	var armor := equipment.active_armor()
	if not weapon.is_empty():
		weapon_text = "J: %s" % ForestEquipment.definition(weapon).name
	elif equipment.is_unlocked(&"bow"):
		weapon_text = "Weapon: off"
	if not armor.is_empty():
		armor_text = (
			"%s: %d/%d"
			% [
				ForestEquipment.definition(armor).name,
				equipment.armor_charge,
				equipment.armor_capacity()
			]
		)
	elif equipment.is_unlocked(&"armor"):
		armor_text = "Armor: off"
	_equipment_label.text = "%s    %s    %s" % [dash_text, weapon_text, armor_text]
	_sync_equipment_rows()


func show_stage_complete(
	stage_title: String, next_title: String, time_text: String, gems: int, total: int
) -> void:
	var column := _menu_column(Vector2(500, 400 if lan_session else 322))
	_add_centered(column, "Level complete", 28, true)
	_add_centered(column, stage_title, 21)
	_add_centered(column, "Time: " + time_text, 19)
	_add_centered(column, "Gems: %d of %d" % [gems, total], 19)
	var next := _button("Continue to " + next_title, true)
	next.pressed.connect(func() -> void: next_requested.emit())
	next.disabled = lan_session and not lan_host
	if next.disabled:
		next.text = "Waiting for host to continue"
	column.add_child(next)
	_add_session_exit(column)
	if not next.disabled:
		next.grab_focus()


func show_win(
	time_text: String, gems: int, total: int, deaths: int, secret: bool, secret_total: int = 0
) -> void:
	if secret_total <= 0:
		secret_total = ForestChapters.TITLES.size()
	var column := _menu_column(Vector2(550, 450 if lan_session else 376))
	_add_centered(column, "Heart of Emberwood reached!", 28, true)
	_add_centered(column, "Adventure complete", 21)
	_add_centered(column, "Time: %s    Gems: %d of %d" % [time_text, gems, total], 19)
	_add_centered(column, "Retries: %d" % deaths, 19)
	_add_centered(
		column,
		(
			("All %d fireflies found!" % secret_total)
			if secret
			else "Hidden fireflies are still waiting to be found."
		),
		18
	)
	var replay := _button("Explore again", true)
	replay.pressed.connect(func() -> void: restart_requested.emit())
	replay.disabled = lan_session and not lan_host
	if replay.disabled:
		replay.text = "Waiting for host to restart"
	column.add_child(replay)
	_add_session_exit(column)
	if not replay.disabled:
		replay.grab_focus()


func set_chapter(index: int, title: String, required_acorns: int = 3) -> void:
	_chapter_index = maxi(index, 0)
	_chapter_title = title
	_required_acorns = required_acorns
	if is_instance_valid(_chapter_label):
		_chapter_label.text = title


func hide_overlay() -> void:
	_overlay.hide()
	_header.show()
	_footer.show()
	_boss_band.visible = _boss_requested
	get_viewport().gui_release_focus()


func update_stats(
	acorns: int, gems: int, total: int, time_text: String, zone: String, jumps: int
) -> void:
	_acorn_label.text = "Acorns %d/%d" % [acorns, _required_acorns]
	_gem_label.text = "Gems %d/%d" % [gems, total]
	_time_label.text = time_text
	_zone_label.text = zone.capitalize()
	_jump_label.text = "Air jump ready" if jumps > 0 else "Land to jump again"


func update_boss(
	show_boss: bool,
	boss_health: int,
	player_health: int,
	hint: String,
	guardian_name := "Old Croak"
) -> void:
	_boss_requested = show_boss
	_boss_band.visible = show_boss and not _overlay.visible
	_boss_count.text = (
		"%s  %s    FOX  %s"
		% [guardian_name, _health_marks(boss_health), _health_marks(player_health)]
	)
	_boss_hint.text = hint


func toast(message: String, broadcast: bool = true) -> void:
	if broadcast:
		message_shown.emit(message)
	if is_instance_valid(_toast_tween):
		_toast_tween.kill()
	_toast_label.text = message
	_toast_panel.modulate.a = 1.0
	_toast_panel.show()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(_toast_panel.hide)


func _build_header() -> void:
	_header = _readability_band(Vector2.ZERO, Vector2(1152, 84), 0.24)
	_screen.add_child(_header)
	_chapter_label = _label("Emberwood", 22, TEXT, true)
	_chapter_label.position = Vector2(28, 14)
	_header.add_child(_chapter_label)
	_zone_label = _label("Mossy trail", 16, QUIET_TEXT)
	_zone_label.position = Vector2(28, 48)
	_header.add_child(_zone_label)
	_equipment_label = _label("Dash: ready     Bow: locked     Armor: locked", 16, QUIET_TEXT)
	_equipment_label.position = Vector2(440, 52)
	_equipment_label.size.x = 624
	_equipment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header.add_child(_equipment_label)
	_acorn_label = _label("Acorns 0/3", 18, TEXT)
	_gem_label = _label("Gems 0/36", 18, TEXT)
	_time_label = _label("00:00", 18, TEXT)
	var labels := [_acorn_label, _gem_label, _time_label]
	for index in labels.size():
		var label: Label = labels[index]
		label.position = Vector2(660 + index * 154, 27)
		_header.add_child(label)
	var pause := _button("Ⅱ", false)
	pause.position = Vector2(1080, 18)
	pause.custom_minimum_size = Vector2(44, 40)
	pause.tooltip_text = "Pause (Esc)"
	pause.pressed.connect(func() -> void: pause_requested.emit())
	_header.add_child(pause)


func _build_footer() -> void:
	_footer = _readability_band(Vector2(0, 588), Vector2(1152, 60), 0.55)
	_screen.add_child(_footer)
	var controls := _label(
		"A D or ← →: move    Space: double jump    Shift: dash    J: use weapon", 16, TEXT
	)
	controls.position = Vector2(24, 7)
	_footer.add_child(controls)
	var options := _label("R: retry from campfire    Esc: gear / pause    M: sound", 16, QUIET_TEXT)
	options.position = Vector2(24, 33)
	_footer.add_child(options)
	_jump_label = _label("Air jump ready", 16, QUIET_TEXT)
	_jump_label.position = Vector2(920, 7)
	_jump_label.size.x = 208
	_jump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer.add_child(_jump_label)


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.position = Vector2(226, 538)
	_toast_panel.size = Vector2(700, 48)
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_theme_stylebox_override("panel", _backing_style())
	_toast_label = _label("", 18, TEXT)
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast_label)
	_screen.add_child(_toast_panel)
	_toast_panel.hide()


func _build_boss_ledger() -> void:
	_boss_band = PanelContainer.new()
	_boss_band.position = Vector2(244, 98)
	_boss_band.size = Vector2(664, 76)
	_boss_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_band.add_theme_stylebox_override("panel", _backing_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_boss_band.add_child(column)
	_boss_count = _label("", 18, GOLD, true)
	_boss_hint = _label("", 17, TEXT)
	_boss_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_boss_count)
	column.add_child(_boss_hint)
	_screen.add_child(_boss_band)
	_boss_band.hide()


func _open_menu(dimensions: Vector2, shade_alpha := 0.6) -> Control:
	for child in _overlay.get_children():
		_overlay.remove_child(child)
		child.queue_free()
	_sound_toggle = null
	_motion_toggle = null
	_equipment_toggles.clear()
	_equipment_details.clear()
	_equipment_scrolls.clear()
	_header.hide()
	_footer.hide()
	_boss_band.hide()
	_toast_panel.hide()
	var shade := _readability_band(Vector2.ZERO, Vector2(1152, 648), shade_alpha)
	_overlay.add_child(shade)
	var menu := Control.new()
	menu.position = (Vector2(1152, 648) - dimensions) / 2
	menu.size = dimensions
	_overlay.add_child(menu)
	_overlay.show()
	return menu


func _menu_column(dimensions: Vector2, shade_alpha := 0.6) -> VBoxContainer:
	var menu := _open_menu(dimensions, shade_alpha)
	var column := VBoxContainer.new()
	column.size = dimensions
	column.add_theme_constant_override("separation", 21)
	menu.add_child(column)
	return column


func _settings() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 24)
	_sound_toggle = _toggle("Sound", not muted)
	_sound_toggle.toggled.connect(
		func(enabled: bool) -> void:
			muted = not enabled
			sound_toggled.emit(muted)
	)
	row.add_child(_sound_toggle)
	_motion_toggle = _toggle("Gentle motion", reduced_motion)
	_motion_toggle.tooltip_text = "Reduce particles and decorative movement."
	_motion_toggle.toggled.connect(
		func(enabled: bool) -> void:
			reduced_motion = enabled
			motion_toggled.emit(reduced_motion)
	)
	row.add_child(_motion_toggle)
	return row


func _equipment_menu() -> VBoxContainer:
	var equipment_menu := VBoxContainer.new()
	equipment_menu.add_theme_constant_override("separation", 8)
	_add_centered(
		equipment_menu, "Choose one weapon and one armor. New camps and retries repair armor.", 16
	)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	equipment_menu.add_child(columns)
	for category in [&"weapon", &"armor"]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 6)
		var title := (
			"Weapons · scroll for more" if category == &"weapon" else "Armor · scroll for more"
		)
		column.add_child(_label(title, 20, TEXT, true))
		columns.add_child(column)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size.y = 260
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_NONE
		column.add_child(scroll)
		_equipment_scrolls[category] = scroll
		var rows := VBoxContainer.new()
		rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rows.add_theme_constant_override("separation", 6)
		scroll.add_child(rows)
		for item in ForestEquipment.ITEMS:
			if item.category == category:
				var row := _equipment_row(item)
				rows.add_child(row)
				var toggle: CheckButton = _equipment_toggles[item.id]
				toggle.focus_entered.connect(scroll.ensure_control_visible.bind(row))
	_sync_equipment_rows()
	return equipment_menu


func _reveal_equipped_items() -> void:
	if _equipment == null:
		return
	for category in [&"weapon", &"armor"]:
		var selected := (
			_equipment.active_weapon() if category == &"weapon" else _equipment.active_armor()
		)
		if not _equipment_scrolls.has(category) or not _equipment_toggles.has(selected):
			continue
		var scroll: ScrollContainer = _equipment_scrolls[category]
		var toggle: CheckButton = _equipment_toggles[selected]
		scroll.ensure_control_visible(toggle.get_parent())


func _equipment_row(item: Dictionary) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.custom_minimum_size.y = 78
	row.add_theme_constant_override("separation", 0)
	var toggle := _toggle(item.name, false)
	toggle.custom_minimum_size.y = 36
	toggle.toggled.connect(
		func(enabled: bool) -> void:
			equipment_toggled.emit(item.id, enabled)
			_sync_equipment_rows()
	)
	row.add_child(toggle)
	var detail := _label("", 16, QUIET_TEXT)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(detail)
	_equipment_toggles[item.id] = toggle
	_equipment_details[item.id] = detail
	return row


func _sync_equipment_rows() -> void:
	for item in ForestEquipment.ITEMS:
		if not _equipment_toggles.has(item.id):
			continue
		var toggle: CheckButton = _equipment_toggles[item.id]
		var detail: Label = _equipment_details[item.id]
		var unlocked := _equipment != null and _equipment.is_unlocked(item.id)
		var equipped := _equipment != null and _equipment.is_equipped(item.id)
		toggle.disabled = not unlocked or (lan_session and not lan_host)
		toggle.set_pressed_no_signal(equipped)
		toggle.tooltip_text = item.description if unlocked else item.unlock_hint
		var status: String = item.unlock_hint
		if unlocked:
			status = "Equipped" if equipped else "Available"
			if equipped and item.category == &"armor":
				status += " · %d/%d hits left" % [_equipment.armor_charge, item.capacity]
		detail.text = "%s\n%s" % [item.description, status]


func _toggle(text: String, enabled: bool) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.button_pressed = enabled
	toggle.add_theme_font_override("font", TEXT_FONT)
	toggle.add_theme_font_size_override("font_size", 17)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		toggle.add_theme_color_override(state, TEXT)
	toggle.add_theme_stylebox_override("focus", _focus_style())
	return toggle


func _label(text: String, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", BOLD_FONT if bold else TEXT_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("142a28"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _center_text(parent: Control, text: String, font_size: int, y: float, color := TEXT) -> void:
	var label := _label(text, font_size, color)
	label.position.y = y
	label.size.x = parent.size.x
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)


func _add_centered(parent: Control, text: String, font_size: int, bold := false) -> void:
	var label := _label(text, font_size, TEXT, bold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)


func _button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", BOLD_FONT if primary else TEXT_FONT)
	button.add_theme_font_size_override("font_size", 18)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, TEXT)
	var normal := _backing_style()
	normal.bg_color = FOREST if primary else Color("1d302b")
	normal.border_color = EDGE
	normal.set_border_width_all(2)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("39573f")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("152c28")
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", _focus_style())
	return button


func _backing_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.16, 0.14, 0.94)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _focus_style() -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = GOLD
	focus.set_border_width_all(3)
	return focus


func _readability_band(at: Vector2, dimensions: Vector2, alpha: float) -> ColorRect:
	var band := ColorRect.new()
	band.color = Color(0.03, 0.09, 0.08, alpha)
	band.position = at
	band.size = dimensions
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return band


func _health_marks(health: int) -> String:
	return "●".repeat(clampi(health, 0, 3)) + "○".repeat(3 - clampi(health, 0, 3))


func _format_time(seconds: float) -> String:
	var whole_seconds := int(seconds)
	return "%02d:%02d" % [whole_seconds / 60, whole_seconds % 60]


func show_lan() -> void:
	var column := _menu_column(Vector2(800, 530), 0.82)
	column.add_theme_constant_override("separation", 16)
	_add_centered(column, "LAN co-op · 2–4 players", 28, true)
	_add_centered(column, "Each player needs Emberwood on the same Wi-Fi or wired network.", 18)
	_add_centered(column, "Share acorns, gear and campfires. A tumble returns the whole team.", 17)
	var host_button := _button("Host a game", true)
	host_button.pressed.connect(func() -> void: host_requested.emit())
	column.add_child(host_button)
	_add_centered(column, "Or enter the host's address", 18)
	var address := LineEdit.new()
	address.name = "HostAddress"
	address.placeholder_text = "192.168.1.20"
	address.max_length = 45
	address.keep_editing_on_text_submit = true
	address.custom_minimum_size = Vector2(400, 44)
	address.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	address.add_theme_font_override("font", TEXT_FONT)
	address.add_theme_font_size_override("font_size", 20)
	address.add_theme_stylebox_override("focus", _focus_style())
	address.text_submitted.connect(func(value: String) -> void: join_requested.emit(value))
	column.add_child(address)
	var join_button := _button("Join game", true)
	join_button.pressed.connect(func() -> void: join_requested.emit(address.text))
	column.add_child(join_button)
	_lan_error = _label("", 17, GOLD)
	_lan_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lan_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lan_error.custom_minimum_size.y = 44
	column.add_child(_lan_error)
	var back := _button("Back", false)
	back.pressed.connect(func() -> void: show_title(_best))
	column.add_child(back)
	host_button.grab_focus()


func lan_error(message: String) -> void:
	if is_instance_valid(_lan_error):
		_lan_error.text = message


func show_lobby(
	title: String, address: String, host_player: bool, count: int, numbers: Array = []
) -> void:
	lobby_visible = true
	var column := _menu_column(Vector2(820, 440), 0.82)
	_add_centered(column, title, 28, true)
	var details := _label(address, 19, GOLD)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)
	_add_centered(column, "".join(_player_names(count, numbers)), 22)
	_add_centered(column, "Host starts with 2–4 players. Everyone joins before the adventure.", 18)
	_add_centered(
		column, "Esc / P pauses the team. The host continues levels and chooses gear.", 17
	)
	var start := _button("Start co-op" if host_player else "Waiting for host", true)
	start.disabled = not host_player or count < 2
	start.pressed.connect(func() -> void: lan_start_requested.emit())
	column.add_child(start)
	var leave := _button("Cancel" if count == 0 else "Leave lobby", false)
	leave.pressed.connect(func() -> void: leave_requested.emit())
	column.add_child(leave)
	if not start.disabled:
		start.grab_focus()
	else:
		leave.grab_focus()


func _player_names(count: int, numbers: Array) -> PackedStringArray:
	var names := PackedStringArray()
	if numbers.is_empty():
		for index in count:
			numbers.append(index + 1)
	numbers.sort()
	for number: int in numbers:
		names.append("P%d%s     " % [number, " · Host" if number == 1 else ""])
	return names


func _add_session_exit(column: VBoxContainer) -> void:
	if not lan_session:
		return
	var leave := _button("Close LAN game" if lan_host else "Leave LAN game", false)
	leave.pressed.connect(func() -> void: leave_requested.emit())
	column.add_child(leave)
	if not lan_host:
		leave.grab_focus()
