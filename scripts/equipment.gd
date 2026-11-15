class_name ForestEquipment
extends RefCounted
## One weapon and one armor choice, carried between checkpoints and chapters.

const ITEMS := [
	{
		"id": &"bow",
		"name": "Bow",
		"category": &"weapon",
		"description": "Fast, straight arrows. J to fire.",
		"unlock_hint": "Emberwood: second campfire.",
		"chapter": 0,
		"camp": 1,
		"cooldown": 0.35,
		"speed": 700.0,
		"range": 700.0,
		"pierce": 1
	},
	{
		"id": &"armor",
		"name": "Leaf armor",
		"category": &"armor",
		"description": "Blocks 1 hit between campfires.",
		"unlock_hint": "Emberwood: third campfire.",
		"chapter": 0,
		"camp": 2,
		"capacity": 1,
		"armor_color": Color("90aa70"),
		"armor_edge": Color("354e44"),
		"armor_art": &"leaf"
	},
	{
		"id": &"spear",
		"name": "Throwing spear",
		"category": &"weapon",
		"description": "Pierces two critters. J to throw.",
		"unlock_hint": "Flooded Mill: second campfire.",
		"chapter": 1,
		"camp": 1,
		"cooldown": 0.6,
		"speed": 560.0,
		"range": 800.0,
		"pierce": 2
	},
	{
		"id": &"bark_armor",
		"name": "Bark armor",
		"category": &"armor",
		"description": "Blocks 2 hits between campfires.",
		"unlock_hint": "High Canopy: second campfire.",
		"chapter": 2,
		"camp": 1,
		"capacity": 2,
		"armor_color": Color("b38a57"),
		"armor_edge": Color("63472e"),
		"armor_art": &"bark"
	},
	{
		"id": &"seed_bomb",
		"name": "Seed bombs",
		"category": &"weapon",
		"description": "Lob a seed that bursts nearby. J to throw.",
		"unlock_hint": "Moss Caverns: second campfire.",
		"chapter": 3,
		"camp": 1,
		"cooldown": 0.8,
		"speed": 330.0,
		"range": 900.0,
		"pierce": 1,
		"gravity": 620.0,
		"lift": -240.0,
		"fuse": 1.2,
		"radius": 100.0
	},
	{
		"id": &"ironwood_armor",
		"name": "Ironwood armor",
		"category": &"armor",
		"description": "Blocks 3 hits between campfires.",
		"unlock_hint": "Sunlit Ridge: second campfire.",
		"chapter": 4,
		"camp": 1,
		"capacity": 3,
		"armor_color": Color("83948c"),
		"armor_edge": Color("3a514e"),
		"armor_art": &"ironwood"
	},
	{
		"id": &"reed_mail",
		"name": "Reed mail",
		"category": &"armor",
		"description": "Woven reeds block 4 hits between camps.",
		"unlock_hint": "Reedbank Trail: second campfire.",
		"chapter": 5,
		"camp": 1,
		"capacity": 4,
		"armor_color": Color("b6ad6a"),
		"armor_edge": Color("4d6041"),
		"armor_art": &"reeds"
	},
	{
		"id": &"thorn_fan",
		"name": "Thorn fan",
		"category": &"weapon",
		"description": "Three spreading thorns. Short range. J to fire.",
		"unlock_hint": "Willow Narrows: second campfire.",
		"chapter": 6,
		"camp": 1,
		"cooldown": 0.65,
		"speed": 600.0,
		"range": 480.0,
		"pierce": 1,
		"angles": [-0.22, 0.0, 0.22]
	},
	{
		"id": &"frost_armor",
		"name": "Frost armor",
		"category": &"armor",
		"description": "A lined coat blocks 5 hits between camps.",
		"unlock_hint": "Frostpine Pass: second campfire.",
		"chapter": 10,
		"camp": 1,
		"capacity": 5,
		"armor_color": Color("94b7b7"),
		"armor_edge": Color("41626d"),
		"armor_art": &"frost"
	},
	{
		"id": &"stoneplate",
		"name": "Stoneplate",
		"category": &"armor",
		"description": "Layered slate blocks 6 hits between camps.",
		"unlock_hint": "Slate Heights: second campfire.",
		"chapter": 12,
		"camp": 1,
		"capacity": 6,
		"armor_color": Color("a9aaa3"),
		"armor_edge": Color("505960"),
		"armor_art": &"slate"
	},
	{
		"id": &"copperbark_armor",
		"name": "Copperbark armor",
		"category": &"armor",
		"description": "Riveted bark blocks 7 hits between camps.",
		"unlock_hint": "Copperbark Woods: second campfire.",
		"chapter": 15,
		"camp": 1,
		"capacity": 7,
		"armor_color": Color("bc8559"),
		"armor_edge": Color("68483b"),
		"armor_art": &"copper"
	},
	{
		"id": &"sunwood_lance",
		"name": "Sunwood lance",
		"category": &"weapon",
		"description": "Pierces four critters. Long reach, slower throws.",
		"unlock_hint": "Rootbound Ruins: second campfire.",
		"chapter": 16,
		"camp": 1,
		"cooldown": 1.0,
		"speed": 440.0,
		"range": 1050.0,
		"pierce": 4
	},
	{
		"id": &"sunleaf_armor",
		"name": "Sunleaf armor",
		"category": &"armor",
		"description": "Golden leaves block 8 hits between camps.",
		"unlock_hint": "Sunleaf Crown: second campfire.",
		"chapter": 18,
		"camp": 1,
		"capacity": 8,
		"armor_color": Color("d1ba68"),
		"armor_edge": Color("68703c"),
		"armor_art": &"sunleaf"
	}
]

