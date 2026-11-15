extends SceneTree
## A complete route using only keyboard/menu and movement actions.
## Run with an isolated XDG_DATA_HOME: a legitimate win saves a best time.

const MAIN := preload("res://scenes/main.tscn")

const FOREST_ROUTE := [
	["walk", 450.0, 536.0],
	["jump", 680.0, 536.0],
	["jump", 780.0, 436.0],
	["jump", 990.0, 356.0],
	["jump", 1250.0, 536.0],
	["jump", 1540.0, 436.0],
	["jump", 1610.0, 386.0],
	["jump", 1840.0, 536.0],
	["walk", 1940.0, 536.0],
	["moving", 2110.0, 475.0],
	["jump", 2370.0, 536.0],
	["jump", 2540.0, 440.0],
	["jump", 2750.0, 350.0],
	["jump", 2870.0, 322.0],
	["jump", 3035.0, 536.0],
	["jump", 3175.0, 480.0],
	["jump", 3305.0, 450.0],
	["jump", 3460.0, 536.0],
	["jump", 3575.0, 440.0],
	["jump", 3660.0, 376.0],
	["jump", 3880.0, 536.0],
	["walk", 3920.0, 536.0],
	["jump", 4090.0, 536.0],
	["jump", 4250.0, 470.0],
	["jump", 4410.0, 410.0],
	["jump", 4600.0, 536.0],
	["mushroom", 4770.0, 536.0],
	["bounce", 4890.0, 350.0],
	["jump", 5010.0, 536.0],
	["walk", 4960.0, 536.0],
	["jump", 5180.0, 536.0],
	["moving", 5300.0, 450.0],
	["jump", 5580.0, 440.0],
	["jump", 5650.0, 356.0],
	["jump", 5900.0, 536.0],
	["jump", 6150.0, 536.0],
	["walk", 6280.0, 536.0],
]

var game: Node2D
var fox: ForestFox
var bridge_steps := 0
var mushroom_bounces := 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	game = MAIN.instantiate()
	root.add_child(game)
	fox = game.fox
	game.sound.muted = true
	# Native menu layout and keyboard focus settle on rendering frames.
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	if game.state != game.State.PLAYING:
		_fail("Enter did not start the adventure from the title menu.")
		return

	if not await _follow_route(FOREST_ROUTE):
		return

	_release()
	await _step(3)
	if game.state != game.State.CHAPTER_COMPLETE or game.level.taken_acorns.size() != 3:
		_fail("The input route did not complete the first chapter.")
		return
	if not game.level.secret_found or bridge_steps < 2 or mushroom_bounces == 0:
		_fail("The route missed the firefly, crumble bridge, or mushroom.")
		return
	print(
		(
			(
				"PASS: title to gate using inputs only; 3 acorns, %d gems, hidden firefly, "
				% game.level.taken_gems.size()
			)
			+ (
				"moving platforms, crumble bridge and mushroom. %d retries. Time %s."
				% [game.deaths, game.format_time(game.elapsed)]
			)
		)
	)
	quit(0)


func _follow_route(route: Array) -> bool:
	for index: int in route.size():
		var command: Array = route[index]
		var target := Vector2(command[1], command[2])
		print("Route %02d: %s %s from %s" % [index, command[0], target, fox.position])
		var arrived := false
		if command[0] == "walk":
			arrived = await _walk_to(target.x)
		elif command[0] == "moving":
			var platform: ForestPlatform
			for candidate: ForestPlatform in game.level.platforms:
				if candidate.kind == "moving" and candidate.origin.x == target.x:
					platform = candidate
			arrived = await _jump_to(target, platform)
		else:
			arrived = await _jump_to(target, null, command[0])
		if not arrived:
			_fail("Route %d failed at %s (velocity %s)." % [index, fox.position, fox.velocity])
			return false
	return true


func _walk_to(target_x: float) -> bool:
	Input.action_release(&"jump")
	for frame: int in range(240):
		_steer(target_x)
		await _step(1)
		if game.state in [game.State.WON, game.State.CHAPTER_COMPLETE]:
			return true
		if game.state != game.State.PLAYING:
			return false
		if absf(fox.position.x - target_x) < 7.0 and absf(fox.velocity.x) < 30.0:
			return true
	return false


func _jump_to(target: Vector2, platform: ForestPlatform = null, mode := "jump") -> bool:
	if mode != "bounce":
		Input.action_release(&"jump")
		await _step(2)
		Input.action_press(&"jump")
	for frame: int in range(210):
		if is_instance_valid(platform):
			target = platform.position + Vector2(platform.size.x / 2.0, 0)
		_steer(target.x)
		if frame == 19:
			Input.action_release(&"jump")
		elif frame == 20:
			Input.action_press(&"jump")
		elif frame == 60:
			Input.action_release(&"jump")
		await _step(1)
		if game.state in [game.State.WON, game.State.CHAPTER_COMPLETE]:
			return true
		if game.state != game.State.PLAYING:
			return false
		if mode == "mushroom" and game.mushroom_cooldown > 0.0:
			mushroom_bounces += 1
			return true
		if fox.is_on_floor() and absf(fox.position.x - target.x) < 18.0:
			if absf(fox.position.y - target.y) < 8.0:
				for collision_index: int in fox.get_slide_collision_count():
					var collider := fox.get_slide_collision(collision_index).get_collider()
					if collider is ForestPlatform and collider.kind == "crumble":
						bridge_steps += 1
				return true
	return false


func _steer(target_x: float) -> void:
	var distance := target_x - fox.position.x
	var stopping_distance := maxf(4.0, absf(fox.velocity.x) * 0.06)
	var direction := signf(distance) if absf(distance) > stopping_distance else 0.0
	_set_action(&"move_left", direction < 0.0)
	_set_action(&"move_right", direction > 0.0)


func _set_action(action: StringName, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not pressed and Input.is_action_pressed(action):
		Input.action_release(action)


func _release() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _step(frames: int) -> void:
	for frame: int in range(frames):
		# The next physics_frame arrives after the preceding physics tick finished.
		# Waiting for process_frame here skips simulation ticks on slower renderers.
		await physics_frame


func _fail(message: String) -> void:
	_release()
	push_error(message)
	quit(1)
