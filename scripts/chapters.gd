class_name ForestChapters
extends RefCounted
## Hand-built routes. Coordinates use the same feet-based scale as the fox.

const TITLES := [
	"Emberwood",
	"Flooded Mill",
	"High Canopy",
	"Moss Caverns",
	"Sunlit Ridge",
	"Reedbank Trail",
	"Willow Narrows",
	"Broken Aqueduct",
	"Heron Marsh",
	"Riverwatch Falls",
	"Frostpine Pass",
	"Snowmelt Gorge",
	"Slate Heights",
	"Whitewater Steps",
	"Cloudline Crossing",
	"Copperbark Woods",
	"Rootbound Ruins",
	"Lantern Hollow",
	"Sunleaf Crown",
	"Heart of Emberwood"
]
const CAMPAIGN_BEST_KEY := "forest_monsters_best_time"
# One guardian every third chapter. Shared rules keep the gold-cap opening readable.
const GUARDIANS := [
	{
		"name": "Old Croak",
		"animal": &"frog",
		"cap": "627545",
		"warning": 1.1,
		"leap": 0.82,
		"height": 110.0,
		"wave": 170.0,
		"rest": 2.1
	},
	{
		"name": "Reed Rumbler",
		"animal": &"opossum",
		"cap": "899b42",
		"warning": 1.2,
		"leap": 0.9,
		"height": 130.0,
		"wave": 185.0,
		"rest": 2.2
	},
	{
		"name": "Marsh Tusk",
		"animal": &"boar",
		"cap": "56898f",
		"warning": 1.05,
		"leap": 0.75,
		"height": 100.0,
		"wave": 200.0,
		"rest": 2.1
	},
	{
		"name": "Frost Fang",
		"animal": &"wolf",
		"cap": "8cabc4",
		"warning": 1.2,
		"leap": 1.0,
		"height": 155.0,
		"wave": 210.0,
		"rest": 2.25
	},
	{
		"name": "Cloudwing",
		"animal": &"eagle",
		"cap": "9694b4",
		"warning": 1.1,
		"leap": 0.95,
		"height": 180.0,
		"wave": 220.0,
		"rest": 2.2
	},
	{
		"name": "Lantern Owl",
		"animal": &"owl",
		"cap": "b8823f",
		"warning": 1.0,
		"leap": 0.85,
		"height": 140.0,
		"wave": 235.0,
		"rest": 2.1
	}
]


static func theme(index: int) -> StringName:
	if index < 5:
		return [&"forest", &"mill", &"canopy", &"cavern", &"ridge"][maxi(index, 0)]
	if index < 10:
		return &"river"
	return &"frost" if index < 15 else &"ancient"


static func has_boss(index: int) -> bool:
	return index >= 0 and index < TITLES.size() and (index + 1) % 3 == 0


static func guardian(index: int) -> Dictionary:
	return GUARDIANS[index / 3] if has_boss(index) else {}


static func layout(index: int) -> Dictionary:
	if index >= 5 and index < TITLES.size():
		var data := ForestTrails.layout(index, TITLES[index])
		if has_boss(index):
			# Extend the existing last bank; keep every obstacle and reward before the fight.
			data.width = 4100.0
			data.ground[-1] = Vector2(2700, data.width)
			data.gate = Vector2(3940, 536)
			data.camps.append(Vector2(3060, 536))
			data.signs.append(
				[
					Vector2(2960, 315),
					guardian(index).name,
					"Dodge the leap. Attack when the cap turns gold."
				]
			)
		return data
	match index:
		1:
			return _mill()
		2:
			return _canopy()
		3:
			return _caverns()
		4:
			return _ridge()
	push_error("Unknown chapter layout: %d" % index)
	return {}


