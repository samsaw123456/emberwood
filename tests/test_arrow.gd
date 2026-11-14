extends SceneTree
## Real physics raycasts verify flight, first-hit ordering and projectile cleanup.

const ArrowController := preload("res://scripts/arrow.gd")

var world: ForestLevel
var failures: Array[String] = []
var impacts: Array[Dictionary] = []


class EmptyLevel:
	extends ForestLevel

	func _ready() -> void:
		pass

	func _draw() -> void:
		pass


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	await _test_pause_and_range()
	await _test_critters_and_direction()
	await _test_terrain_priority()
	await _test_moving_and_collapsed_terrain()
	await _test_boss_collision()
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print(
			"PASS: arrow flight, pause, range, left/right hits, terrain, moving bridges and boss."
		)
		quit(0)
	else:
		for message in failures:
			push_error(message)
		quit(1)


func _new_world() -> void:
	if is_instance_valid(world):
		root.remove_child(world)
		world.queue_free()
	world = EmptyLevel.new()
	root.add_child(world)
	impacts.clear()


func _shoot(
	origin: Vector2, direction: int = 1, boss: ForestBoss = null, shooter: PhysicsBody2D = null
) -> ArrowController:
	var arrow := ArrowController.new()
	arrow.setup(origin, direction, world, boss, shooter)
	arrow.struck.connect(
		func(at: Vector2, target: String) -> void:
			impacts.append({"position": at, "target": target})
	)
	world.add_child(arrow)
	return arrow


func _critter(x: float) -> Dictionary:
	return {"home": Vector2(x, 130), "range": 0.0, "speed": 1.0, "out": false}


func _platform(
	rect: Rect2, kind: String = "wall", travel: Vector2 = Vector2.ZERO
) -> ForestPlatform:
	var platform := ForestPlatform.new()
	platform.setup(rect, kind, travel)
	world.add_child(platform)
	world.platforms.append(platform)
	return platform


func _test_pause_and_range() -> void:
	_new_world()
	var arrow := _shoot(Vector2(0, 70))
	await _step(6)
	_check(
		arrow.position.x > 40 and arrow.position.x < 85, "An arrow advances at a readable speed."
	)
	arrow.active = false
	var stopped := arrow.position
	var traveled := arrow.traveled
	await _step(80)
	_check(arrow.position == stopped, "Pause freezes an arrow in flight.")
	_check(arrow.traveled == traveled, "Paused time does not consume arrow range.")
	arrow.active = true
	await _step(65)
	_check(not is_instance_valid(arrow), "A missed arrow frees itself at its finite range.")
	_check(impacts.is_empty(), "A clean miss does not report an impact.")


func _test_critters_and_direction() -> void:
	_new_world()
	world.critters.assign([_critter(160), _critter(90)])
	var fox := ForestFox.new()
	world.add_child(fox)
	fox.reset_at(Vector2(40, 130))
	await _step(3)
	_shoot(Vector2(0, 110), 1, null, fox)
	await _step(20)
	_check(bool(world.critters[1].out), "A right-facing shot knocks the nearest critter aside.")
	_check(not world.critters[0].out, "One arrow cannot pass through to a second critter.")
	_check(impacts.size() == 1 and impacts[0].target == "critter", "The shooter is excluded.")
	_check(
		impacts.size() > 0 and absf(impacts[0].position.x - 65) < 0.1,
		"The arrow stops at the critter's near edge."
	)
	_shoot(Vector2(240, 110), -1, null, fox)
	await _step(15)
	_check(bool(world.critters[0].out), "A left-facing shot hits the remaining critter.")
	_check(
		impacts.size() > 1 and absf(impacts[1].position.x - 185) < 0.1,
		"Left shots stop at the opposite edge."
	)
	world.critters[0].out = false
	_shoot(Vector2(0, 70))
	await _step(25)
	_check(not world.critters[0].out, "A high arrow misses a critter beneath it.")


func _test_terrain_priority() -> void:
	_new_world()
	world.critters.assign([_critter(90)])
	_platform(Rect2(58, 80, 1, 60))
	var fox := ForestFox.new()
	world.add_child(fox)
	fox.reset_at(Vector2(45, 130))
	await _step(3)
	_shoot(fox.position + Vector2(0, -20), 1, null, fox)
	await _step(5)
	_check(
		impacts.size() == 1 and impacts[0].target == "blocked", "A one-pixel wall blocks arrows."
	)
	_check(not world.critters[0].out, "Terrain protects a critter immediately behind it.")
	_check(
		impacts.size() > 0 and absf(impacts[0].position.x - 58) < 0.1,
		"A fast arrow cannot tunnel through thin terrain."
	)
	_new_world()
	world.critters.assign([_critter(60)])
	_platform(Rect2(80, 80, 20, 60))
	await _step(3)
	_shoot(Vector2(0, 110))
	await _step(15)
	_check(
		impacts.size() == 1 and impacts[0].target == "critter",
		"Targets before a wall remain hittable."
	)
	_shoot(Vector2(85, 110))
	await _step(3)
	_check(
		impacts.size() == 2 and impacts[1].target == "blocked", "A shot inside a wall is blocked."
	)


func _test_moving_and_collapsed_terrain() -> void:
	_new_world()
	var platform := _platform(Rect2(110, 95, 12, 28), "moving", Vector2(70, 0))
	platform.phase = PI / 2
	platform.active = true
	await _step(5)
	_shoot(Vector2(100, 108))
	await _step(15)
	_check(impacts.size() == 1 and impacts[0].target == "blocked", "A moving beam blocks arrows.")
	_check(
		impacts.size() > 0 and impacts[0].position.x > 165,
		"The beam's current position is used, not its original position."
	)
	_new_world()
	world.critters.assign([_critter(160)])
	platform = _platform(Rect2(80, 90, 5, 40), "crumble")
	platform.active = true
	platform.step_on()
	await _step(40)
	_shoot(Vector2(0, 110))
	await _step(25)
	_check(bool(world.critters[0].out), "Arrows pass through a bridge after it crumbles away.")


func _test_boss_collision() -> void:
	_new_world()
	var boss := ForestBoss.new()
	boss.position = Vector2(200, 130)
	world.add_child(boss)
	boss.active = true
	boss.engaged = true
	boss.phase = "rest"
	_shoot(Vector2(0, 110), 1, boss)
	await _step(20)
	_check(boss.health == 2, "An actual arrow damages the resting boss.")
	_check(
		impacts.size() == 1 and impacts[0].target == "boss", "A valid boss hit reports its impact."
	)
	_shoot(Vector2(0, 110), 1, boss)
	await _step(20)
	_check(boss.health == 2, "The same opening cannot take another arrow hit.")
	_check(
		impacts.size() == 2 and impacts[1].target == "blocked", "The recovering boss blocks arrows."
	)


func _step(frames: int) -> void:
	for frame in frames:
		await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