var unlocked: Dictionary = {}
var equipped: Dictionary = {}
var armor_charge: int:
	get:
		return maxi(0, int(definition(_last_armor).get("capacity", 0)) - _armor_damage)
	set(value):
		_armor_damage = maxi(0, int(definition(_last_armor).get("capacity", 0)) - maxi(value, 0))

var _last_armor: StringName = &""
var _armor_damage := 0


static func definition(item_id: StringName) -> Dictionary:
	for item in ITEMS:
		if item.id == item_id:
			return item
	return {}


func reset() -> void:
	unlocked.clear()
	equipped.clear()
	_last_armor = &""
	_armor_damage = 0


func rewards_at(chapter: int, camp: int) -> Array[StringName]:
	var rewards: Array[StringName] = []
	for item in ITEMS:
		if chapter < item.chapter or (chapter == item.chapter and camp < item.camp):
			continue
		if is_unlocked(item.id):
			continue
		unlocked[item.id] = true
		set_equipped(item.id, true)
		rewards.append(item.id)
	return rewards


func is_unlocked(item_id: StringName) -> bool:
	return unlocked.has(item_id) and not definition(item_id).is_empty()


func is_equipped(item_id: StringName) -> bool:
	return is_unlocked(item_id) and bool(equipped.get(item_id, false))


func set_equipped(item_id: StringName, enabled: bool) -> bool:
	if not is_unlocked(item_id):
		return false
	var item := definition(item_id)
	if enabled:
		for other in ITEMS:
			if other.category == item.category:
				equipped[other.id] = false
		if item.category == &"armor":
			_last_armor = item_id
	equipped[item_id] = enabled
	return true


func active_weapon() -> StringName:
	return _active_in(&"weapon")


func active_armor() -> StringName:
	return _active_in(&"armor")


func armor_capacity() -> int:
	return int(definition(active_armor()).get("capacity", 0))


func recharge() -> void:
	_armor_damage = 0


func absorb_hit() -> bool:
	if active_armor().is_empty() or armor_charge <= 0:
		return false
	# Swapping sets never restores spent protection; all armor shares this budget.
	_armor_damage += 1
	return true


func _active_in(category: StringName) -> StringName:
	for item in ITEMS:
		if item.category == category and is_equipped(item.id):
			return item.id
	return &""