static func route(index: int) -> Array:
	if index >= 5 and index < TITLES.size():
		return layout(index).route
	if index == 3:
		return [
			["walk", 300.0, 536.0],
			["jump", 500.0, 536.0],
			["jump", 610.0, 416.0],
			["jump", 785.0, 360.0],
			["moving", 940.0, 455.0],
			["jump", 1230.0, 536.0],
			["walk", 1280.0, 536.0],
			["jump", 1510.0, 410.0],
			["jump", 1680.0, 320.0],
			["jump", 1875.0, 390.0],
			["jump", 2050.0, 440.0],
			["jump", 2180.0, 536.0],
			["walk", 2250.0, 536.0],
			["jump", 2400.0, 536.0],
			["jump", 2615.0, 390.0],
			["moving", 2700.0, 450.0],
			["jump", 2980.0, 536.0],
			["walk", 3030.0, 536.0],
			["jump", 3240.0, 536.0],
			["walk", 3290.0, 536.0]
		]
	if index == 4:
		return [
			["walk", 240.0, 536.0],
			["jump", 450.0, 536.0],
			["jump", 605.0, 430.0],
			["jump", 825.0, 360.0],
			["moving", 890.0, 455.0],
			["jump", 1080.0, 536.0],
			["jump", 1325.0, 400.0],
			["jump", 1550.0, 450.0],
			["moving", 1680.0, 405.0],
			["jump", 1970.0, 536.0],
			["walk", 2040.0, 536.0],
			["jump", 2230.0, 536.0],
			["jump", 2365.0, 400.0],
			["jump", 2555.0, 310.0],
			["jump", 2715.0, 415.0],
			["jump", 2840.0, 536.0],
			["walk", 2860.0, 536.0],
			["walk", 3020.0, 536.0],
			["jump", 3240.0, 536.0],
			["jump", 3410.0, 536.0],
			["walk", 3450.0, 536.0]
		]
	if index == 1:
		return [
			["walk", 270.0, 536.0],
			["jump", 420.0, 536.0],
			["jump", 530.0, 430.0],
			["jump", 750.0, 470.0],
			["moving", 860.0, 430.0],
			["jump", 1190.0, 536.0],
			["jump", 1350.0, 390.0],
			["jump", 1540.0, 335.0],
			["jump", 1700.0, 480.0],
			["jump", 1860.0, 440.0],
			["jump", 2100.0, 536.0],
			["jump", 2300.0, 385.0],
			["jump", 2460.0, 536.0],
			["moving", 2620.0, 470.0],
			["jump", 2930.0, 536.0],
			["jump", 3160.0, 536.0],
			["jump", 3380.0, 536.0],
			["walk", 3420.0, 536.0]
		]
	if index != 2:
		push_error("Unknown chapter route: %d" % index)
		return []
	return [
		["walk", 250.0, 536.0],
		["jump", 450.0, 536.0],
		["jump", 650.0, 455.0],
		["jump", 830.0, 390.0],
		["jump", 1020.0, 455.0],
		["jump", 1160.0, 536.0],
		["jump", 1380.0, 536.0],
		["jump", 1500.0, 460.0],
		["jump", 1670.0, 390.0],
		["jump", 1840.0, 335.0],
		["jump", 2030.0, 536.0],
		["jump", 2220.0, 440.0],
		["jump", 2300.0, 385.0],
		["jump", 2520.0, 536.0],
		["walk", 2630.0, 536.0]
	]


static func _mill() -> Dictionary:
	return {
		"title": TITLES[1],
		"width": 3600.0,
		"gate": Vector2(3420, 536),
		"gate_label": "Up to the canopy",
		"ground": [Vector2(0, 620), Vector2(1150, 1580), Vector2(2060, 2510), Vector2(2880, 3600)],
		"ledges":
		[
			Rect2(470, 430, 130, 28),
			Rect2(690, 470, 120, 28),
			Rect2(1290, 390, 130, 28),
			Rect2(1490, 335, 110, 28),
			Rect2(1960, 480, 100, 28),
			Rect2(2240, 385, 140, 28)
		],
		"moving":
		[[Rect2(860, 430, 140, 28), Vector2(0, 45)], [Rect2(2620, 470, 140, 28), Vector2(65, 20)]],
		"crumble": [Rect2(1650, 480, 110, 28), Rect2(1810, 440, 110, 28)],
		"spikes": [Vector2(320, 60), Vector2(3000, 90)],
		"acorns": [Vector2(530, 394), Vector2(1350, 354), Vector2(2300, 349)],
		"camps": [Vector2(140, 536), Vector2(1190, 536), Vector2(2100, 536), Vector2(2930, 536)],
		"mushrooms": [],
		"secret": Vector2(1540, 302),
		"critters": [{"home": Vector2(3240, 536), "range": 60.0, "speed": 1.3, "out": false}],
		"gems":
		[
			Vector2(250, 490),
			Vector2(350, 426),
			Vector2(570, 395),
			Vector2(750, 434),
			Vector2(930, 358),
			Vector2(1080, 434),
			Vector2(1190, 490),
			Vector2(1320, 354),
			Vector2(1540, 298),
			Vector2(1700, 444),
			Vector2(1860, 404),
			Vector2(2010, 444),
			Vector2(2100, 490),
			Vector2(2340, 349),
			Vector2(2690, 400),
			Vector2(2930, 490),
			Vector2(3040, 426),
			Vector2(3390, 490)
		],
		"signs":
		[
			[Vector2(190, 385), "Flooded Mill", "Use the old beams to cross the millpond."],
			[Vector2(640, 340), "The sluice lift", "Blue beams rise and fall with the water."],
			[Vector2(1600, 300), "Rotten timber", "Keep moving across the cracked beams."],
			[Vector2(2830, 385), "The far bank", "One more fence, then the canopy trail."]
		]
	}


