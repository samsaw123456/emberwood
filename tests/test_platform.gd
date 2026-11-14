extends SceneTree
## Exercises terrain with the real fox and Godot's collision/carry behavior.

const PlatformController := preload("res://scripts/platform.gd")
const FoxController := preload("res://scripts/fox.gd")

var failures: Array[String] = []
var fixture: Node2D
var platform: PlatformController
var fox: FoxController


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	await _test_solid_floor()
	await _test_moving_platform()
	await _test_crumbling_platform()
	_clear_fixture()
	if failures.is_empty():
		print(
			"PASS: solid collisions, moving-platform carry, pause/resume, crumble, recovery and reset."
		)
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_solid_floor() -> void:
	_create_fixture("ground")
	fox.reset_at(Vector2(190, 250))
	await _step(30)
	_check(fox.is_on_floor(), "The fox lands on a platform's solid surface.")
	_check(
		absf(fox.position.y - 320.0) < 1.0, "The rendered platform top matches the collision top."
	)
	Input.action_press(&"move_right")
	await _step(45)
	Input.action_release(&"move_right")
	await _step(20)
	_check(not fox.is_on_floor(), "Walking past the visible edge leaves the platform.")
	_check(fox.position.y > 360.0, "There is no invisible floor beyond the platform edge.")


func _test_moving_platform() -> void:
	_create_fixture("moving", Vector2(100, 35))
	await _step(6)
	_check(fox.is_on_floor(), "The fox can board a stopped moving platform.")
	var starting_fox_position := fox.position
	var relative_x := fox.position.x - platform.position.x
	platform.active = true
	await _step(45)
	_check(fox.is_on_floor(), "The fox stays grounded while riding a moving platform.")
	_check(
		fox.position.x > starting_fox_position.x + 45, "The platform carries an idle fox sideways."
	)
	_check(
		fox.position.y > starting_fox_position.y + 15, "The platform carries the fox vertically."
	)
	_check(
		absf(fox.position.x - platform.position.x - relative_x) < 4.0,
		"The fox keeps its place on the moving platform without sliding off."
	)
	_check(
		absf(fox.position.y - platform.position.y) < 2.0, "The fox's feet follow the moving top."
	)
	platform.active = false
	fox.active = false
	var paused_age := platform.age
	var paused_fox := fox.position
	var requested_pause_position := platform.position
	# AnimatableBody2D may still commit the transform queued in the preceding physics tick.
	await _step(2)
	_check(
		platform.position.distance_to(requested_pause_position) < 4.0,
		"Pausing allows at most the already queued physics step."
	)
	var paused_platform := platform.position
	await _step(30)
	_check(platform.age == paused_age, "Paused platforms do not advance their motion timer.")
	_check(platform.position == paused_platform, "Pausing freezes the moving platform.")
	_check(fox.position == paused_fox, "Pausing freezes its passenger.")
	platform.active = true
	fox.active = true
	await _step(2)
	_check(
		platform.position.distance_to(paused_platform) < 8.0,
		"Resume does not skip ahead in motion."
	)
	await _step(65)
	_check(fox.is_on_floor(), "The passenger stays on board through the platform's turnaround.")
	_check(
		absf(fox.position.x - platform.position.x - relative_x) < 4.0,
		"Changing direction does not dislodge the passenger."
	)


func _test_crumbling_platform() -> void:
	_create_fixture("crumble")
	platform.active = true
	await _step(6)
	_check(fox.is_on_floor(), "An untouched crumble bridge supports the fox.")
	platform.step_on()
	await _step(12)
	_check(fox.is_on_floor(), "The warning gives the player time to jump off.")
	platform.active = false
	fox.active = false
	var paused_crumble := platform.crumble_time
	await _step(30)
	_check(platform.crumble_time == paused_crumble, "Pausing also freezes a pending collapse.")
	platform.active = true
	fox.active = true
	for frame: int in range(30):
		platform.step_on()
		await _step(1)
	_check(platform.collision_layer == 0, "Repeated foot contact does not postpone the collapse.")
	_check(not fox.is_on_floor(), "A collapsed bridge releases its passenger.")
	_check(fox.position.y > platform.position.y + 10, "The fox falls through the faded bridge.")
	platform.step_on()
	await _step(180)
	_check(platform.collision_layer == 1, "A collapsed bridge eventually becomes solid again.")
	fox.reset_at(Vector2(190, 300))
	await _step(16)
	_check(fox.is_on_floor(), "The recovered bridge supports a new landing.")
	platform.step_on()
	await _step(42)
	_check(not fox.is_on_floor(), "The recovered bridge can collapse a second time.")
	platform.reset_bridge()
	fox.reset_at(Vector2(190, 320))
	await _step(6)
	_check(fox.is_on_floor(), "Retry immediately restores a collapsed bridge's collision.")
	await _step(45)
	_check(fox.is_on_floor(), "Reset clears the previous collapse timer.")


func _create_fixture(kind: String, motion := Vector2.ZERO) -> void:
	_clear_fixture()
	fixture = Node2D.new()
	root.add_child(fixture)
	platform = PlatformController.new()
	platform.setup(Rect2(100, 320, 240, 28), kind, motion)
	fixture.add_child(platform)
	fox = FoxController.new()
	fixture.add_child(fox)
	fox.active = true
	fox.reset_at(Vector2(190, 320))


func _clear_fixture() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)
	if is_instance_valid(fixture):
		root.remove_child(fixture)
		fixture.queue_free()


func _step(frames: int) -> void:
	for frame: int in range(frames):
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
