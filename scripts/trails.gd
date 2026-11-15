class_name ForestTrails
extends RefCounted
## Curated courses reuse traversal sections; their route follows the same geometry.

const FLOOR := 536.0
const SECTION_WIDTH := 900.0
const COURSES := [
	["stones", "lift", "thorns"],
	["ferry", "arch", "stones"],
	["ruins", "crumble", "lift"],
	["lift", "thorns", "ferry"],
	["arch", "ferry", "crumble"],
	["stones", "arch", "ruins"],
	["lift", "crumble", "ferry"],
	["arch", "ruins", "stones"],
	["ferry", "stones", "lift"],
	["crumble", "arch", "ferry"],
	["thorns", "ruins", "arch"],
	["ruins", "arch", "crumble"],
	["thorns", "lift", "ruins"],
	["arch", "crumble", "thorns"],
	["ruins", "ferry", "arch"]
]
const LANDMARKS := [
	["Reed islands", "The old sluice", "Thornbank"],
	["Willow ferry", "Bent branches", "Narrow stones"],
	["Broken arches", "Loose masonry", "The water lift"],
	["Heron's perch", "Rush beds", "Marsh ferry"],
	["Above the falls", "Crossing the spray", "The last footbridge"],
	["Pine stepping stones", "Snow shelves", "A sheltered arch"],
	["Meltwater lift", "The cracked crossing", "Across the gorge"],
	["Slate staircase", "Stoneplate lookout", "The high traverse"],
	["Whitewater ferry", "River stones", "Rising mist"],
	["Cloud bridge", "Above the pines", "The wind crossing"],
	["Copper thorns", "Old roots", "The amber bough"],
	["Rootbound arches", "The lost stair", "Fallen beams"],
	["Firefly thicket", "Hollow lift", "The lantern arch"],
	["Sunleaf lookout", "Crown crossing", "Golden brambles"],
	["The oldest roots", "Heartwood crossing", "Homeward arch"]
]


static func layout(index: int, title: String) -> Dictionary:
	var course: Array = COURSES[index - 5]
	var names: Array = LANDMARKS[index - 5]
	var data := {
		"title": title,
		"width": 3100.0,
		"gate": Vector2(2940, FLOOR),
		"gate_label": "The heartwood clearing" if index == 19 else "The onward trail",
		"ground": [],
		"ledges": [],
		"moving": [],
		"crumble": [],
		"spikes": [],
		"acorns": [],
		"camps": [Vector2(140, FLOOR)],
		"mushrooms": [],
		"secret": Vector2.ZERO,
		"critters": [],
		"gems": [],
		"signs": [],
		"route": [],
		"zones": names.duplicate()
	}
	for section in 3:
		var origin := section * SECTION_WIDTH
		var shape := _section(course[section])
		_append_section(data, shape, origin, section == 1)
		data.signs.append([Vector2(origin + 130, 315), names[section], shape.hint])
	# The middle bank has room for a monster, clear of campfires, gaps and spikes.
	data.critters.append(
		{
			"home": Vector2(1030, FLOOR),
			"range": 40.0,
			"speed": 1.5,
			"out": false,
			"kind": ForestCritters.KINDS[1 + (index - 5) % 3]
		}
	)
	for step: Array in data.route:
		if step[0] == "walk" and step[1] >= 1100 and step[1] <= 1120:
			step[0] = "jump"
	data.ground.append(Vector2(2700, 3100))
	data.spikes.append(Vector2(2750, 70))
	data.critters.append({"home": Vector2(2850, FLOOR), "range": 18.0, "speed": 1.5, "out": false})
	data.route.append(["walk", 2700.0, FLOOR])
	data.route.append(["jump", 2940.0, FLOOR])
	return data


