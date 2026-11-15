extends "res://tests/test_route.gd"
## Complete all chapters and all six guardians using movement, jumping and menu inputs only.


func _run() -> void:
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	game = MAIN.instantiate()
	root.add_child(game)
	fox = game.fox
	game.sound.muted = true
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	for chapter in ForestChapters.TITLES.size():
		if not await _play_chapter(chapter):
			return
	_release()
	await _step(3)
	if (
		game.state != game.State.WON
		or game.chapter_results.size() != ForestChapters.TITLES.size() - 1
	):
		_fail("Campaign completion was not reached.")
		return
	print(
		(
			"PASS: full %d-level campaign and all six guardians, inputs only. Time "
			% ForestChapters.TITLES.size()
		),
		game.format_time(game.elapsed),
		"; retries ",
		game.deaths,
		"; earned gear ",
		game.equipment.unlocked.size()
	)
	quit(0)


func _play_chapter(chapter: int) -> bool:
	var path: Array = FOREST_ROUTE if chapter == 0 else ForestChapters.route(chapter)
	print("CHAPTER ", chapter + 1, ": ", game.level.title)
	if not await _follow_route(path):
		return false
	_release()
	if ForestChapters.has_boss(chapter) and not await _finish_boss_chapter():
		return false
	if game.level.taken_acorns.size() != 3 or not game.level.secret_found:
		_fail("Chapter %d missed an acorn or hidden firefly." % (chapter + 1))
		return false
	if chapter < ForestChapters.TITLES.size() - 1:
		return await _continue_chapter(chapter)
	return true


func _continue_chapter(chapter: int) -> bool:
	if game.state != game.State.CHAPTER_COMPLETE:
		_fail("The chapter gate did not show a result.")
		return false
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	if game.stage_index != chapter + 1:
		_fail("Continue did not advance to the next chapter.")
		return false
	return true


func _finish_boss_chapter() -> bool:
	if not await _fight_boss():
		return false
	if not await _walk_to(game.level.gate.x):
		_fail("The defeated boss did not leave a reachable gate.")
		return false
	_release()
	return true


func _fight_boss() -> bool:
	if not await _walk_to(game.boss.arena_min + 60):
		_fail("The boss camp could not be reached.")
		return false
	var previous_phase := ""
	var jump_frame := -1
	var escape_x: float = game.boss.arena_min + 300
	for frame in 2400:
		if game.boss.defeated:
			_release()
			return true
		if game.state != game.State.PLAYING:
			_fail("The input battle exhausted the fox's hearts.")
			return false
		if game.boss.phase != previous_phase:
			if game.boss.phase == "warning":
				escape_x = (
					game.boss.landing_x
					+ (210 if game.boss.landing_x < game.boss.arena_min + 400 else -210)
				)
			elif game.boss.phase == "rest":
				Input.action_release(&"jump")
				jump_frame = frame + 1
			previous_phase = game.boss.phase
		if game.boss.phase in ["warning", "leap", "landing", "hurt"]:
			_steer(escape_x)
			Input.action_release(&"jump")
		else:
			_steer(game.boss.position.x)
		if jump_frame >= 0:
			var since := frame - jump_frame
			if since == 0 or since == 20:
				Input.action_press(&"jump")
			elif since == 19 or since == 65:
				Input.action_release(&"jump")
		await _step(1)
	_fail("The boss input battle timed out.")
	return false
