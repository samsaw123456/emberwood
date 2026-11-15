extends "res://tests/test_arrow.gd"
## Actual projectiles exercise piercing, arcing, blast visibility and cleanup.

var checks := 0


func _run() -> void:
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	await _test_spear_piercing()
	await _test_spear_terrain()
	await _test_bomb_arc_and_fuse()
	await _test_bomb_terrain_and_blast()
	await _test_bomb_direct_contact()
	await _test_bomb_boss()
	await _test_bomb_pause_and_cleanup()
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("PASS: %d spear and seed-bomb collision, blast, pause and cleanup checks." % checks)
		quit(0)
	else:
		for message in failures:
			push_error(message)
		quit(1)


func _launch(
	kind: StringName, origin: Vector2, direction: int = 1, boss: ForestBoss = null
) -> ForestArrow:
	var projectile := ForestArrow.new()
	projectile.setup(origin, direction, world, boss, null, kind)
	projectile.struck.connect(
		func(at: Vector2, target: String) -> void:
			impacts.append({"position": at, "target": target})
	)
	world.add_child(projectile)
	return projectile


func _test_spear_piercing() -> void:
	for direction in [1, -1]:
		_new_world()
		world.critters.assign([_critter(100), _critter(180), _critter(260)])
		var origin := Vector2(0 if direction > 0 else 360, 110)
		var spear := _launch(&"spear", origin, direction)
		await _step(35)
		var near_index := 0 if direction > 0 else 2
		var far_index := 2 if direction > 0 else 0
		_check(
			world.critters[near_index].out,
			"The spear hits the nearest critter in either direction."
		)
		_check(world.critters[1].out, "The spear continues through a second critter.")
		_check(not world.critters[far_index].out, "A spear cannot defeat a third critter.")
		_check(impacts.size() == 2, "Each pierced critter reports one hit.")
		_check(not is_instance_valid(spear), "The spear is removed after its second target.")
	_new_world()
	var missed := _launch(&"spear", Vector2(0, 30))
	await _step(100)
	_check(not is_instance_valid(missed), "A missed spear cleans up at its finite range.")


func _test_spear_terrain() -> void:
	_new_world()
	world.critters.assign([_critter(90), _critter(220)])
	_platform(Rect2(150, 60, 1, 100))
	await _step(3)
	_launch(&"spear", Vector2(0, 110))
	await _step(35)
	_check(world.critters[0].out, "A spear hits a critter before a wall.")
	_check(not world.critters[1].out, "Piercing cannot pass through a one-pixel wall.")
	_check(
		impacts.size() == 2 and impacts[1].target == "blocked",
		"Terrain stops the spear after its first enemy."
	)
	_check(
		impacts.size() == 2 and absf(impacts[1].position.x - 150) < 0.1,
		"The spear sweep stops exactly at thin terrain."
	)
	_new_world()
	var boss := _boss_fixture("warning")
	world.critters.assign([_critter(310)])
	_launch(&"spear", Vector2(0, 110), 1, boss)
	await _step(40)
	_check(boss.health == 3, "A guarded boss blocks the spear.")
	_check(not world.critters[0].out, "The spear cannot pierce through the boss.")
	boss.phase = "rest"
	_launch(&"spear", Vector2(0, 110), 1, boss)
	await _step(40)
	_check(boss.health == 2, "A spear takes one hit from a resting boss.")
	_check(not world.critters[0].out, "A successful spear boss hit also ends its flight.")


func _test_bomb_arc_and_fuse() -> void:
	for direction in [1, -1]:
		_new_world()
		var bomb := _launch(&"seed_bomb", Vector2(0, 110), direction)
		await _step(12)
		_check(bomb.position.x * direction > 40, "The seed bomb travels in the selected direction.")
		_check(bomb.position.y < 90, "The seed bomb initially rises in an arc.")
		bomb.active = false
		var stopped := bomb.position
		await _step(90)
		_check(bomb.position == stopped, "Pause freezes both bomb motion and its fuse.")
		bomb.active = true
		await _step(40)
		_check(
			is_instance_valid(bomb) and bomb.position.y > 110,
			"Gravity brings the seed bomb down after the apex."
		)
		await _step(25)
		_check(
			is_instance_valid(bomb) and impacts.size() == 1,
			"The fuse produces a visible burst even without a target."
		)
		await _step(20)
		_check(not is_instance_valid(bomb), "The burst cleans itself up after a missed throw.")


