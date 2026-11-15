extends "res://tests/test_game.gd"
## New reward camps, selected weapon input, armor choices and world cleanup.


func _run() -> void:
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	game.start_run()
	game.sound.muted = true
	await _test_reward_camps()
	await _test_selected_weapon_input()
	await _test_armor_selection_and_retry()
	await _test_chapter_projectile_cleanup()
	for code in [KEY_J, KEY_ESCAPE, KEY_R]:
		_key(code, false)
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d expanded adventure integration checks." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_reward_camps() -> void:
	var expected_weapons := [&"spear", &"spear", &"seed_bomb", &"seed_bomb"]
	var expected_armor := [&"armor", &"bark_armor", &"bark_armor", &"ironwood_armor"]
	for chapter in [1, 2, 3, 4]:
		game._load_chapter(chapter)
		game._set_state(Adventure.State.PLAYING)
		game.fox.reset_at(game.level.camps[1])
		await _step(3)
		_check(game.level.camp_index == 1, "Real contact reaches each new reward checkpoint.")
		_check(
			game.equipment.active_weapon() == expected_weapons[chapter - 1],
			"Each reward camp equips the expected weapon."
		)
		_check(
			game.equipment.active_armor() == expected_armor[chapter - 1],
			"Each reward camp equips the expected armor."
		)
		_check(
			(
				game.fox.weapon_id == expected_weapons[chapter - 1]
				and game.fox.armor_id == expected_armor[chapter - 1]
			),
			"The fox's visible gear follows real reward contact."
		)
	_check(game.equipment.unlocked.size() == 6, "The ridge checkpoint has earned all six items.")


func _test_selected_weapon_input() -> void:
	for item_id in [&"bow", &"spear", &"seed_bomb"]:
		await _tap_expansion(KEY_ESCAPE)
		var button := (
			_find_button(game.hud, ForestEquipment.definition(item_id).name) as CheckButton
		)
		_check(button != null and not button.disabled, "Every earned weapon has an enabled choice.")
		if button == null:
			continue
		button.button_pressed = true
		_check(game.equipment.active_weapon() == item_id, "The pause menu selects one weapon.")
		await _tap_expansion(KEY_ESCAPE)
		game._clear_arrows()
		game.shot_cooldown = 0.0
		game.fox.reset_at(Vector2(140, 400))
		_key(KEY_J, true)
		await _step(2)
		_check(game.arrows.get_child_count() == 1, "J creates exactly one selected projectile.")
		if game.arrows.get_child_count() != 1:
			_key(KEY_J, false)
			continue
		var projectile: ForestArrow = game.arrows.get_child(0)
		_check(
			projectile.weapon_id == item_id, "J uses the chosen weapon rather than always a bow."
		)
		await _tap_expansion(KEY_ESCAPE)
		var paused_at := projectile.position
		var cooldown: float = game.shot_cooldown
		await _step(20)
		_check(projectile.position == paused_at, "Pause freezes each weapon's flight.")
		_check(game.shot_cooldown == cooldown, "Pause also freezes the selected weapon cooldown.")
		await _tap_expansion(KEY_ESCAPE)
		await _step(85)
		_check(game.arrows.get_child_count() == 0, "Held J does not repeat after the shot expires.")
		_key(KEY_J, false)
		await _step(1)


func _test_armor_selection_and_retry() -> void:
	game.equipment.recharge()
	await _tap_expansion(KEY_ESCAPE)
	var ironwood := _find_button(game.hud, "Ironwood armor") as CheckButton
	_check(ironwood != null and not ironwood.disabled, "The stronger armor can be selected.")
	if ironwood != null:
		ironwood.button_pressed = true
	await _tap_expansion(KEY_ESCAPE)
	game.fox.reset_at(Vector2(140, 536))
	for remaining in [2, 1, 0]:
		_check(game._absorb_hit(), "Ironwood armor absorbs three separate hits.")
		_check(game.equipment.armor_charge == remaining, "Armor reports each remaining block.")
	_check(not game._absorb_hit(), "A fourth hit cannot be absorbed without repair.")
	await _tap_expansion(KEY_ESCAPE)
	for item_id in [&"armor", &"bark_armor", &"ironwood_armor"]:
		var button := (
			_find_button(game.hud, ForestEquipment.definition(item_id).name) as CheckButton
		)
		if button != null:
			button.button_pressed = true
		_check(game.equipment.armor_charge == 0, "Switching armor in pause cannot refill it.")
	await _tap_expansion(KEY_ESCAPE)
	await _tap_expansion(KEY_R)
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "Retry returns to the ridge camp.")
	_check(game.equipment.armor_charge == 3, "Retry repairs all three ironwood blocks.")
	_check(game.equipment.active_weapon() == &"seed_bomb", "Retry keeps the chosen weapon.")
	_check(game.equipment.active_armor() == &"ironwood_armor", "Retry keeps the chosen armor.")


func _test_chapter_projectile_cleanup() -> void:
	game._load_chapter(3)
	game._set_state(Adventure.State.PLAYING)
	game.fox.reset_at(Vector2(140, 400))
	await _tap_expansion(KEY_J)
	_check(game.arrows.get_child_count() == 1, "The transition probe has a live seed bomb.")
	var projectile: Node = game.arrows.get_child(0)
	game._set_state(Adventure.State.CHAPTER_COMPLETE)
	game.next_chapter()
	await _step(3)
	_check(not is_instance_valid(projectile), "Chapter changes free the previous weapon and burst.")
	_check(game.arrows.get_child_count() == 0, "The new chapter begins without old projectiles.")
	_check(
		game.equipment.active_weapon() == &"seed_bomb", "Chapter changes preserve weapon choice."
	)
	_check(
		game.equipment.active_armor() == &"ironwood_armor", "Chapter changes preserve armor choice."
	)
	game.start_run()
	_check(game.equipment.unlocked.is_empty(), "Restart clears every expanded reward.")
	_check(game.fox.weapon_id == &"" and game.fox.armor_id == &"", "Restart clears visible gear.")


func _tap_expansion(code: Key) -> void:
	_key(code, true)
	await _step(1)
	_key(code, false)
	await _step(1)
