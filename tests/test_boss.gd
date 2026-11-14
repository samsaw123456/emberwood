extends SceneTree
## Tests the encounter with real fox physics and input-driven jumps.

const BossController := preload("res://scripts/boss.gd")
const FoxController := preload("res://scripts/fox.gd")
const PlatformController := preload("res://scripts/platform.gd")

var fixture: Node2D
var boss: BossController
var fox: FoxController
var failures: Array[String] = []
var hit_count := 0
var damage_events: Array[int] = []
var victory_count := 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	await _test_waiting_and_telegraph()
	await _test_damage_and_reset()
	await _test_arrows()
	await _test_input_battle()
	_release()
	if is_instance_valid(fixture):
		fixture.queue_free()
	if failures.is_empty():
		print(
			"PASS: boss tells, leaps, waves, pause, stomps, arrows, defeat, retry and input battle."
		)
		quit(0)
	else:
		for message in failures:
			push_error(message)
		quit(1)


func _make_fixture() -> void:
	_release()
	if is_instance_valid(fixture):
		root.remove_child(fixture)
		fixture.queue_free()
	fixture = Node2D.new()
	root.add_child(fixture)
	var floor_body := PlatformController.new()
	floor_body.setup(Rect2(2500, 536, 1100, 180))
	fixture.add_child(floor_body)
	fox = FoxController.new()
	fixture.add_child(fox)
	fox.reset_at(Vector2(2700, 536))
	fox.active = true
	boss = BossController.new()
	boss.position = Vector2(2970, 536)
	boss.fox = fox
	fixture.add_child(boss)
	boss.active = true
	hit_count = 0
	damage_events.clear()
	victory_count = 0
	boss.player_hit.connect(func() -> void: hit_count += 1)
	boss.damaged.connect(func(remaining: int) -> void: damage_events.append(remaining))
	boss.defeated_boss.connect(func() -> void: victory_count += 1)


func _test_waiting_and_telegraph() -> void:
	_make_fixture()
	await _step(30)
	_check(not boss.engaged and boss.phase == "waiting", "The boss waits for entry.")
	_check(hit_count == 0, "An unstarted encounter cannot hurt the fox.")
	boss.begin()
	boss.begin()
	var marker := boss.landing_x
	fox.reset_at(Vector2(3200, 536))
	await _step(30)
	_check(boss.phase == "warning", "The first landing is warned well before launch.")
	_check(boss.landing_x == marker, "The landing marker stays fixed when the fox escapes.")
	var seen_leap := false
	var lowest_y := boss.position.y
	for frame in 120:
		await _step(1)
		lowest_y = minf(lowest_y, boss.position.y)
		seen_leap = seen_leap or boss.phase == "leap"
		if boss.phase == "landing":
			break
	_check(seen_leap and lowest_y < 435, "The boss visibly leaves the floor during a leap.")
	_check(lowest_y >= 424, "The leap stays within its readable height limit.")
	_check(absf(boss.position.x - marker) < 1, "The boss lands on the warned spot.")
	_check(boss.waves.size() == 2, "Landing sends one jumpable ripple each way.")
	var pause_position := boss.position
	var pause_time := boss.phase_time
	var pause_waves := boss.waves.duplicate(true)
	boss.active = false
	fox.active = false
	await _step(60)
	_check(boss.position == pause_position, "Pausing freezes boss motion.")
	_check(boss.phase_time == pause_time, "Pausing freezes the attack countdown.")
	_check(boss.waves == pause_waves, "Pausing freezes every ripple.")
	boss.active = true
	fox.active = true
	await _step(3)
	_check(boss.waves != pause_waves, "Ripples resume from their paused locations.")
	var wave_x: float = boss.waves[1].x
	fox.reset_at(Vector2(wave_x + 5, 536))
	await _step(5)
	_check(hit_count > 0, "A grounded fox is hit by a low ripple.")


