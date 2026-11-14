extends "res://tests/test_game.gd"
## Checkpoint rewards, equipment controls, shooting, armor and adventure state.

var shots_fired := 0


func _run() -> void:
	_test_reward_rules()
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	_press_button("Start adventure")
	game.sound.muted = true
	await _step(3)
	game.arrows.child_entered_tree.connect(func(_arrow: Node) -> void: shots_fired += 1)
	await _test_reward_controls()
	await _test_shooting_and_pause()
	await _test_shooting_direction()
	await _test_armor_and_retry()
	await _test_boss_armor()
	await _test_equipment_progression()
	for code in [KEY_J, KEY_ESCAPE, KEY_LEFT, KEY_SHIFT]:
		_key(code, false)
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d equipment and reward integration checks." % checks)
		print("Checkpoint unlocks, bow input/cooldown/pause, armor, retries, choices and replay.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_reward_rules() -> void:
	var gear := ForestEquipment.new()
	_check(gear.rewards_at(0, 0).is_empty(), "The starting camp does not award equipment.")
	_check(not gear.set_equipped(&"bow", true), "A locked bow cannot be equipped.")
	_check(not gear.set_equipped(&"unknown", true), "Unknown equipment is refused.")
	_check(not gear.absorb_hit(), "Locked armor cannot absorb a hit.")
	var first := gear.rewards_at(0, 1)
	_check(first == [&"bow"], "The first reached checkpoint awards the bow alone.")
	_check(gear.is_equipped(&"bow"), "The rewarded bow is equipped immediately.")
	_check(
		gear.rewards_at(0, 1).is_empty(), "An already visited checkpoint cannot duplicate a reward."
	)
	_check(not gear.is_unlocked(&"armor"), "Armor remains locked until the next checkpoint.")
	_check(gear.rewards_at(0, 2) == [&"armor"], "The next checkpoint awards leaf armor.")
	_check(
		gear.is_equipped(&"bow") and gear.is_equipped(&"armor"),
		"Bow and armor can be worn together."
	)
	_check(gear.absorb_hit() and not gear.absorb_hit(), "One armor charge blocks exactly one hit.")
	gear.set_equipped(&"armor", false)
	gear.set_equipped(&"armor", true)
	_check(gear.armor_charge == 0, "Re-equipping spent armor does not refill it.")
	gear.recharge()
	gear.set_equipped(&"armor", false)
	_check(
		not gear.absorb_hit() and gear.armor_charge == 1, "Unequipped armor preserves its charge."
	)
	gear.reset()
	_check(
		gear.unlocked.is_empty() and gear.equipped.is_empty(),
		"Reset clears reward ownership and choices."
	)
	_check(gear.armor_charge == 0, "Reset clears the armor charge.")
	var caught_up := gear.rewards_at(2, 1)
	_check(
		caught_up.has(&"bow") and caught_up.has(&"armor"),
		"A later checkpoint grants missed rewards."
	)
	_check(gear.rewards_at(0, 3).is_empty(), "Backtracking does not duplicate caught-up rewards.")


func _test_reward_controls() -> void:
	await _tap(KEY_ESCAPE)
	var bow := _find_button(game.hud, "Bow") as CheckButton
	var armor := _find_button(game.hud, "Leaf armor") as CheckButton
	_check(bow != null and armor != null, "Pause exposes the bow and armor controls.")
	if bow != null and armor != null:
		_check(bow.disabled and armor.disabled, "Unearned equipment controls are disabled.")
		_check(
			not bow.button_pressed and not armor.button_pressed,
			"Locked equipment is shown unequipped."
		)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_J)
	_check(shots_fired == 0, "J cannot fire before the bow reward.")
	game.fox.reset_at(game.level.camps[1])
	await _step(3)
	_check(game.level.camp_index == 1, "Real checkpoint contact records the camp.")
	_check(game.equipment.is_equipped(&"bow"), "Real checkpoint contact awards and equips the bow.")
	_check(game.fox.bow_equipped, "The reward makes the bow visible on the fox.")
	_check(
		not game.equipment.is_unlocked(&"armor"), "The first reward does not unlock armor early."
	)
	await _tap(KEY_ESCAPE)
	bow = _find_button(game.hud, "Bow") as CheckButton
	armor = _find_button(game.hud, "Leaf armor") as CheckButton
	_check(
		bow != null and not bow.disabled and bow.button_pressed,
		"The earned bow control is enabled and on."
	)
	_check(armor != null and armor.disabled, "Armor stays disabled at the bow checkpoint.")
	if bow != null:
		bow.button_pressed = false
		_check(
			not game.equipment.is_equipped(&"bow") and not game.fox.bow_equipped,
			"The bow control unequips actual gear."
		)
		bow.button_pressed = true
		_check(
			game.equipment.is_equipped(&"bow") and game.fox.bow_equipped,
			"The bow control equips actual gear again."
		)
	await _tap(KEY_ESCAPE)
	game._toggle_equipment(&"bow", false)
	_check(
		game.equipment.is_equipped(&"bow"), "Equipment changes are refused outside the pause menu."
	)


