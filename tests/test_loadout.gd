extends SceneTree
## Armor shares a damage budget, so changing sets cannot create extra protection.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_test_reward_progression()
	_test_later_rewards()
	_test_choices()
	_test_armor_budget()
	_test_full_armor_budget()
	_test_catchup_and_reset()
	if failures.is_empty():
		print("PASS: %d expanded loadout checks." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_reward_progression() -> void:
	var gear := ForestEquipment.new()
	_check(gear.rewards_at(0, 0).is_empty(), "The starting camp gives no reward.")
	_check(not gear.set_equipped(&"seed_bomb", true), "Future weapons cannot be equipped early.")
	_check(not gear.set_equipped(&"ironwood_armor", true), "Future armor cannot be equipped early.")
	_check(not gear.set_equipped(&"unknown", true), "Unknown equipment is rejected.")
	_check(gear.rewards_at(0, 1) == [&"bow"], "The forest's second camp awards only the bow.")
	_check(gear.active_weapon() == &"bow", "The first weapon equips automatically.")
	_check(gear.rewards_at(0, 2) == [&"armor"], "The third camp awards leaf armor.")
	_check(
		gear.armor_capacity() == 1 and gear.armor_charge == 1,
		"Leaf armor starts ready for one hit."
	)
	_check(gear.rewards_at(1, 0).is_empty(), "Entering the mill does not skip its reward camp.")
	_check(gear.rewards_at(1, 1) == [&"spear"], "The mill's second camp awards a spear.")
	_check(
		gear.active_weapon() == &"spear" and not gear.is_equipped(&"bow"),
		"A new weapon replaces the old selection."
	)
	_check(gear.rewards_at(2, 1) == [&"bark_armor"], "The canopy's second camp awards bark armor.")
	_check(gear.armor_capacity() == 2, "Bark armor protects against two hits.")
	_check(gear.rewards_at(3, 1) == [&"seed_bomb"], "The cavern's second camp awards seed bombs.")
	_check(
		gear.rewards_at(4, 1) == [&"ironwood_armor"],
		"The ridge's second camp awards ironwood armor."
	)
	_check(
		gear.active_weapon() == &"seed_bomb" and gear.active_armor() == &"ironwood_armor",
		"The latest rewards occupy separate weapon and armor slots."
	)
	_check(gear.armor_capacity() == 3, "Ironwood armor protects against three hits.")
	_check(gear.rewards_at(4, 1).is_empty(), "Revisiting a reward cannot grant it twice.")


func _test_choices() -> void:
	var gear := ForestEquipment.new()
	gear.rewards_at(4, 1)
	_check(gear.set_equipped(&"bow", true), "Earlier weapons can be selected again.")
	_check(
		(
			gear.active_weapon() == &"bow"
			and not gear.is_equipped(&"spear")
			and not gear.is_equipped(&"seed_bomb")
		),
		"Selecting a weapon disables every other weapon."
	)
	_check(gear.active_armor() == &"ironwood_armor", "Changing weapons preserves the armor choice.")
	gear.set_equipped(&"armor", true)
	_check(
		(
			gear.active_armor() == &"armor"
			and not gear.is_equipped(&"bark_armor")
			and not gear.is_equipped(&"ironwood_armor")
		),
		"Selecting armor disables every other armor set."
	)
	_check(gear.active_weapon() == &"bow", "Changing armor preserves the weapon choice.")
	gear.set_equipped(&"bow", false)
	_check(gear.active_weapon().is_empty(), "Turning the selected weapon off leaves an empty slot.")
	_check(gear.active_armor() == &"armor", "An empty weapon slot does not remove armor.")
	gear.set_equipped(&"armor", false)
	_check(
		gear.active_armor().is_empty() and gear.armor_capacity() == 0,
		"Turning armor off removes its protection."
	)
	_check(
		not gear.absorb_hit() and gear.armor_charge == 1,
		"Unequipped armor preserves charge without blocking damage."
	)


func _test_later_rewards() -> void:
	var gear := ForestEquipment.new()
	for reward in [
		[5, &"reed_mail", 4],
		[10, &"frost_armor", 5],
		[12, &"stoneplate", 6],
		[15, &"copperbark_armor", 7],
		[18, &"sunleaf_armor", 8]
	]:
		gear.rewards_at(reward[0], 0)
		_check(not gear.is_unlocked(reward[1]), "Each new set waits for its own reward camp.")
		_check(not gear.set_equipped(reward[1], true), "A locked later set cannot be selected.")
		_check(gear.rewards_at(reward[0], 1) == [reward[1]], "Its second camp awards the new set.")
		_check(gear.active_armor() == reward[1], "The new armor equips immediately.")
		_check(gear.armor_capacity() == reward[2], "The new armor grants its promised capacity.")
		_check(gear.rewards_at(reward[0], 1).is_empty(), "Repeated contact cannot duplicate armor.")
	_check(gear.unlocked.size() == 11, "The complete adventure contains eleven gear rewards.")


func _test_armor_budget() -> void:
	var gear := ForestEquipment.new()
	gear.rewards_at(4, 1)
	gear.set_equipped(&"armor", true)
	_check(gear.absorb_hit() and gear.armor_charge == 0, "Leaf armor spends its one hit.")
	gear.set_equipped(&"armor", false)
	gear.set_equipped(&"armor", true)
	_check(not gear.absorb_hit(), "Toggling spent armor cannot recharge it.")
	gear.set_equipped(&"bark_armor", true)
	_check(gear.armor_charge == 1, "Stronger armor accounts for the hit already absorbed.")
	_check(
		gear.absorb_hit() and gear.armor_charge == 0, "Bark armor provides only one additional hit."
	)
	gear.set_equipped(&"armor", true)
	_check(gear.armor_charge == 0 and not gear.absorb_hit(), "Downgrading cannot erase damage.")
	gear.set_equipped(&"ironwood_armor", true)
	_check(
		gear.armor_charge == 1 and gear.absorb_hit(),
		"Ironwood provides only the last remaining hit."
	)
	for item in [&"armor", &"bark_armor", &"ironwood_armor"]:
		gear.set_equipped(item, true)
		_check(
			gear.armor_charge == 0 and not gear.absorb_hit(),
			"Swapping exhausted sets cannot exceed three total blocked hits."
		)
	gear.recharge()
	_check(gear.armor_charge == 3, "A real recharge restores the selected armor's full capacity.")
	_check(
		gear.absorb_hit() and gear.absorb_hit() and gear.absorb_hit(),
		"Recharged ironwood absorbs three hits."
	)
	_check(not gear.absorb_hit(), "The next hit passes through spent ironwood armor.")


func _test_full_armor_budget() -> void:
	var gear := ForestEquipment.new()
	gear.rewards_at(19, 1)
	var sets := [
		&"armor",
		&"bark_armor",
		&"ironwood_armor",
		&"reed_mail",
		&"frost_armor",
		&"stoneplate",
		&"copperbark_armor",
		&"sunleaf_armor"
	]
	for armor in sets:
		_check(gear.set_equipped(armor, true), "Every earned armor can be worn.")
		_check(gear.armor_charge == 1, "Upgrading preserves all earlier absorbed damage.")
		_check(
			gear.absorb_hit() and gear.armor_charge == 0, "Each upgrade adds only its extra hit."
		)
	for armor in sets:
		gear.set_equipped(armor, true)
		_check(not gear.absorb_hit(), "No swap can exceed the eight-hit protection budget.")
	gear.recharge()
	_check(gear.armor_charge == 8, "A real repair restores all eight Sunleaf blocks.")
	for hit in 8:
		_check(gear.absorb_hit(), "Repaired Sunleaf armor absorbs each of its eight hits.")
	_check(not gear.absorb_hit(), "A ninth hit cannot be absorbed before the next repair.")


func _test_catchup_and_reset() -> void:
	var gear := ForestEquipment.new()
	_check(gear.rewards_at(19, 2).size() == 11, "A later checkpoint catches up all missed rewards.")
	_check(
		gear.active_weapon() == &"seed_bomb" and gear.active_armor() == &"sunleaf_armor",
		"Catchup equips the latest reward in each category."
	)
	gear.set_equipped(&"spear", true)
	gear.set_equipped(&"bark_armor", true)
	gear.absorb_hit()
	_check(gear.rewards_at(0, 3).is_empty(), "Backtracking grants no duplicate equipment.")
	_check(
		(
			gear.active_weapon() == &"spear"
			and gear.active_armor() == &"bark_armor"
			and gear.armor_charge == 1
		),
		"Backtracking preserves choices and spent protection."
	)
	gear.reset()
	_check(
		gear.unlocked.is_empty() and gear.equipped.is_empty(),
		"Restart clears ownership and choices."
	)
	_check(
		(
			gear.active_weapon().is_empty()
			and gear.active_armor().is_empty()
			and gear.armor_charge == 0
		),
		"Restart leaves no weapon or armor protection."
	)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
