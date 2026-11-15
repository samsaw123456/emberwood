extends "res://tests/test_game.gd"
## Exercise each configured arena, real projectile openings, retry and progression.


func _run() -> void:
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	game = MAIN.instantiate()
	root.add_child(game)
	game.start_run()
	game.sound.muted = true
	for chapter in ForestChapters.TITLES.size():
		_check(
			ForestChapters.has_boss(chapter) == ([2, 5, 8, 11, 14, 17].has(chapter)),
			"Exactly every third level has a guardian."
		)
	var species: Array[StringName] = []
	for chapter in [2, 5, 8, 11, 14, 17]:
		var animal: StringName = ForestChapters.guardian(chapter).animal
		_check(not species.has(animal), "Each guardian is a different animal.")
		species.append(animal)
		await _test_guardian(chapter)
	_check(species.count(&"frog") == 1, "Old Croak is the only frog.")
	game.start_run()
	_check(not is_instance_valid(game.boss), "Restart removes the last encounter.")
	_check(game.equipment.unlocked.is_empty(), "Restart clears earned gear.")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d six-guardian arena, projectile, retry and progression checks." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_guardian(chapter: int) -> void:
	game._load_chapter(chapter)
	game._set_state(Adventure.State.PLAYING)
	var boss: ForestBoss = game.boss
	_check(
		boss.species == ForestChapters.guardian(chapter).animal,
		"The encounter loads its animal artwork."
	)
	var camp: Vector2 = game.level.camps[-1]
	game.fox.reset_at(camp)
	await _step(3)
	_check(
		not boss.engaged and not is_instance_valid(game.arena_wall),
		"Missing acorns leave the way back open."
	)
	_check(not game.level.gate_open, "The guardian gate begins locked.")
	await _collect_acorns()
	game.fox.reset_at(camp)
	await _step(3)
	_check(
		boss.engaged and is_instance_valid(game.arena_wall),
		"Prepared arena entry starts the fight."
	)
	_check(
		game.hud._boss_count.text.begins_with(boss.guardian_name), "HUD names the current guardian."
	)
	_check(
		boss.cap_bounds().position.y < boss.body_bounds().position.y,
		"The visible cap can be reached from above before body contact."
	)
	_check(game.level.camp_index == game.level.camps.size() - 1, "The arena camp is saved.")
	_check(game.fox.is_on_floor(), "The arena checkpoint has solid ground.")
	game.pause_run()
	var phase_time := boss.phase_time
	await _step(20)
	_check(boss.phase_time == phase_time, "Pause freezes each guardian's timer.")
	game.resume_run()
	await _step(3)
	_check(boss.phase_time > phase_time, "Resume continues the encounter.")
	# Use real health-loss events to exercise the full retry transition.
	game.equipment.set_equipped(game.equipment.active_armor(), false)
	game._sync_equipment()
	for hit in 3:
		game.invincible_left = 0
		boss.player_hit.emit()
	_check(game.state == Adventure.State.RESPAWNING, "Three unprotected hits cause failure.")
	await _step(55)
	_check(
		game.state == Adventure.State.PLAYING and boss.health == 3 and game.player_health == 3,
		"Retry restores both combatants in every arena."
	)
	_check(game.fox.position.distance_to(camp) < 4, "Retry uses safe arena ground.")
	_check(not game.level.gate_open, "An unfinished fight stays locked after retry.")
	game.equipment.set_equipped(&"bow", true)
	game._sync_equipment()
	for hit in 3:
		game.fox.reset_at(Vector2(boss.arena_min + 400, ForestLevel.FLOOR_Y))
		game.invincible_left = 6.0
		var opened := false
		for frame in 360:
			await _step(1)
			if boss.phase == "rest":
				opened = true
				break
		_check(opened, "The guardian exposes its cap after its actual leap.")
		if not opened:
			return
		game.fox.reset_at(boss.position - Vector2(180, 0))
		game.fox.facing = 1
		game.shot_cooldown = 0
		_key(KEY_J, true)
		await _step(1)
		_key(KEY_J, false)
		await _step(30)
		_check(boss.health == 2 - hit, "A real bow shot removes one health per opening.")
	_check(boss.defeated and game.level.gate_open, "Three openings unlock the gate.")
	await _step(2)
	_check(not is_instance_valid(game.arena_wall), "Victory removes the arena barrier.")
	_key(KEY_R, true)
	await _step(1)
	_key(KEY_R, false)
	await _step(55)
	_check(boss.defeated and game.level.gate_open, "Retry preserves each earned victory.")
	_check(not game.hud._boss_band.visible, "A defeated guardian hides its health display.")
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(
		game.state == Adventure.State.CHAPTER_COMPLETE, "The cleared gate reaches chapter results."
	)
	game.next_chapter()
	await _step(2)
	_check(
		game.stage_index == chapter + 1 and not is_instance_valid(game.boss),
		"Continue frees the defeated guardian and loads the next trail."
	)
