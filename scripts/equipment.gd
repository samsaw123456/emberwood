class_name ForestEquipment
extends RefCounted
## Equipment belongs to this adventure, surviving retries and chapter changes.

const ITEMS := [
	{
		"id": &"bow",
		"name": "Bow",
		"description": "J fires an arrow in the direction you face.",
		"unlock_hint": "Reward at Emberwood's second campfire.",
		"chapter": 0,
		"camp": 1
	},
	{
		"id": &"armor",
		"name": "Leaf armor",
		"description": "Blocks one hit. Recharges at a new campfire or on retry.",
		"unlock_hint": "Reward at Emberwood's third campfire.",
		"chapter": 0,
		"camp": 2
	}
]

var unlocked: Dictionary = {}
var equipped: Dictionary = {}
var armor_charge := 0


func reset() -> void:
	unlocked.clear()
	equipped.clear()
	armor_charge = 0


func rewards_at(chapter: int, camp: int) -> Array[StringName]:
	var rewards: Array[StringName] = []
	for item in ITEMS:
		if chapter < item.chapter or (chapter == item.chapter and camp < item.camp):
			continue
		if is_unlocked(item.id):
			continue
		unlocked[item.id] = true
		equipped[item.id] = true
		rewards.append(item.id)
		if item.id == &"armor":
			armor_charge = 1
	return rewards


func is_unlocked(item_id: StringName) -> bool:
	return unlocked.has(item_id)


func is_equipped(item_id: StringName) -> bool:
	return is_unlocked(item_id) and bool(equipped.get(item_id, false))


func set_equipped(item_id: StringName, enabled: bool) -> bool:
	if not is_unlocked(item_id):
		return false
	equipped[item_id] = enabled
	return true


func recharge() -> void:
	if is_unlocked(&"armor"):
		armor_charge = 1


func absorb_hit() -> bool:
	if not is_equipped(&"armor") or armor_charge <= 0:
		return false
	armor_charge = 0
	return true
