extends "res://tests/test_game.gd"
## Keyboard focus must expose later armor without making the pause menu taller.


func _run() -> void:
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	game.start_run()
	game.sound.muted = true
	game.equipment.rewards_at(19, 1)
	game._sync_equipment()
	await _test_scroll_and_choices()
	await _test_reopen_and_retry()
	_key(KEY_TAB, false)
	_key(KEY_SPACE, false)
	_key(KEY_ESCAPE, false)
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d armor menu and recovery checks." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_scroll_and_choices() -> void:
	game.pause_run()
	await _step(3)
	var armor_scroll: ScrollContainer = game.hud._equipment_scrolls[&"armor"]
	var sunleaf: CheckButton = game.hud._equipment_toggles[&"sunleaf_armor"]
	_check(armor_scroll.scroll_vertical > 0, "Opening pause reveals the equipped later armor.")
	_check(
		_inside_scroll(armor_scroll, sunleaf), "The selected Sunleaf choice is visible on opening."
	)
	var order := [
		&"bow",
		&"spear",
		&"seed_bomb",
		&"armor",
		&"bark_armor",
		&"ironwood_armor",
		&"reed_mail",
		&"frost_armor",
		&"stoneplate",
		&"copperbark_armor",
		&"sunleaf_armor"
	]
	for item_id in order:
		await _tap_menu(KEY_TAB)
		var toggle: CheckButton = game.hud._equipment_toggles[item_id]
		_check(root.gui_get_focus_owner() == toggle, "Tab reaches each gear choice in order.")
		var category: StringName = ForestEquipment.definition(item_id).category
		var scroll: ScrollContainer = game.hud._equipment_scrolls[category]
		_check(_inside_scroll(scroll, toggle), "Focused gear scrolls fully into view.")
		await _tap_menu(KEY_SPACE)
		_check(game.equipment.is_equipped(item_id), "Space equips the visible focused choice.")
	_check(
		(
			game.equipment.active_weapon() == &"seed_bomb"
			and game.equipment.active_armor() == &"sunleaf_armor"
		),
		"All eleven keyboard choices update the actual loadout."
	)
	for text in ["Keep exploring", "Restart all chapters", "Sound", "Gentle motion"]:
		var control := _find_button(game.hud, text)
		_check(
			control != null and Rect2(0, 0, 1152, 648).encloses(control.get_global_rect()),
			"Pause actions remain on screen with all eight armor sets."
		)


func _test_reopen_and_retry() -> void:
	await _tap_menu(KEY_ESCAPE)
	_check(game.state == Adventure.State.PLAYING, "Escape resumes from the longer gear menu.")
	_check(game.fox.armor_id == &"sunleaf_armor", "The selected late armor appears on the fox.")
	for hit in 8:
		_check(game._absorb_hit(), "The equipped Sunleaf set blocks its eight hits in the game.")
	_check(not game._absorb_hit(), "The ninth hit is not absorbed by spent Sunleaf armor.")
	await _tap_menu(KEY_ESCAPE)
	var armor_scroll: ScrollContainer = game.hud._equipment_scrolls[&"armor"]
	var toggle: CheckButton = game.hud._equipment_toggles[&"sunleaf_armor"]
	_check(
		_inside_scroll(armor_scroll, toggle), "Reopening pause reveals the selected armor again."
	)
	_check(game.equipment.armor_charge == 0, "Opening equipment does not repair spent armor.")
	await _tap_menu(KEY_ESCAPE)
	await _tap_menu(KEY_R)
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "The retry finishes normally with later gear.")
	_check(game.equipment.armor_charge == 8, "Retry restores the full late-armor capacity.")
	_check(game.fox.armor_id == &"sunleaf_armor", "Retry preserves the selected visible armor.")


func _inside_scroll(scroll: ScrollContainer, control: Control) -> bool:
	return scroll.get_global_rect().grow(0.5).encloses(control.get_global_rect())


func _tap_menu(code: Key) -> void:
	_key(code, true)
	await _step(1)
	_key(code, false)
	await _step(1)
