extends SceneTree
## Runs the real CharacterBody2D against a floor using the game's input actions.

const FoxController := preload("res://scripts/fox.gd")

var fox: ForestFox
var failures: Array[String] = []
var dash_count := 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump", &"dash"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(800.0, 60.0)
	floor_shape.shape = rectangle
	floor_body.position = Vector2(400.0, 350.0)
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	fox = FoxController.new()
	root.add_child(fox)
	fox.dashed.connect(func() -> void: dash_count += 1)
	fox.active = true
	await _reset()
	_check(fox.is_on_floor(), "The fox settles on solid ground.")
	_check(absf(fox.position.y - 320.0) < 1.0, "The feet align with the floor.")
	Input.action_press(&"move_right")
	await _step(30)
	Input.action_release(&"move_right")
	await _step(10)
	_check(fox.position.x > 200.0, "Movement input moves the fox along the ground.")
	_check(is_zero_approx(fox.velocity.x), "Releasing movement stops the fox.")
	await _test_jump_limit()
	await _test_reset_and_pause()
	var held_height := await _jump_height(false)
	var short_height := await _jump_height(true)
	_check(held_height > 85.0, "Holding jump reaches a full-height jump.")
	_check(short_height < held_height * 0.65, "Releasing jump produces a smaller hop.")
	await _test_coyote_jump()
	await _test_buffered_jump()
	await _test_ground_dash()
	await _test_air_dash()
	await _test_dash_pause_and_reset()
	await _test_dash_wall()
	await _test_dash_jump()
	await _test_dash_tick_rates()
	await _test_bounce_budget()
	await _test_bounce_during_dash_and_pause()
	await _test_jump_release_after_bounce()
	_release_inputs()
	if failures.is_empty():
		print("PASS: fox physics, movement, double-jump limit, reset, pause, jump height, ")
		print(
			"      coyote/buffered jumps, dash distance, cooldown, air limit, pause, reset and walls."
		)
		print("      Grounded/airborne bounces, jump budget, dash interruption and pause.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_jump_limit() -> void:
	await _reset()
	Input.action_press(&"jump")
	await _step(2)
	_check(fox.jumps_left == 1 and fox.velocity.y < 0.0, "A ground jump spends one jump.")
	Input.action_release(&"jump")
	await _step(2)
	Input.action_press(&"jump")
	await _step(2)
	_check(fox.jumps_left == 0 and fox.velocity.y < -400.0, "A second press jumps in midair.")
	Input.action_release(&"jump")
	await _step(2)
	var before_third_press := fox.velocity.y
	Input.action_press(&"jump")
	await _step(2)
	_check(fox.velocity.y > before_third_press, "A third midair press does not grant another jump.")


func _test_reset_and_pause() -> void:
	Input.action_press(&"move_right")
	fox.reset_at(Vector2(120.0, 320.0))
	_check(fox.velocity == Vector2.ZERO, "Retry resets the fox's momentum.")
	_check(fox.jumps_left == 2, "Retry restores both jumps.")
	_check(fox.body_bounds().end.y == 320.0, "The collision bounds follow the retry position.")
	Input.action_release(&"move_right")
	await _step(5)
	_check(fox.is_on_floor(), "Holding jump through retry does not jump automatically.")
	_release_inputs()
	await _step(2)
	Input.action_press(&"jump")
	await _step(3)
	fox.active = false
	var paused_position := fox.position
	var paused_velocity := fox.velocity
	await _step(6)
	_check(fox.position == paused_position, "Inactive gameplay freezes the fox's position.")
	_check(fox.velocity == paused_velocity, "Inactive gameplay preserves momentum for resume.")
	fox.active = true


func _jump_height(release_early: bool) -> float:
	await _reset()
	Input.action_press(&"jump")
	await _step(2)
	if release_early:
		Input.action_release(&"jump")
	var highest_y := fox.position.y
	for frame: int in range(44):
		await _step(1)
		highest_y = minf(highest_y, fox.position.y)
	return 320.0 - highest_y


func _test_coyote_jump() -> void:
	await _reset(Vector2(785.0, 320.0))
	Input.action_press(&"move_right")
	for frame: int in range(30):
		await _step(1)
		if not fox.is_on_floor():
			break
	_check(not fox.is_on_floor(), "The fox can walk off a platform edge.")
	Input.action_press(&"jump")
	await _step(1)
	_check(fox.velocity.y < -500.0 and fox.jumps_left == 1, "Coyote time grants the ground jump.")
	await _reset(Vector2(785.0, 320.0))
	Input.action_press(&"move_right")
	for frame: int in range(30):
		await _step(1)
		if not fox.is_on_floor():
			break
	await _step(10)
	Input.action_press(&"jump")
	await _step(1)
	_check(fox.jumps_left == 0, "Walking off an edge leaves only one air jump after grace expires.")


func _test_buffered_jump() -> void:
	await _reset()
	fox.reset_at(Vector2(100.0, 280.0))
	fox.jumps_left = 0
	fox.velocity.y = 380.0
	Input.action_press(&"jump")
	await _step(8)
	_check(fox.velocity.y < 0.0, "A press just before landing becomes a jump after landing.")


func _test_ground_dash() -> void:
	await _reset()
	var start := fox.position.x
	var before := dash_count
	Input.action_press(&"dash")
	await _step(10)
	_check(fox.position.x - start > 94.0, "Dash covers substantially more ground than running.")
	_check(fox.position.x - start < 106.0, "Dash ends after its short fixed distance.")
	_check(not fox.can_dash(), "Dash cannot repeat during its cooldown.")
	await _step(45)
	_check(dash_count == before + 1, "Holding dash does not automatically repeat it.")
	_check(fox.can_dash(), "A grounded fox can dash again after its cooldown.")
	Input.action_release(&"dash")
	Input.action_press(&"move_left")
	await _step(2)
	Input.action_release(&"move_left")
	start = fox.position.x
	Input.action_press(&"dash")
	await _step(10)
	_check(fox.position.x < start - 94.0, "Dash follows the fox's left-facing direction.")


func _test_air_dash() -> void:
	await _reset(Vector2(300.0, -500.0))
	var jumps_before := fox.jumps_left
	Input.action_press(&"dash")
	await _step(4)
	_check(is_zero_approx(fox.velocity.y), "An air dash travels horizontally without dropping.")
	_check(fox.jumps_left <= jumps_before, "An air dash never replenishes jumps.")
	Input.action_release(&"dash")
	await _step(45)
	var before := dash_count
	_check(not fox.is_on_floor(), "The air-limit probe stays airborne through the cooldown.")
	_check(not fox.can_dash(), "Waiting out the cooldown in midair does not restore an air dash.")
	Input.action_press(&"dash")
	await _step(2)
	_check(dash_count == before, "A second air-dash press is ignored until landing.")
	Input.action_release(&"dash")
	await _step(55)
	_check(fox.is_on_floor() and fox.can_dash(), "Landing restores the air dash.")


func _test_dash_pause_and_reset() -> void:
	await _reset()
	Input.action_press(&"dash")
	await _step(3)
	fox.active = false
	var stopped_position := fox.position
	var stopped_dash := fox.dash_left
	var stopped_cooldown := fox.dash_cooldown_left
	await _step(8)
	_check(fox.position == stopped_position, "Pausing freezes movement during dash.")
	_check(fox.dash_left == stopped_dash, "Pausing freezes dash duration.")
	_check(fox.dash_cooldown_left == stopped_cooldown, "Pausing freezes dash cooldown.")
	fox.active = true
	await _step(2)
	_check(fox.position.x > stopped_position.x, "Resume continues the interrupted dash.")
	fox.reset_at(Vector2(100, 320))
	var before := dash_count
	await _step(8)
	_check(fox.dash_left == 0.0 and fox.dash_cooldown_left == 0.0, "Retry clears dash timers.")
	_check(fox.velocity == Vector2.ZERO, "Retry clears dash momentum.")
	_check(dash_count == before, "Holding dash through retry cannot launch a new dash.")
	Input.action_release(&"dash")
	await _step(2)
	Input.action_press(&"dash")
	await _step(1)
	_check(dash_count == before + 1, "Dash works again after release and a fresh press.")


func _test_dash_wall() -> void:
	await _reset()
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(10, 160)
	shape.shape = rectangle
	wall.position = Vector2(180, 240)
	wall.add_child(shape)
	root.add_child(wall)
	await _step(2)
	Input.action_press(&"dash")
	await _step(12)
	_check(fox.position.x <= 164.2, "A dash stops at a thin solid wall instead of tunneling.")
	_check(fox.dash_left == 0.0, "Solid wall contact ends the dash.")
	wall.queue_free()
	await _step(2)


func _test_dash_jump() -> void:
	await _reset()
	Input.action_press(&"dash")
	await _step(3)
	Input.action_press(&"jump")
	await _step(2)
	_check(fox.velocity.y < -400.0, "Jump interrupts a ground dash immediately.")
	_check(fox.dash_left == 0.0, "Jumping does not leave a second dash running.")
	await _reset(Vector2(300.0, -500.0))
	Input.action_press(&"dash")
	await _step(3)
	Input.action_press(&"jump")
	await _step(45)
	_check(not fox.is_on_floor() and not fox.can_dash(), "Canceling an air dash keeps it spent.")


func _test_dash_tick_rates() -> void:
	var initial_rate := Engine.physics_ticks_per_second
	for rate in [30, 120]:
		Engine.physics_ticks_per_second = rate
		await _reset()
		var start := fox.position.x
		Input.action_press(&"dash")
		await _step(ceili(ForestFox.DASH_DURATION * rate))
		var distance := fox.position.x - start
		_check(absf(distance - 99.2) < 1.0, "Dash keeps its travel distance at %d Hz." % rate)
	Engine.physics_ticks_per_second = initial_rate


func _test_bounce_budget() -> void:
	for grounded in [true, false]:
		await _reset()
		if not grounded:
			fox.reset_at(Vector2(300, 240))
			fox.velocity.y = 300.0
			await _step(2)
		var start_y := fox.position.y
		fox.bounce(-770.0)
		await _step(1)
		_check(fox.position.y < start_y - 10.0, "A bounce launches from ground or descending air.")
		_check(fox.jumps_left == 1, "Every bounce leaves exactly one air jump.")
		Input.action_press(&"jump")
		await _step(1)
		_check(
			fox.jumps_left == 0 and fox.velocity.y < -470.0,
			"A quick press after a bounce spends the single air jump."
		)
		Input.action_release(&"jump")
		await _step(1)
		var previous_velocity := fox.velocity.y
		Input.action_press(&"jump")
		await _step(1)
		_check(
			fox.jumps_left == 0 and fox.velocity.y > previous_velocity,
			"Stale ground contact cannot provide a second jump after a bounce."
		)


func _test_bounce_during_dash_and_pause() -> void:
	await _reset(Vector2(300, -500))
	Input.action_press(&"move_left")
	await _step(2)
	Input.action_press(&"dash")
	await _step(2)
	_check(fox.dash_left > 0.0, "The bounce probe starts during an active air dash.")
	var horizontal_speed := fox.velocity.x
	var cooldown := fox.dash_cooldown_left
	fox.bounce(-770.0)
	_check(
		fox.velocity.x == horizontal_speed and fox.facing == -1,
		"Bouncing preserves horizontal momentum and facing."
	)
	_check(fox.dash_left == 0.0, "A bounce interrupts the horizontal dash.")
	fox.active = false
	var position := fox.position
	await _step(5)
	_check(fox.position == position and fox.velocity.y == -770.0, "Pause freezes a pending bounce.")
	_check(fox.dash_cooldown_left == cooldown, "Pause preserves the interrupted dash cooldown.")
	fox.active = true
	await _step(2)
	_check(
		fox.position.y < position.y - 20.0, "Resume applies the upward bounce instead of a dash."
	)
	Input.action_release(&"dash")
	await _step(40)
	_check(not fox.can_dash(), "A bounce does not restore an already spent airborne dash.")


func _test_jump_release_after_bounce() -> void:
	await _reset()
	Input.action_press(&"jump")
	await _step(3)
	fox.bounce(-770.0)
	await _step(2)
	Input.action_release(&"jump")
	await _step(1)
	_check(
		fox.velocity.y < -650.0, "Releasing the previous jump cannot shorten an external bounce."
	)
	Input.action_press(&"jump")
	await _step(1)
	_check(fox.velocity.y < -470.0, "The remaining air jump can replace the bounce ascent.")
	Input.action_release(&"jump")
	await _step(1)
	_check(
		fox.velocity.y > -300.0 and fox.velocity.y < 0.0,
		"Releasing a new player-initiated air jump still produces a short jump."
	)


func _reset(location := Vector2(100.0, 320.0)) -> void:
	_release_inputs()
	fox.reset_at(location)
	await _step(5)


func _release_inputs() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump", &"dash"]:
		Input.action_release(action)


func _step(frames: int) -> void:
	for frame: int in range(frames):
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