func _test_shooting_and_pause() -> void:
	game.fox.reset_at(Vector2(140, 300))
	var before := shots_fired
	_key(KEY_J, true)
	await _step(1)
	_check(shots_fired == before + 1, "A real J key press fires one arrow.")
	await _step(40)
	_check(shots_fired == before + 1, "Holding J through the cooldown does not repeat fire.")
	_key(KEY_J, false)
	await _step(1)
	_key(KEY_J, true)
	await _step(1)
	_check(shots_fired == before + 2, "A fresh J press fires after cooldown.")
	_key(KEY_J, false)
	await _step(1)
	_key(KEY_J, true)
	await _step(1)
	_check(shots_fired == before + 2, "Rapid repeated input respects the shot cooldown.")
	_key(KEY_J, false)
	await _step(30)
	game._clear_arrows()
	game.fox.reset_at(Vector2(140, 300))
	await _tap(KEY_J)
	await _tap(KEY_ESCAPE)
	_check(game.arrows.get_child_count() == 1, "A live arrow remains visible when paused.")
	if game.arrows.get_child_count() == 1:
		var arrow: Node2D = game.arrows.get_child(0)
		var position := arrow.position
		var traveled: float = arrow.traveled
		var cooldown: float = game.shot_cooldown
		await _step(15)
		_check(
			arrow.position == position and arrow.traveled == traveled,
			"Pause freezes arrow flight and range."
		)
		_check(game.shot_cooldown == cooldown, "Pause freezes the shot cooldown.")
		before = shots_fired
		await _tap(KEY_J)
		_check(shots_fired == before, "J cannot fire while the equipment menu is open.")
		await _tap(KEY_ESCAPE)
		await _step(2)
		_check(arrow.position.x > position.x, "Resume continues the paused arrow.")
		_check(game.shot_cooldown < cooldown, "Resume continues the shot cooldown.")
	else:
		await _tap(KEY_ESCAPE)
	game._clear_arrows()


func _test_shooting_direction() -> void:
	game.fox.reset_at(Vector2(140, 300))
	game.shot_cooldown = 0.0
	await _step(3)
	_key(KEY_LEFT, true)
	_key(KEY_J, true)
	await _step(1)
	_key(KEY_LEFT, false)
	_key(KEY_J, false)
	_check(game.fox.sprite.flip_h, "Turning and firing together visibly turns the fox left.")
	_check(game.arrows.get_child_count() == 1, "Turning and firing together produces one arrow.")
	if game.arrows.get_child_count() == 1:
		var arrow: Node2D = game.arrows.get_child(0)
		var start_x := arrow.position.x
		await _step(3)
		_check(arrow.position.x < start_x - 20, "The simultaneous left-turn shot flies left.")
	game._clear_arrows()
	game.fox.reset_at(Vector2(140, 300))
	game.shot_cooldown = 0.0
	await _step(3)
	_key(KEY_SHIFT, true)
	await _step(2)
	_key(KEY_SHIFT, false)
	_key(KEY_LEFT, true)
	_key(KEY_J, true)
	await _step(1)
	_key(KEY_LEFT, false)
	_key(KEY_J, false)
	_check(game.fox.dash_left > 0.0, "The opposite-direction shot occurs during an active dash.")
	_check(not game.fox.sprite.flip_h, "Opposite input keeps the dashing fox facing right.")
	_check(game.arrows.get_child_count() == 1, "Shooting during a dash produces one arrow.")
	if game.arrows.get_child_count() == 1:
		var arrow: Node2D = game.arrows.get_child(0)
		var start_x := arrow.position.x
		await _step(3)
		_check(
			arrow.position.x > start_x + 20, "The dash shot flies in its locked right direction."
		)
	game._clear_arrows()