static func _canopy() -> Dictionary:
	return {
		"title": TITLES[2],
		"width": 3600.0,
		"gate": Vector2(3450, 536),
		"gate_label": "Into the caverns",
		"ground": [Vector2(0, 500), Vector2(1080, 1410), Vector2(1970, 2440), Vector2(2500, 3600)],
		"ledges":
		[
			Rect2(590, 455, 120, 28),
			Rect2(780, 390, 130, 28),
			Rect2(970, 455, 120, 28),
			Rect2(1620, 390, 120, 28),
			Rect2(1790, 335, 120, 28),
			Rect2(2180, 440, 110, 28),
			Rect2(2240, 385, 140, 28),
			Rect2(2580, 430, 110, 28),
			Rect2(3330, 430, 110, 28)
		],
		"moving": [],
		"crumble": [Rect2(1450, 460, 110, 28)],
		"spikes": [Vector2(315, 60), Vector2(1270, 60), Vector2(2370, 50)],
		"acorns": [Vector2(830, 354), Vector2(1840, 299), Vector2(2300, 349)],
		"camps": [Vector2(140, 536), Vector2(1160, 536), Vector2(2030, 536), Vector2(2630, 536)],
		"mushrooms": [],
		"secret": Vector2(1840, 260),
		"critters": [{"home": Vector2(2140, 536), "range": 35.0, "speed": 1.4, "out": false}],
		"gems":
		[
			Vector2(240, 490),
			Vector2(345, 426),
			Vector2(650, 419),
			Vector2(870, 354),
			Vector2(1020, 419),
			Vector2(1160, 490),
			Vector2(1300, 426),
			Vector2(1500, 424),
			Vector2(1670, 354),
			Vector2(1800, 299),
			Vector2(1900, 420),
			Vector2(2030, 490),
			Vector2(2220, 404),
			Vector2(2340, 349),
			Vector2(2480, 440),
			Vector2(2635, 394),
			Vector2(3265, 394),
			Vector2(3465, 490)
		],
		"signs":
		[
			[
				Vector2(170, 370),
				"Above the treetops",
				"Three acorns are hidden along these branches."
			],
			[Vector2(1450, 290), "Watch your footing", "The first branch is ready to break."],
			[
				Vector2(2470, 340),
				"OLD CROAK'S HOLLOW",
				"Jump over the ripples. Watch for his golden cap."
			]
		]
	}