static func _section(kind: String) -> Dictionary:
	var section := {
		"ground": [Vector2(0, 300), Vector2(740, SECTION_WIDTH)],
		"ledges": [],
		"moving": [],
		"crumble": [],
		"spikes": [],
		"critters": [],
		"path": [["walk", 220.0, FLOOR]],
		"acorn": Vector2.ZERO,
		"hint": ""
	}
	match kind:
		"stones":
			_add_step(section, Rect2(360, 455, 120, 28))
			_add_step(section, Rect2(550, 390, 130, 28), "ledge", true)
			section.hint = "Hop between the stones. An acorn waits on the higher ledge."
		"lift":
			_add_step(section, Rect2(380, 430, 140, 28), "moving", false, Vector2(0, 36))
			_add_step(section, Rect2(600, 390, 120, 28), "ledge", true)
			section.hint = "Blue platforms rise and fall. Jump when the next ledge is close."
		"crumble":
			_add_step(section, Rect2(350, 455, 110, 28), "crumble")
			_add_step(section, Rect2(530, 420, 110, 28), "crumble", true)
			_add_step(section, Rect2(685, 465, 100, 28), "crumble")
			section.hint = "The cracked crossing falls away. Keep your jumps moving."
		"arch":
			_add_step(section, Rect2(330, 445, 120, 28))
			_add_step(section, Rect2(500, 355, 125, 28), "ledge", true)
			_add_step(section, Rect2(665, 430, 115, 28))
			section.hint = "Climb the high arch. A second jump gives you more height."
		"thorns":
			section.ground = [Vector2(0, SECTION_WIDTH)]
			section.spikes = [Vector2(290, 90), Vector2(650, 80)]
			section.path = [["walk", 200.0, FLOOR]]
			_add_step(section, Rect2(400, 400, 140, 28), "ledge", true)
			_add_step(section, Rect2(620, 460, 110, 28))
			section.critters = [
				{"home": Vector2(575, FLOOR), "range": 30.0, "speed": 1.7, "out": false}
			]
			section.hint = "Take the upper shelves over the thorns and wandering critters."
		"ferry":
			_add_step(section, Rect2(360, 455, 130, 28), "moving", false, Vector2(35, 0))
			_add_step(section, Rect2(590, 410, 130, 28), "moving", true, Vector2(0, 35))
			section.hint = "The two ferries move differently. Watch before you leap."
		"ruins":
			section.ground = [Vector2(0, 290), Vector2(660, SECTION_WIDTH)]
			section.path = [["walk", 210.0, FLOOR]]
			_add_step(section, Rect2(335, 450, 110, 28))
			_add_step(section, Rect2(500, 380, 130, 28), "crumble")
			_add_step(section, Rect2(660, 330, 120, 28), "ledge", true)
			section.critters = [
				{"home": Vector2(735, FLOOR), "range": 22.0, "speed": 1.4, "out": false}
			]
			section.hint = "A broken beam leads to the old lookout. Keep one jump in reserve."
	section.path.append(["jump", 810.0, FLOOR])
	return section


static func _add_step(
	section: Dictionary, rect: Rect2, kind := "ledge", acorn := false, motion := Vector2.ZERO
) -> void:
	var landing := rect.position + Vector2(rect.size.x / 2, 0)
	if kind == "moving":
		section.moving.append([rect, motion])
		section.path.append(["moving", rect.position.x, rect.position.y])
	elif kind == "crumble":
		section.crumble.append(rect)
		section.path.append(["jump", landing.x, landing.y])
	else:
		section.ledges.append(rect)
		section.path.append(["jump", landing.x, landing.y])
	if acorn:
		section.acorn = landing - Vector2(0, 36)


static func _append_section(
	data: Dictionary, section: Dictionary, origin: float, hide_firefly: bool
) -> void:
	var offset := Vector2(origin, 0)
	for span: Vector2 in section.ground:
		data.ground.append(span + Vector2(origin, origin))
	for field in ["ledges", "crumble"]:
		for rect: Rect2 in section[field]:
			data[field].append(Rect2(rect.position + offset, rect.size))
	for moving: Array in section.moving:
		var rect: Rect2 = moving[0]
		data.moving.append([Rect2(rect.position + offset, rect.size), moving[1]])
	for spike: Vector2 in section.spikes:
		data.spikes.append(spike + Vector2(origin, 0))
	for critter: Dictionary in section.critters:
		var placed := critter.duplicate()
		placed.home += offset
		data.critters.append(placed)
	var acorn: Vector2 = section.acorn + offset
	data.acorns.append(acorn)
	data.camps.append(Vector2(origin + 810, FLOOR))
	if hide_firefly:
		data.secret = acorn - Vector2(0, 38)
	var first: Array = section.path[1]
	for gem in [
		Vector2(origin + 200, 490),
		Vector2(origin + first[1] + 25, first[2] - 36),
		acorn + Vector2(35, 0),
		acorn + Vector2(-30, -36),
		Vector2(origin + 730, 460),
		Vector2(origin + 810, 490)
	]:
		data.gems.append(gem)
	for step: Array in section.path:
		data.route.append([step[0], step[1] + origin, step[2]])
