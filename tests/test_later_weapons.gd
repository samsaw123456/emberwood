extends "res://tests/test_expansion.gd"
## Actual checkpoint contact and keyboard shooting for the later weapon rewards.


func _run() -> void:
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	game.start_run()
	game.sound.muted = true
	for reward in [[6, &"thorn_fan", 3], [16, &"sunwood_lance", 1]]:
		await _test_later_weapon(reward[0], reward[1], reward[2])
	game.start_run()
	_check(game.equipment.unlocked.is_empty(), "Restart removes later weapon rewards.")
	_check(game.fox.weapon_id.is_empty(), "Restart removes the new weapon artwork.")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d later weapon reward and keyboard checks." % checks)
		quit(0)
	else:
		for message in failures:
			push_error(message)
		quit(1)


func _test_later_weapon(chapter: int, weapon: StringName, count: int) -> void:
	game._load_chapter(chapter)
	game._set_state(Adventure.State.PLAYING)
	_check(
		not game.equipment.is_unlocked(weapon), "The weapon stays locked before its reward camp."
	)
	game.fox.reset_at(game.level.camps[1])
	await _step(3)
	_check(game.equipment.active_weapon() == weapon, "Touching the new camp equips its weapon.")
	_check(game.fox.weapon_id == weapon, "The earned weapon appears on the fox.")
	game.fox.reset_at(Vector2(140, 220))
	game._clear_arrows()
	game.shot_cooldown = 0
	_key(KEY_J, true)
	await _step(2)
	_check(game.arrows.get_child_count() == count, "One J press creates the weapon's full volley.")
	_key(KEY_J, false)
	await _step(1)
	_key(KEY_J, true)
	await _step(1)
	_check(
		game.arrows.get_child_count() == count,
		"Rapid repeated presses respect the volley cooldown."
	)
	await _tap_expansion(KEY_ESCAPE)
	var locations: Array[Vector2] = []
	for projectile in game.arrows.get_children():
		locations.append(projectile.position)
	var cooldown: float = game.shot_cooldown
	await _step(20)
	for index in game.arrows.get_child_count():
		_check(
			game.arrows.get_child(index).position == locations[index],
			"Pause freezes every new projectile."
		)
	_check(game.shot_cooldown == cooldown, "Pause freezes the new cooldown.")
	await _tap_expansion(KEY_ESCAPE)
	await _step(170)
	_check(game.arrows.get_child_count() == 0, "Held input never repeats; all shots expire.")
	_key(KEY_J, false)
	await _tap_expansion(KEY_R)
	await _step(55)
	_check(game.equipment.active_weapon() == weapon, "Retry preserves the earned weapon.")
	game._load_chapter(chapter + 1)
	game._set_state(Adventure.State.PLAYING)
	_check(
		game.equipment.active_weapon() == weapon, "The selected weapon carries to the next level."
	)
	_check(game.arrows.get_child_count() == 0, "Chapter changes leave no stray volley.")