func _test_armor_and_retry() -> void:
	game.fox.reset_at(game.level.camps[2])
	await _step(3)
	_check(
		game.equipment.is_equipped(&"armor") and game.fox.armor_equipped,
		"The next checkpoint equips visible armor."
	)
	_check(game.equipment.armor_charge == 1, "New armor starts with one charge.")
	var spike: Rect2 = game.level.spikes[0]
	game.invincible_left = 0.0
	game.fox.reset_at(Vector2(spike.get_center().x, ForestLevel.FLOOR_Y))
	await _step(2)
	_check(game.state == Adventure.State.PLAYING, "Armor prevents retry on the first spike hit.")
	_check(
		game.equipment.armor_charge == 0 and not game.fox.armor_charged,
		"A blocked hit spends and visually updates armor."
	)
	_check(game.invincible_left > 0.0, "A blocked hit gives time to leave the hazard.")
	game.fox.reset_at(game.level.camps[2])
	await _step(3)
	_check(game.equipment.armor_charge == 0, "Returning to an old camp does not refill armor.")
	await _tap(KEY_ESCAPE)
	var armor := _find_button(game.hud, "Leaf armor") as CheckButton
	_check(
		armor != null and not armor.disabled, "Earned armor exposes an enabled equipment control."
	)
	if armor != null:
		armor.button_pressed = false
		_check(not game.fox.armor_equipped, "Unequipping armor removes its visible equipment.")
		armor.button_pressed = true
		_check(game.equipment.armor_charge == 0, "The menu cannot refill armor by toggling it.")
	await _tap(KEY_ESCAPE)
	game.fox.reset_at(game.level.camps[3])
	await _step(3)
	_check(game.equipment.armor_charge == 1, "A newly reached camp recharges spent armor.")
	await _step(30)
	await _tap(KEY_J)
	_check(game.arrows.get_child_count() > 0, "The retry probe starts with an arrow in flight.")
	game.invincible_left = 0.0
	game.fox.reset_at(Vector2(spike.get_center().x, ForestLevel.FLOOR_Y))
	await _step(1)
	game.invincible_left = 0.0
	await _step(1)
	_check(
		game.state == Adventure.State.RESPAWNING,
		"A second spike hit after immunity exhausts armor protection."
	)
	_check(game.arrows.get_child_count() == 0, "Retry clears arrows immediately.")
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "An armored failure recovers at the checkpoint.")
	_check(
		game.equipment.is_equipped(&"bow") and game.equipment.is_equipped(&"armor"),
		"Retry preserves earned and equipped gear."
	)
	_check(
		game.equipment.armor_charge == 1 and game.shot_cooldown == 0,
		"Retry recharges armor and resets weapon timing."
	)
	game.fox.reset_at(Vector2(2200, 760))
	await _step(2)
	_check(game.state == Adventure.State.RESPAWNING, "Charged armor cannot prevent a fall retry.")
	await _step(55)
	var critter: Dictionary = game.level.critters[0]
	game.invincible_left = 0.0
	game.fox.reset_at(game.level.critter_position(critter))
	await _step(1)
	_check(
		game.state == Adventure.State.PLAYING, "Armor also absorbs contact from a walking critter."
	)
	_check(
		game.equipment.armor_charge == 0, "Critter contact spends the same one-hit armor charge."
	)


func _test_boss_armor() -> void:
	game.equipment.reset()
	game._load_chapter(2)
	game._set_state(Adventure.State.PLAYING)
	for index in 3:
		game.level.taken_acorns[index] = true
	game.fox.reset_at(game.level.camps[3])
	await _step(2)
	_check(game.boss_started, "Reaching the prepared clearing starts the boss.")
	_check(
		game.equipment.is_equipped(&"bow") and game.equipment.is_equipped(&"armor"),
		"The boss checkpoint catches up missed equipment rewards."
	)
	game.invincible_left = 0.0
	game.boss.player_hit.emit()
	_check(
		game.player_health == 3 and game.equipment.armor_charge == 0,
		"Armor absorbs a boss hit without losing a heart."
	)
	game.boss.player_hit.emit()
	_check(game.player_health == 3, "Immediate repeated boss contact respects armor immunity.")
	game.invincible_left = 0.0
	game.boss.player_hit.emit()
	_check(game.player_health == 2, "Spent armor allows the next boss hit to cost a heart.")


func _test_equipment_progression() -> void:
	game._load_chapter(0)
	game._set_state(Adventure.State.PLAYING)
	await _tap(KEY_ESCAPE)
	var bow := _find_button(game.hud, "Bow") as CheckButton
	var armor := _find_button(game.hud, "Leaf armor") as CheckButton
	if bow != null and armor != null:
		bow.button_pressed = false
		armor.button_pressed = true
	_check(
		not game.equipment.is_equipped(&"bow") and game.equipment.is_equipped(&"armor"),
		"The player can choose armor without the bow."
	)
	game._set_state(Adventure.State.CHAPTER_COMPLETE)
	game.next_chapter()
	await _step(3)
	_check(game.stage_index == 1, "The progression probe reaches the next chapter.")
	_check(
		not game.equipment.is_equipped(&"bow") and game.equipment.is_equipped(&"armor"),
		"Chapter changes preserve independent equipment choices."
	)
	_check(
		game.equipment.is_unlocked(&"bow") and game.equipment.is_unlocked(&"armor"),
		"Chapter changes preserve unlocked equipment."
	)
	_check(
		not game.fox.bow_equipped and game.fox.armor_equipped,
		"The fox artwork follows choices after chapter loading."
	)
	var before := shots_fired
	await _tap(KEY_J)
	_check(
		shots_fired == before and game.arrows.get_child_count() == 0,
		"An unequipped bow cannot fire."
	)
	await _tap(KEY_ESCAPE)
	_press_button("Restart all chapters")
	await _step(3)
	_check(
		game.stage_index == 0 and game.state == Adventure.State.PLAYING,
		"Replay starts a fresh first chapter."
	)
	_check(
		game.equipment.unlocked.is_empty() and game.equipment.equipped.is_empty(),
		"Replay clears all equipment rewards and choices."
	)
	_check(
		not game.fox.bow_equipped and not game.fox.armor_equipped,
		"Replay removes both equipment visuals."
	)
	_check(
		game.arrows.get_child_count() == 0 and game.equipment.armor_charge == 0,
		"Replay leaves no projectiles or armor charge."
	)


func _tap(code: Key) -> void:
	_key(code, true)
	await _step(1)
	_key(code, false)
	await _step(1)
