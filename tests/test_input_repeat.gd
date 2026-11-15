extends SceneTree
## Native key repeat must not spend extra jumps, dashes or shots while held.

var game: Node2D
var jumps := 0
var shots := 0
var dashes := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.start_run()
	game.fox.jumped.connect(func(_double: bool) -> void: jumps += 1)
	game.fox.dashed.connect(func() -> void: dashes += 1)
	game.fox.shot_requested.connect(func() -> void: shots += 1)
	await _step(8)
	_key(KEY_SPACE, true)
	await _step(5)
	for repeat in 10:
		_key(KEY_SPACE, true, true)
		await _step(2)
	_check(jumps == 1, "Holding jump with native repeat spends only one jump.")
	_key(KEY_SPACE, false)
	await _step(2)
	_key(KEY_SPACE, true)
	await _step(2)
	_check(jumps == 2, "Release then press spends the second jump.")
	_key(KEY_SPACE, false)
	await _step(70)
	_key(KEY_SHIFT, true)
	await _step(50)
	_key(KEY_SHIFT, true, true)
	await _step(3)
	_check(dashes == 1, "Holding dash past cooldown cannot auto-repeat.")
	_key(KEY_SHIFT, false)
	await _step(3)
	_key(KEY_J, true)
	await _step(2)
	for repeat in 5:
		_key(KEY_J, true, true)
		await _step(2)
	_check(shots == 1, "Holding weapon cannot auto-repeat.")
	_key(KEY_J, false)
	await _step(2)
	_key(KEY_J, true)
	await _step(2)
	_check(shots == 2, "Weapon fires again after release and press.")
	_key(KEY_J, false)
	if failures.is_empty():
		print("PASS: native repeat consumes one jump, dash and shot per physical press.")
		quit()
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)


func _step(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