func _test_damage_and_reset() -> void:
	_make_fixture()
	boss.begin()
	fox.reset_at(boss.position - Vector2(0, 115))
	await _step(20)
	_check(hit_count > 0, "Landing on a closed cap hurts the fox.")
	_check(boss.health == 3, "The closed cap cannot be damaged.")
	fox.reset_at(Vector2(3300, 536))
	for hit in 3:
		_check(await _wait_for_phase("rest"), "Every attack leaves a vulnerable opening.")
		fox.reset_at(boss.position - Vector2(0, 135))
		var previous_health := boss.health
		for frame in 55:
			await _step(1)
			if boss.health < previous_health:
				break
		_check(boss.health == previous_health - 1, "A falling head stomp removes one boss hit.")
		_check(fox.velocity.y < -400, "The stomp gives a clear upward bounce.")
		_check(boss.waves.is_empty(), "A successful stomp clears lingering ripples.")
		await _step(5)
		_check(boss.health == previous_health - 1, "One landing cannot count as several hits.")
		fox.reset_at(Vector2(3300, 536))
	_check(damage_events == [2, 1, 0], "Damage reports the remaining three-step encounter health.")
	_check(boss.defeated and not boss.engaged, "The third stomp ends the encounter.")
	_check(victory_count == 1, "The encounter announces victory once.")
	var final_hits := hit_count
	fox.reset_at(boss.position)
	await _step(90)
	_check(hit_count == final_hits, "The defeated boss is harmless.")
	boss.begin()
	_check(boss.defeated, "Beginning twice cannot resurrect a defeated boss.")
	boss.reset_battle()
	_check(boss.health == 3 and not boss.defeated, "Retry restores all boss health.")
	_check(boss.phase == "waiting" and not boss.engaged, "Retry returns to entry state.")
	_check(boss.position == Vector2(2970, 536), "Retry restores the original safe layout.")
	_check(boss.waves.is_empty(), "Retry removes every previous attack.")


func _test_arrows() -> void:
	_make_fixture()
	_check(not boss.arrow_hit(), "Arrows cannot start or damage a waiting boss.")
	boss.begin()
	_check(not boss.arrow_hit() and boss.health == 3, "A closed cap blocks arrows.")
	_check(await _wait_for_phase("rest"), "The bow gets the same opening as a stomp.")
	boss.active = false
	_check(not boss.arrow_hit(), "Arrows cannot damage a paused boss.")
	boss.active = true
	var fox_velocity := fox.velocity
	_check(boss.arrow_hit() and boss.health == 2, "A resting boss takes one arrow hit.")
	_check(fox.velocity == fox_velocity, "An arrow hit does not bounce the distant fox.")
	_check(not boss.arrow_hit() and boss.health == 2, "One opening accepts only one arrow.")
	_check(boss.waves.is_empty(), "A valid arrow hit clears the attack's ripples.")
	for hit in 2:
		_check(await _wait_for_phase("rest"), "Later attacks also expose the boss to arrows.")
		_check(boss.arrow_hit(), "Each later opening accepts an arrow.")
	_check(boss.defeated and victory_count == 1, "Three arrows can finish the encounter.")
	_check(not boss.arrow_hit() and boss.health == 0, "A defeated boss rejects extra damage.")


func _test_input_battle() -> void:
	_make_fixture()
	boss.begin()
	var previous_phase := ""
	var jump_frame := -1
	var escape_x := 2900.0
	for frame in 1800:
		if boss.defeated:
			break
		if boss.phase != previous_phase:
			if boss.phase == "warning":
				escape_x = boss.landing_x + (210 if boss.landing_x < 3000 else -210)
			elif boss.phase == "rest":
				Input.action_release(&"jump")
				jump_frame = frame + 1
			previous_phase = boss.phase
		if boss.phase in ["warning", "leap", "landing", "hurt"]:
			_steer(escape_x)
			Input.action_release(&"jump")
		else:
			_steer(boss.position.x)
		if jump_frame >= 0:
			var since := frame - jump_frame
			if since == 0 or since == 20:
				Input.action_press(&"jump")
			elif since == 19 or since == 65:
				Input.action_release(&"jump")
		await _step(1)
	_release()
	_check(boss.defeated, "The boss can be defeated entirely through movement and jump inputs.")
	_check(hit_count < 3, "The input route can finish within the fox's three-heart allowance.")
	print("Input boss battle: hits=", hit_count, " remaining boss health=", boss.health)


func _steer(target_x: float) -> void:
	var offset := target_x - fox.position.x
	var stopping_distance := maxf(4, absf(fox.velocity.x) * 0.06)
	var direction := signf(offset) if absf(offset) > stopping_distance else 0.0
	_set_input(&"move_left", direction < 0)
	_set_input(&"move_right", direction > 0)


func _set_input(action: StringName, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not pressed and Input.is_action_pressed(action):
		Input.action_release(action)


func _release() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)


func _wait_for_phase(expected: String) -> bool:
	for frame in 400:
		await _step(1)
		if boss.phase == expected:
			return true
	return false


func _step(frames: int) -> void:
	for frame in frames:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
