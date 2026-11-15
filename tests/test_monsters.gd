extends "res://tests/test_game.gd"
## Regular enemy contacts, attacks and recovery use the real game scene.


func _run() -> void:
	Engine.time_scale = 3
	Engine.physics_ticks_per_second = 180
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	var title := game.hud.find_child("GameTitle", true, false) as Label
	_check(
		title != null and title.text == "Emberwood",
		"The opening title spells Emberwood as readable text."
	)
	_check(
		root.title == "Emberwood - Forest Adventure", "The window title uses a plain ASCII dash."
	)
	game.start_run()
	game.sound.muted = true
	for species in ForestCritters.KINDS:
		await _test_species(species)
	await _test_routes()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print(
			"PASS: %d monster contact, weapon, pause, retry, placement and title checks." % checks
		)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _target(species: StringName) -> Dictionary:
	game.start_run()
	for other in game.level.critters:
		other.out = true
	var target := {
		"home": Vector2(340, 536), "range": 0.0, "speed": 1.4, "kind": species, "out": false
	}
	game.level.critters.append(target)
	return target


func _test_species(species: StringName) -> void:
	var target := _target(species)
	await _step(3)
	var before: Vector2 = game.level.critter_position(target)
	game.pause_run()
	await _step(20)
	_check(
		game.level.critter_position(target) == before,
		"Pause freezes every enemy, including hovering and hopping."
	)
	game.resume_run()
	var bounds: Rect2 = game.level.critter_bounds(target)
	game.fox.reset_at(Vector2(bounds.get_center().x, bounds.position.y - 16))
	game.fox.velocity.y = 240
	game.invincible_left = 1.3
	await _step(15)
	_check(target.out, "A descending stomp defeats " + String(species))
	_check(game.fox.velocity.y < 0, "Stomping bounces the fox clear.")
	_check(game.deaths == 0, "A protected stomp does not count as a failure.")
	game._respawn("Test retry")
	await _step(55)
	_check(
		not target.out and ForestCritters.kind(target) == species,
		"Retry restores the same enemy species."
	)
	for weapon in [&"bow", &"spear", &"seed_bomb", &"thorn_fan", &"sunwood_lance"]:
		target = _target(species)
		await _step(2)
		bounds = game.level.critter_bounds(target)
		var shot := ForestArrow.new()
		var origin := Vector2(bounds.position.x - 45, bounds.get_center().y)
		if weapon == &"seed_bomb":
			origin = Vector2(bounds.get_center().x - 260, 516)
		shot.setup(origin, 1, game.level, null, game.fox, weapon)
		game.arrows.add_child(shot)
		await _step(90 if weapon == &"seed_bomb" else 25)
		_check(target.out, "Each weapon can defeat " + String(species) + ": " + String(weapon))
	# Side contact uses actual collision geometry, including the airborne bat.
	for armored in [false, true]:
		target = _target(species)
		await _step(2)
		if armored:
			game.equipment.rewards_at(0, 2)
			game._sync_equipment()
		bounds = game.level.critter_bounds(target)
		game.fox.reset_at(bounds.get_center() + Vector2(0, 12))
		game.invincible_left = 0
		await _step(1)
		_check(not target.out, "Side contact is not a stomp.")
		_check(
			game.state == (Adventure.State.PLAYING if armored else Adventure.State.RESPAWNING),
			"Armor blocks contact; unprotected contact triggers retry."
		)
		if armored:
			_check(game.equipment.armor_charge == 0, "Monster contact spends one armor block.")


func _test_routes() -> void:
	var found := {}
	for chapter in 20:
		game._load_chapter(chapter)
		game._set_state(Adventure.State.PLAYING)
		for target in game.level.critters:
			found[ForestCritters.kind(target)] = true
		if chapter < 5:
			continue
		var extras: Array = game.level.critters.filter(
			func(c: Dictionary) -> bool: return c.home.x == 1030
		)
		var extra: Dictionary = extras[0]
		_check(ForestCritters.kind(extra) != &"opossum", "Each later trail adds a new monster.")
		for time in [0.0, 1.0, 2.5, 4.0]:
			var bounds := ForestCritters.bounds(extra, time)
			for camp in game.level.camps:
				_check(
					absf(bounds.get_center().x - camp.x) > 100,
					"New patrols stay clear of respawn camps."
				)
			for spike in game.level.spikes:
				_check(not bounds.intersects(spike), "New monsters do not overlap spike patches.")
	_check(found.size() == 4, "The campaign contains all four ordinary enemy types.")
