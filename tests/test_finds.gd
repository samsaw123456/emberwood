extends "res://tests/test_game.gd"
## Exercise discovery rewards through dash input, collisions and real state transitions.


func _run() -> void:
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	game.sound.muted = true
	await _test_chest()
	await _test_shield()
	await _test_companion()
	await _test_progression()
	_test_placement()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print(
			(
				"PASS: %d discovery checks: chests, shields, friend, walls, pause, retry and all trails."
				% checks
			)
		)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_chest() -> void:
	for direction in [1, -1]:
		game.start_run()
		game.fox.reset_at(game.finds.chest)
		await _step(3)
		_check(not game.finds.chest_open, "Walking into a chest never spends its reward.")
		game.fox.reset_at(game.finds.chest + Vector2(-direction * 65, 0))
		await _step(3)
		var move_key := KEY_RIGHT if direction == 1 else KEY_LEFT
		_key(move_key, true)
		await _step(2)
		_key(KEY_SHIFT, true)
		await _step(10)
		_key(KEY_SHIFT, false)
		_key(move_key, false)
		_check(
			game.finds.chest_open and game.finds.leaf_shield,
			"A real dash opens the chest from either side."
		)
		game.finds.absorb_hit()
		game.fox.reset_at(game.finds.chest)
		await _step(3)
		_key(KEY_SHIFT, true)
		await _step(3)
		_key(KEY_SHIFT, false)
		_check(
			not game.finds.leaf_shield, "Dashing through an open chest cannot duplicate its shield."
		)
	game.start_run()
	game.fox.reset_at(game.finds.chest - Vector2(60, 0))
	await _step(3)
	game.pause_run()
	var frozen: float = game.finds.age
	_key(KEY_SHIFT, true)
	await _step(12)
	_key(KEY_SHIFT, false)
	_check(
		not game.finds.chest_open and game.finds.age == frozen,
		"Pause freezes rewards and their animation."
	)
	game.resume_run()


func _test_shield() -> void:
	game.start_run()
	game.equipment.rewards_at(0, 2)
	game._sync_equipment()
	game.finds.chest_open = true
	game.finds.leaf_shield = true
	game.fox.reset_at(Vector2(550, 536))
	game.invincible_left = 0
	await _step(1)
	_check(
		game.state == Adventure.State.PLAYING and not game.finds.leaf_shield,
		"A leaf shield blocks actual spike contact."
	)
	_check(game.equipment.armor_charge == 1, "The extra shield preserves worn armor.")
	game.invincible_left = 0
	await _step(1)
	_check(game.equipment.armor_charge == 0, "The next hit spends ordinary armor.")
	game.invincible_left = 0
	await _step(1)
	_check(
		game.state == Adventure.State.RESPAWNING, "A third unprotected hit triggers normal failure."
	)
	await _step(55)
	_check(
		game.finds.chest_open and not game.finds.leaf_shield,
		"Retry preserves the opened chest without refilling its shield."
	)
	game.finds.leaf_shield = true
	game.fox.reset_at(Vector2(1100, 750))
	await _step(1)
	_check(game.state == Adventure.State.RESPAWNING, "Shields do not prevent falling into a pit.")
	await _step(55)
	_check(not game.finds.leaf_shield, "A fall clears the carried shield.")
	game._load_chapter(2)
	game._set_state(Adventure.State.PLAYING)
	game.finds.leaf_shield = true
	game.invincible_left = 0
	game._on_boss_hit()
	_check(
		game.player_health == 3 and not game.finds.leaf_shield,
		"The same shield protects against a boss hit."
	)


func _test_companion() -> void:
	game.start_run()
	game.level.gems.assign([Vector2(220, 510), Vector2(270, 510)])
	await _step(3)
	_check(
		game.level.taken_gems.is_empty(), "Distant gems are not collected before finding a friend."
	)
	game.level.secret = game.fox.position - Vector2(0, 20)
	await _step(3)
	_check(
		game.finds.companion and game.level.secret_found,
		"Touching a real hidden firefly recruits it."
	)
	_check(game.level.taken_gems.size() == 1, "The friend collects only gems inside its range.")
	await _step(10)
	_check(game.level.taken_gems.size() == 1, "Already fetched gems cannot be counted twice.")
	game.pause_run()
	game.level.add_platform(Rect2(180, 435, 10, 101), "wall")
	await _step(3)
	game.level.taken_gems.clear()
	game.resume_run()
	await _step(3)
	_check(game.level.taken_gems.is_empty(), "A solid wall blocks remote gem collection.")
	var wall: ForestPlatform = game.level.platforms.pop_back()
	wall.queue_free()
	game.pause_run()
	await _step(10)
	_check(game.level.taken_gems.is_empty(), "The friend cannot gather gems while paused.")
	game.resume_run()
	await _step(3)
	_check(
		game.level.taken_gems.size() == 1,
		"Removing the obstruction permits collection after resume."
	)
	game.level.taken_gems.clear()
	game.level.gems.assign([Vector2(140, 560)])
	await _step(3)
	_check(game.level.taken_gems.is_empty(), "Solid ground also blocks the magnet.")
	game.level.acorns.assign([Vector2(220, 510)])
	game.level.secret_found = false
	game.level.secret = Vector2(220, 510)
	await _step(3)
	_check(
		game.level.taken_acorns.is_empty() and not game.level.secret_found,
		"The companion never fetches required acorns or hidden fireflies."
	)
	game._respawn("Retry test")
	await _step(55)
	_check(game.finds.companion, "The rescued friend survives retry.")


func _test_progression() -> void:
	game.start_run()
	game.finds.companion = true
	game.finds.leaf_shield = true
	game.finds.chest_open = true
	for index in game.level.acorns.size():
		game.level.taken_acorns[index] = true
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(
		game.state == Adventure.State.CHAPTER_COMPLETE,
		"Optional discoveries do not add gate requirements."
	)
	game.next_chapter()
	await _step(3)
	_check(
		game.stage_index == 1 and game.finds.companion, "The friend follows into the next trail."
	)
	_check(
		not game.finds.chest_open and not game.finds.leaf_shield,
		"The next trail has one fresh chest and no carried shield."
	)
	game.start_run()
	_check(
		not game.finds.companion and not game.finds.leaf_shield,
		"A new adventure resets discovery rewards."
	)


func _test_placement() -> void:
	for chapter in 20:
		game._load_chapter(chapter)
		var bounds: Rect2 = game.finds.chest_bounds()
		var supported := false
		for platform in game.level.platforms:
			if platform.kind == "ground":
				var surface := Rect2(platform.position, platform.size)
				if (
					surface.position.y == bounds.end.y
					and surface.position.x <= bounds.position.x
					and surface.end.x >= bounds.end.x
				):
					supported = true
		_check(supported, "Every chest rests fully on existing ground: %d" % chapter)
		for spike in game.level.spikes:
			_check(
				not bounds.grow(25).intersects(spike), "Chest and approach stay clear of spikes."
			)
		for camp in game.level.camps:
			_check(not bounds.grow(30).has_point(camp), "Chest does not obscure a camp.")
		if is_instance_valid(game.boss):
			_check(bounds.end.x < game.boss.arena_min, "Treasure stays outside boss arenas.")
