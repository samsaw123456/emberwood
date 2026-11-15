extends RefCounted
## Compact pixel silhouettes share the boss's body scale and gold-cap anchor.
## Original art; SunnyLand supplies the animated opossum and eagle.

const OPOSSUM := preload("res://assets/pixel/animals/sunnyland/opossum-run-sheet.png")
const EAGLE := preload("res://assets/pixel/animals/sunnyland/eagle-fly-sheet.png")
const PIXELS := {
	&"boar":
	[
		".....dd..........dd.....",
		"....drrd..dddd..drrd....",
		"....drrrddrrrrddrrrd....",
		".....drrrrrrrrrrrrd.....",
		"....drrrrrrrrrrrrrrd....",
		"...drrrrrrrrrrrrrrrrd...",
		"...drrrllrrrrrrllrrrd...",
		"..drrrlwwlrrrrlwwlrrrd..",
		"..drrrlwklrrrrlkwlrrrd..",
		"..drrrrllrrrrrrllrrrrd..",
		"..drrrrrrrrrrrrrrrrrrd..",
		"..dwrrrppppppppprrrwd..",
		"..dwwrrppkpppkpprrwwd..",
		"...dwwrppkpppkpprwwd...",
		"....dwwpppppppppwwd....",
		"....drrrrrrrrrrrrrd....",
		".....drrrrrrrrrrrd.....",
		".....drrrd..drrrd......",
		".....drrrd..drrrd......",
		".....dddd....dddd......"
	],
	&"wolf":
	[
		"....dd............dd....",
		"...drrd..........drrd...",
		"...drrrd........drrrd...",
		"...drlrrddddddddrrlrd...",
		"....drlrrrrrrrrrlrd....",
		"....drrrrrrrrrrrrrd....",
		"...drrrllrrrrllrrrrd...",
		"..drrrlwwlrrlwwlrrrd..",
		"..drrrlwklrrlkwlrrrd..",
		"...drrrllrrrrllrrrd...",
		"..drrrllllkkllllrrrd..",
		"...drrllllkkllllrrd...",
		"....drllllllllllrd....",
		"...drrrllllllllrrrd...",
		"..drrrrrllllllrrrrrd..",
		"...drrrrrllllrrrrrd...",
		"....drrrrrllrrrrrd....",
		".....drrrd..drrrd.....",
		".....drrrd..drrrd.....",
		".....dllll..lllld....."
	],
	&"owl":
	[
		"....dd............dd....",
		"....drrd........drrd....",
		"....drrrddddddddrrrd....",
		"...drrrrrrrrrrrrrrrrd...",
		"..drrllllllllllllllrrd..",
		"..drlwwwwllllwwwwllrd..",
		"..drlwwkwwllwwkwwllrd..",
		"..drlwwkwwllwwkwwllrd..",
		"..drrlwwwlrrlwwwllrrd..",
		"...drrllllppllllrrrd...",
		"..drrrrlllpplllrrrrrd..",
		".drrrrrrllllllrrrrrrd.",
		".drrrdrrllllllrrdrrrd.",
		".drrrdrlrrllrrlrdrrrd.",
		"..drrdrlrrllrrlrdrrd..",
		"...ddrrlrrllrrlrrdd...",
		"....drrllllllllrrd....",
		".....drrrrrrrrrrd.....",
		"......drrrrrrrrd......",
		"......ppp..ppp........"
	]
}
const PALETTES := {
	&"boar": {"d": "352d2a", "r": "865d43", "l": "ad8364", "p": "c98b77"},
	&"wolf": {"d": "303c4c", "r": "788eaa", "l": "d3e0e8", "p": "a9bdcf"},
	&"owl": {"d": "44352e", "r": "946c3c", "l": "d6b478", "p": "e6ac4e"}
}


static func draw_animal(
	canvas: Node2D,
	species: StringName,
	age: float,
	phase: String,
	facing_left: bool,
	tint: Color,
	still: bool
) -> void:
	var direction := 1 if facing_left else -1
	var squash := Vector2(1.04, 0.94) if phase == "warning" else Vector2.ONE
	canvas.draw_set_transform(Vector2.ZERO, 0, squash * Vector2(direction, 1))
	if species == &"opossum":
		var frame := 0 if still or phase != "leap" else int(age * 8) % 6
		canvas.draw_texture_rect_region(
			OPOSSUM, Rect2(-66, -94, 132, 100), Rect2(frame * 36, 0, 36, 28), tint
		)
	elif species == &"eagle":
		var frame := 0 if still else int(age * 7) % 4
		canvas.draw_texture_rect_region(
			EAGLE, Rect2(-60, -104, 120, 112), Rect2(frame * 40, 0, 40, 41), tint
		)
	else:
		var rows: Array = PIXELS[species]
		var palette: Dictionary = PALETTES[species].duplicate()
		palette["w"] = "ffe6a8" if species == &"owl" else "f4ead5"
		palette["k"] = "202c31"
		for y in rows.size():
			var row: String = rows[y]
			# Center each row independently; all body pixels stay within the hitbox margin.
			for x in row.length():
				var ink := row.substr(x, 1)
				if ink != ".":
					canvas.draw_rect(
						Rect2((x - row.length() / 2.0) * 4, y * 4 - 80, 4, 4),
						Color(palette[ink]) * tint
					)
	canvas.draw_set_transform(Vector2.ZERO)