func _test_bomb_terrain_and_blast() -> void:
	_new_world()
	var near := _critter(130)
	near.home.y = 145
	var second := _critter(100)
	second.home.y = 150
	var behind_wall := _critter(205)
	var distant := _critter(380)
	world.critters.assign([near, second, behind_wall, distant])
	_platform(Rect2(160, -100, 1, 350))
	await _step(3)
	var bomb := _launch(&"seed_bomb", Vector2(0, 110))
	await _step(34)
	_check(near.out and second.out, "A burst can reach multiple nearby critters.")
	_check(not behind_wall.out, "A blast cannot hit a critter through a thin wall.")
	_check(not distant.out, "A blast cannot hit beyond its radius.")
	_check(
		is_instance_valid(bomb) and bomb.position.x < 160 and bomb.position.x > 156,
		"A terrain impact places the visible burst on the near side of the wall."
	)
	_check(impacts.size() == 2, "A burst reports each affected enemy once.")
	await _step(30)
	_check(not is_instance_valid(bomb), "An impact burst is eventually removed.")
	_new_world()
	var boss := _boss_fixture("rest")
	boss.position.x = 240
	_platform(Rect2(180, -100, 1, 350))
	await _step(3)
	_launch(&"seed_bomb", Vector2(0, 110), 1, boss)
	await _step(50)
	_check(boss.health == 3, "Solid terrain also shields a vulnerable boss from the blast.")


func _test_bomb_direct_contact() -> void:
	_new_world()
	var target := _critter(130)
	target.home.y = 85
	var neighbor := _critter(190)
	world.critters.assign([target, neighbor])
	_launch(&"seed_bomb", Vector2(0, 110))
	await _step(40)
	_check(target.out, "An arcing bomb bursts on direct enemy contact.")
	_check(neighbor.out, "Direct impact also splashes a nearby enemy.")
	_check(impacts.size() == 2, "Direct impact does not damage its target twice.")


func _test_bomb_boss() -> void:
	for phase in ["warning", "rest"]:
		_new_world()
		var boss := _boss_fixture(phase)
		_launch(&"seed_bomb", Vector2(0, 110), 1, boss)
		await _step(45)
		_check(
			boss.health == (2 if phase == "rest" else 3),
			"A bomb respects the boss's guarded and resting phases."
		)
		_check(impacts.size() == 1, "A bomb can only report one boss hit per burst.")
		if phase == "rest":
			_launch(&"seed_bomb", Vector2(0, 110), 1, boss)
			await _step(45)
			_check(boss.health == 2, "A second burst cannot bypass the boss's recovery.")
	_new_world()
	var defeated := _boss_fixture("rest")
	defeated.health = 1
	_launch(&"seed_bomb", Vector2(0, 110), 1, defeated)
	await _step(45)
	_check(defeated.defeated and defeated.health == 0, "A seed bomb can finish the boss.")
	_launch(&"seed_bomb", Vector2(0, 110), 1, defeated)
	await _step(90)
	_check(defeated.health == 0, "A defeated boss cannot take additional blast damage.")


func _test_bomb_pause_and_cleanup() -> void:
	_new_world()
	_platform(Rect2(140, -100, 1, 350))
	await _step(3)
	var bomb := _launch(&"seed_bomb", Vector2(0, 110))
	await _step(30)
	_check(impacts.size() == 1, "The pause probe has already burst against terrain.")
	bomb.active = false
	var position := bomb.position
	await _step(60)
	_check(
		is_instance_valid(bomb) and bomb.position == position,
		"Pausing preserves a visible burst rather than expiring it."
	)
	_check(impacts.size() == 1, "A paused burst does not repeat contact callbacks.")
	bomb.active = true
	await _step(20)
	_check(not is_instance_valid(bomb), "Resuming lets the burst finish and clean up.")


func _boss_fixture(phase: String) -> ForestBoss:
	var boss := ForestBoss.new()
	boss.position = Vector2(220, 130)
	world.add_child(boss)
	boss.active = true
	boss.engaged = true
	boss.phase = phase
	# Isolate projectile contact from the separately tested attack phase clock.
	boss.set_physics_process(false)
	return boss


func _check(condition: bool, message: String) -> void:
	checks += 1
	super._check(condition, message)
