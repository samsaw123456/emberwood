extends "res://tests/test_campaign.gd"
## Every new trail is played from its entrance using movement and jump input.


func _run() -> void:
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	game = MAIN.instantiate()
	root.add_child(game)
	fox = game.fox
	game.sound.muted = true
	game.start_run()
	var signatures: Dictionary = {}
	var first := int(OS.get_environment("EMBERWOOD_FIRST_TRAIL"))
	first = maxi(first, 5)
	var last := int(OS.get_environment("EMBERWOOD_LAST_TRAIL"))
	last = 19 if last < first else mini(last, 19)
	for chapter in range(first, last + 1):
		var layout := ForestChapters.layout(chapter)
		var signature := str([layout.ledges, layout.moving, layout.crumble, layout.spikes])
		if signatures.has(signature):
			_fail("Two new chapters share an identical obstacle layout.")
			return
		signatures[signature] = true
		if not await _play_trail(chapter):
			return
	print(
		(
			"PASS: %d distinct new trails, every acorn, firefly and checkpoint, zero retries."
			% signatures.size()
		)
	)
	quit(0)


func _play_trail(chapter: int) -> bool:
	_release()
	game._load_chapter(chapter)
	game._set_state(game.State.PLAYING)
	await _step(3)
	print("TRAIL ", chapter + 1, ": ", game.level.title)
	if not await _follow_route(ForestChapters.route(chapter)):
		return false
	_release()
	if ForestChapters.has_boss(chapter) and not await _finish_boss_chapter():
		return false
	await _step(3)
	var expected: int = game.State.WON if chapter == 19 else game.State.CHAPTER_COMPLETE
	if game.state != expected or game.level.taken_acorns.size() != 3:
		_fail("The trail did not reach its gate with all three acorns.")
		return false
	if not game.level.secret_found or game.level.camp_index != game.level.camps.size() - 1:
		_fail("The trail missed its hidden firefly or a safe checkpoint.")
		return false
	if game.deaths != 0:
		_fail("The trail route caused an unexpected retry.")
		return false
	print(
		"PASS TRAIL ",
		chapter + 1,
		"; gems ",
		game.level.taken_gems.size(),
		"/",
		game.level.gems.size()
	)
	return true
