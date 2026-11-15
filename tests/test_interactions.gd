extends "res://tests/test_game.gd"
## Full-scene contacts exercise bounce ordering and protected enemy interactions.


func _run() -> void:
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	game.sound.muted = true
	await _test_mushroom_jump_budget()
	await _test_dashing_into_mushroom()
	await _test_mushroom_release()
	await _test_protected_critter_stomp()
	await _test_critter_side_contacts()
	_release_interaction_inputs()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d full-scene bounce and protected-contact checks." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_mushroom_jump_budget() -> void:
	for descending in [false, true]:
		_release_interaction_inputs()
		game.start_run()
		for critter in game.level.critters:
			critter.out = true
		var mushroom: Vector2 = game.level.mushrooms[0]
		if descending:
			game.fox.reset_at(mushroom - Vector2(0, 56))
			game.fox.velocity.y = 400.0
		else:
			game.fox.reset_at(mushroom - Vector2(45, 0))
			await _step(4)
			Input.action_press(&"move_right")
		var bounced := await _wait_for_mushroom_bounce()
		Input.action_release(&"move_right")
		_check(bounced, "Walking or descending onto the real mushroom launches the fox.")
		if not bounced:
			continue
		_check(game.fox.jumps_left == 1, "Both mushroom approaches leave one air jump.")
		await _step(1)
		Input.action_press(&"jump")
		await _step(1)
		_check(
			game.fox.jumps_left == 0 and game.fox.velocity.y < -470.0,
			"A quick jump after contact spends the single mushroom air jump."
		)
		Input.action_release(&"jump")
		await _step(1)
		var previous_velocity: float = game.fox.velocity.y
		Input.action_press(&"jump")
		await _step(1)
		_check(
			game.fox.jumps_left == 0 and game.fox.velocity.y > previous_velocity,
			"A second quick press cannot exploit stale mushroom floor contact."
		)


func _test_dashing_into_mushroom() -> void:
	_release_interaction_inputs()
	game.start_run()
	for critter in game.level.critters:
		critter.out = true
	var mushroom: Vector2 = game.level.mushrooms[0]
	game.fox.reset_at(mushroom - Vector2(65, 0))
	await _step(4)
	Input.action_press(&"dash")
	var bounced := await _wait_for_mushroom_bounce()
	Input.action_release(&"dash")
	_check(bounced, "Dashing onto the mushroom causes upward movement, not just feedback.")
	_check(game.mushroom_cooldown > 0.0, "The actual mushroom contact triggers its cooldown.")
	_check(game.fox.dash_left == 0.0, "The mushroom interrupts an active horizontal dash.")
	_check(game.fox.jumps_left == 1, "A mushroom dash contact also leaves one air jump.")


func _wait_for_mushroom_bounce() -> bool:
	var previous_y: float = game.fox.position.y
	for frame in 25:
		await _step(1)
		if game.fox.velocity.y < -600.0 and game.fox.position.y < previous_y:
			return true
		previous_y = game.fox.position.y
	return false


func _test_mushroom_release() -> void:
	_release_interaction_inputs()
	game.start_run()
	for critter in game.level.critters:
		critter.out = true
	var mushroom: Vector2 = game.level.mushrooms[0]
	game.fox.reset_at(mushroom - Vector2(0, 140))
	Input.action_press(&"jump")
	await _step(1)
	game.fox.velocity.y = 400.0
	_check(await _wait_for_mushroom_bounce(), "The release probe lands on the real mushroom.")
	Input.action_release(&"jump")
	await _step(1)
	_check(
		game.fox.velocity.y < -650.0, "Releasing held jump preserves the mushroom's full launch."
	)
	Input.action_press(&"jump")
	await _step(1)
	Input.action_release(&"jump")
	await _step(1)
	_check(
		game.fox.velocity.y > -300.0 and game.fox.velocity.y < 0.0,
		"A new air jump after a mushroom still responds to early release."
	)


func _test_protected_critter_stomp() -> void:
	var target := await _prepare_critter(true, 1.3, Vector2(300, 450))
	game.fox.velocity.y = 300.0
	var bounced := false
	for frame in 25:
		await _step(1)
		if target.out and game.fox.velocity.y < -300.0:
			bounced = true
			break
	_check(target.out, "Protection from a previous hit does not disable critter stomps.")
	_check(bounced, "A protected stomp still gives its upward bounce.")
	_check(game.equipment.armor_charge == 1, "A valid protected stomp consumes no armor.")
	_check(game.deaths == 0, "A protected stomp causes no retry.")
	_check(game.invincible_left > 0.0, "The stomp probe occurs during protection.")


func _test_critter_side_contacts() -> void:
	for scenario in [[true, 1.3], [true, 0.0], [false, 0.0]]:
		var armored: bool = scenario[0]
		var protection: float = scenario[1]
		var target := await _prepare_critter(armored, protection, Vector2(250, 536))
		Input.action_press(&"move_right")
		await _step(18)
		Input.action_release(&"move_right")
		_check(not target.out, "Side contact cannot defeat a critter as a stomp.")
		if protection > 0.0:
			_check(
				game.level.critter_bounds(target).intersects(game.fox.body_bounds()),
				"The protected side-contact probe actually overlaps the critter."
			)
			_check(
				game.state == Adventure.State.PLAYING and game.deaths == 0,
				"Protected side contact remains harmless."
			)
			_check(game.equipment.armor_charge == 1, "Protected side contact does not spend armor.")
		elif armored:
			_check(
				game.state == Adventure.State.PLAYING and game.deaths == 0,
				"Charged armor blocks unprotected side contact."
			)
			_check(
				game.equipment.armor_charge == 0, "That damaging side contact spends armor once."
			)
			_check(game.invincible_left > 0.0, "The armor block grants recovery time.")
		else:
			_check(
				game.state == Adventure.State.RESPAWNING and game.deaths == 1,
				"Unprotected side contact without armor causes a retry."
			)


func _prepare_critter(armored: bool, protection: float, start: Vector2) -> Dictionary:
	_release_interaction_inputs()
	game.start_run()
	for critter in game.level.critters:
		critter.out = true
	var target: Dictionary = game.level.critters[0]
	target.home = Vector2(300, 536)
	target.range = 0.0
	target.out = false
	if armored:
		game.equipment.rewards_at(0, 2)
		game._sync_equipment()
	game.fox.reset_at(start)
	game.invincible_left = protection
	await _step(2)
	return target


func _release_interaction_inputs() -> void:
	for action in [&"move_left", &"move_right", &"jump", &"dash", &"shoot"]:
		Input.action_release(action)