static func _caverns() -> Dictionary:
	return {
		"title": TITLES[3],
		"width": 3420.0,
		"gate": Vector2(3290, 536),
		"gate_label": "The daylight passage",
		"ground": [Vector2(0, 760), Vector2(1190, 1710), Vector2(2100, 2620), Vector2(2910, 3420)],
		"ledges":
		[
			Rect2(540, 416, 140, 28),
			Rect2(730, 360, 110, 28),
			Rect2(1450, 410, 140, 28),
			Rect2(1630, 320, 110, 28),
			Rect2(2000, 440, 100, 28),
			Rect2(2550, 390, 130, 28)
		],
		"moving":
		[[Rect2(940, 455, 130, 28), Vector2(45, 0)], [Rect2(2700, 450, 140, 28), Vector2(0, 45)]],
		"crumble": [Rect2(1820, 390, 110, 28)],
		"spikes": [Vector2(360, 60), Vector2(2320, 60)],
		"acorns": [Vector2(610, 380), Vector2(1510, 374), Vector2(2615, 354)],
		"camps": [Vector2(140, 536), Vector2(1280, 536), Vector2(2180, 536), Vector2(3030, 536)],
		"mushrooms": [],
		"secret": Vector2(1680, 284),
		"critters":
		[
			{"home": Vector2(1390, 536), "range": 15.0, "speed": 1.3, "out": false},
			{"home": Vector2(1440, 536), "range": 15.0, "speed": 1.1, "out": false},
			{"home": Vector2(3140, 536), "range": 30.0, "speed": 1.5, "out": false}
		],
		"gems":
		[
			Vector2(265, 490),
			Vector2(390, 426),
			Vector2(610, 375),
			Vector2(785, 324),
			Vector2(960, 410),
			Vector2(1120, 450),
			Vector2(1280, 490),
			Vector2(1510, 370),
			Vector2(1680, 280),
			Vector2(1875, 354),
			Vector2(2050, 404),
			Vector2(2180, 490),
			Vector2(2350, 426),
			Vector2(2615, 350),
			Vector2(2770, 380),
			Vector2(2980, 490),
			Vector2(3160, 420),
			Vector2(3290, 490)
		],
		"signs":
		[
			[Vector2(165, 375), "Moss Caverns", "Follow the roots toward daylight."],
			[Vector2(1180, 300), "Seed bombs", "J lobs a seed. Its burst catches nearby critters."],
			[Vector2(1740, 245), "Loose stone", "This crossing crumbles under your paws."],
			[Vector2(2920, 375), "Fresh air", "The ridge is just beyond this passage."]
		]
	}


static func _ridge() -> Dictionary:
	return {
		"title": TITLES[4],
		"width": 3600.0,
		"gate": Vector2(3450, 536),
		"gate_label": "Down to the river",
		"ground": [Vector2(0, 610), Vector2(1000, 1450), Vector2(1910, 2410), Vector2(2780, 3600)],
		"ledges":
		[
			Rect2(540, 430, 130, 28),
			Rect2(760, 360, 130, 28),
			Rect2(1260, 400, 130, 28),
			Rect2(2300, 400, 130, 28),
			Rect2(2500, 310, 110, 28)
		],
		"moving":
		[[Rect2(890, 455, 130, 28), Vector2(0, 35)], [Rect2(1680, 405, 130, 28), Vector2(40, 0)]],
		"crumble": [Rect2(1500, 450, 100, 28), Rect2(2660, 415, 110, 28)],
		"spikes": [Vector2(290, 60), Vector2(2090, 60), Vector2(3070, 90)],
		"acorns": [Vector2(605, 394), Vector2(1325, 364), Vector2(2365, 364)],
		"camps": [Vector2(140, 536), Vector2(1080, 536), Vector2(1970, 536), Vector2(2860, 536)],
		"mushrooms": [],
		"secret": Vector2(2555, 274),
		"critters":
		[
			{"home": Vector2(1190, 536), "range": 25.0, "speed": 1.6, "out": false},
			{"home": Vector2(3310, 536), "range": 25.0, "speed": 1.8, "out": false}
		],
		"gems":
		[
			Vector2(220, 490),
			Vector2(320, 426),
			Vector2(605, 390),
			Vector2(825, 324),
			Vector2(955, 400),
			Vector2(1080, 490),
			Vector2(1325, 360),
			Vector2(1550, 414),
			Vector2(1745, 360),
			Vector2(1970, 490),
			Vector2(2120, 426),
			Vector2(2365, 360),
			Vector2(2555, 270),
			Vector2(2715, 379),
			Vector2(2860, 490),
			Vector2(3115, 426),
			Vector2(3310, 420),
			Vector2(3450, 490)
		],
		"signs":
		[
			[Vector2(160, 375), "Sunlit Ridge", "Cross the stone shelves to the summit."],
			[
				Vector2(1010, 290),
				"Ironwood armor",
				"Three blocks when fresh. Change gear with Esc."
			],
			[Vector2(2400, 230), "A high roost", "A firefly is hiding above the last crossing."],
			[
				Vector2(2850, 365),
				"The river beyond",
				"Watch the thorns. Follow the pass down to the river."
			]
		]
	}
