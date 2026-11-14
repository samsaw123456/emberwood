extends SceneTree
## Runs the real CharacterBody2D against a floor using the game's input actions.

const FoxController := preload("res://scripts/fox.gd")

var fox: ForestFox
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
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
	_release_inputs()
	if failures.is_empty():
		print("PASS: fox physics, movement, double-jump limit, reset, pause, jump height, ")
		print("      coyote jump and buffered landing jump.")
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


func _reset(location := Vector2(100.0, 320.0)) -> void:
	_release_inputs()
	fox.reset_at(location)
	await _step(5)


func _release_inputs() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)


func _step(frames: int) -> void:
	for frame: int in range(frames):
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
