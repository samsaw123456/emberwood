class_name ForestChapters
extends RefCounted
## Hand-built routes. Coordinates use the same feet-based scale as the fox.

const TITLES := ["Emberwood", "Flooded Mill", "High Canopy"]


static func layout(index: int) -> Dictionary:
	if index == 1:
		return _mill()
	return _canopy()


static func route(index: int) -> Array:
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
		"gate_label": "The hollow tree",
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
