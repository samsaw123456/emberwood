class_name ForestCritters
extends RefCounted
## Ordinary enemies share movement, artwork and contact geometry with every weapon.

const OPOSSUM := preload("res://assets/pixel/animals/sunnyland/opossum-run-sheet.png")
const KINDS := [&"opossum", &"slime", &"beetle", &"bat"]
const TYPES := {
	&"opossum": {"name": "Opossum", "size": Vector2(50, 29), "pace": 1.0},
	&"slime": {"name": "Moss slime", "size": Vector2(42, 27), "pace": 0.75},
	&"beetle": {"name": "Bramble beetle", "size": Vector2(44, 27), "pace": 1.25},
	&"bat": {"name": "Cave bat", "size": Vector2(36, 24), "pace": 0.9}
}
const PIXELS := {
	&"slime":
	[
		"......gg......",
		"....ggllgg....",
		"...gllllllg...",
		"..gllllllllg..",
		".gllwwllwwllg.",
		".gllwkllkwllg.",
		"gllllllllllllg",
		"gllllkkkkllllg",
		".ggllllllllgg.",
		"...gggggggg..."
	],
	&"beetle":
	[
		"..d..........d..",
		"...d..dddd..d...",
		"....ddrrrrdd....",
		"..drrrllrrrrrd..",
		".drrrllrdrrrrrd.",
		"ddrrrrrrdrrrrrdd",
		".drrrrrrdrrrrrd.",
		"..drrrwwwwwrrd..",
		".d..ddwkwkdd..d.",
		"d.....dddd.....d"
	],
	&"bat":
	[
		"d......d....d......d",
		"dd.....dddddd.....dd",
		"dld....dlllld....dld",
		"dllld..dlwwld..dllld",
		"dlllllddlkklddllllld",
		".ddllllllrrlllllldd.",
		"...ddlllllllllldd...",
		".....dddllllddd.....",
		".......dddddd......."
	]
}
const PALETTES := {
	&"slime": {"g": "315940", "l": "8cbc59", "w": "edf2c1", "k": "243c32"},
	&"beetle": {"d": "422f35", "r": "b46c3d", "l": "dfb165", "w": "f5ddac", "k": "272d35"},
	&"bat": {"d": "382c49", "l": "8b6e9f", "r": "c292c1", "w": "f8dc92", "k": "2b293e"}
}


static func kind(critter: Dictionary) -> StringName:
	return critter.get("kind", &"opossum")


static func position(critter: Dictionary, age: float) -> Vector2:
	var species := kind(critter)
	var phase: float = age * critter.speed * TYPES[species].pace
	var height := 0.0
	if species == &"slime":
		height = maxf(0, sin(phase * 2)) * 22
	elif species == &"bat":
		height = 38 + sin(phase * 1.7) * 10
	return critter.home + Vector2(sin(phase) * critter.range, -height)


static func bounds(critter: Dictionary, age: float) -> Rect2:
	var size: Vector2 = TYPES[kind(critter)].size
	return Rect2(position(critter, age) - Vector2(size.x / 2, size.y), size)


static func draw_critter(canvas: Node2D, critter: Dictionary, age: float, gentle: bool) -> void:
	var species := kind(critter)
	var facing := -1.0 if cos(age * critter.speed * TYPES[species].pace) > 0 else 1.0
	canvas.draw_set_transform(position(critter, age), 0, Vector2(facing, 1))
	if species == &"opossum":
		var frame := 0 if gentle else int(age * 10) % 6
		canvas.draw_texture_rect_region(
			OPOSSUM, Rect2(-36, -50, 72, 56), Rect2(frame * 36, 0, 36, 28)
		)
	else:
		_draw_pixels(canvas, species, age, gentle)
	canvas.draw_set_transform(Vector2.ZERO)


static func _draw_pixels(canvas: Node2D, species: StringName, age: float, gentle: bool) -> void:
	var rows: Array = PIXELS[species]
	var palette: Dictionary = PALETTES[species]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ink := row.substr(x, 1)
			if ink in [".", " "]:
				continue
			var wing := 0.0
			if species == &"bat" and (x < 7 or x > 12) and not gentle:
				wing = -3.0 if int(age * 8) % 2 == 0 else 0.0
			canvas.draw_rect(
				Rect2((x - row.length() / 2.0) * 3, (y - rows.size()) * 3 + wing, 3, 3),
				Color(palette[ink])
			)
