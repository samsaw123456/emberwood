extends "res://tests/test_expansion.gd"
## Real reward contact and spike damage for every later armor set.


func _run() -> void:
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	game.start_run()
	game.sound.muted = true
	for reward in [
		[5, &"reed_mail", 4],
		[10, &"frost_armor", 5],
		[12, &"stoneplate", 6],
		[15, &"copperbark_armor", 7],
		[18, &"sunleaf_armor", 8]
	]:
		await _test_armor_reward(reward[0], reward[1], reward[2])
	_check(
		game.equipment.unlocked.size() == 11, "The final armor camp has unlocked all eleven items."
	)
	game.start_run()
	_check(game.equipment.unlocked.is_empty(), "Restart clears all later armor unlocks.")
	_check(game.fox.armor_id == &"", "Restart removes the final armor artwork.")
	_check(game.equipment.armor_charge == 0, "Restart removes all remaining protection.")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d twenty-level armor and retry checks." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_armor_reward(chapter: int, item_id: StringName, capacity: int) -> void:
	game._load_chapter(chapter)
	game._set_state(Adventure.State.PLAYING)
	_check(not game.equipment.is_unlocked(item_id), "Later armor is locked before its camp.")
	game.fox.reset_at(game.level.camps[1])
	await _step(3)
	_check(game.level.camp_index == 1, "The fox reaches the new armor's camp by contact.")
	_check(game.equipment.active_armor() == item_id, "The new camp equips the earned armor.")
	_check(game.fox.armor_id == item_id, "The fox displays the new armor.")
	_check(game.equipment.armor_charge == capacity, "The new camp fully charges its armor.")
	var acorns: Dictionary = game.level.taken_acorns.duplicate()
	var retries: int = game.deaths
	for remaining in range(capacity - 1, -1, -1):
		await _touch_spike()
		_check(game.state == Adventure.State.PLAYING, "Each charged block prevents a spike retry.")
		_check(
			game.equipment.armor_charge == remaining, "Each real spike contact spends one block."
		)
		_check(game.invincible_left > 0, "Every blocked hit grants recovery time.")
	await _test_spent_choices(item_id)
	await _touch_spike()
	_check(game.state == Adventure.State.RESPAWNING, "Spent armor permits a real failure.")
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "Failure returns to the new chapter's camp.")
	_check(game.deaths == retries + 1, "The full armor test causes exactly one retry.")
	_check(game.equipment.active_armor() == item_id, "Retry retains the selected later armor.")
	_check(
		game.equipment.armor_charge == capacity, "Retry restores every block of the selected armor."
	)
	_check(game.level.taken_acorns == acorns, "Retry preserves the chapter's collectibles.")
	game.fox.reset_at(game.level.camps[0])
	await _step(3)
	_check(game.equipment.active_armor() == item_id, "Returning to an older camp preserves gear.")


func _test_spent_choices(item_id: StringName) -> void:
	await _tap_expansion(KEY_ESCAPE)
	_check(game.state == Adventure.State.PAUSED, "Gear can be changed during a safe pause.")
	game._toggle_equipment(&"armor", true)
	game._toggle_equipment(item_id, true)
	_check(game.equipment.armor_charge == 0, "Swapping to older armor and back cannot recharge it.")
	_check(game.fox.armor_id == item_id, "The returned choice restores the right artwork.")
	await _tap_expansion(KEY_ESCAPE)


func _touch_spike() -> void:
	var spike: Rect2 = game.level.spikes[0]
	game.fox.reset_at(Vector2(spike.get_center().x, ForestLevel.FLOOR_Y))
	game.invincible_left = 0.0
	await _step(1)
