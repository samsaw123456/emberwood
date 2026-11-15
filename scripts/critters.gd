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
		match species:
			&"slime":
				_draw_slime(canvas, age, gentle)
			&"beetle":
				_draw_beetle(canvas, age, gentle)
			&"bat":
				_draw_bat(canvas, age, gentle)
	canvas.draw_set_transform(Vector2.ZERO)


static func _shape(canvas: Node2D, points: Array[Vector2], fill: Color, edge: Color) -> void:
	var polygon := PackedVector2Array(points)
	canvas.draw_colored_polygon(polygon, fill)
	polygon.append(polygon[0])
	canvas.draw_polyline(polygon, edge, 2.0)


static func _draw_slime(canvas: Node2D, age: float, gentle: bool) -> void:
	# A wide jelly dome, hanging drips and bright reflections read at small sizes.
	var wobble := 0.0 if gentle else roundf(sin(age * 5) * 2)
	var edge := Color("183c36")
	_shape(
		canvas,
		[
			Vector2(-25, -2),
			Vector2(-26, -12),
			Vector2(-22, -12),
			Vector2(-22, -23),
			Vector2(-16 + wobble, -23),
			Vector2(-16 + wobble, -30),
			Vector2(-7 + wobble, -30),
			Vector2(-7 + wobble, -35),
			Vector2(7 + wobble, -35),
			Vector2(7 + wobble, -32),
			Vector2(17, -32),
			Vector2(17, -27),
			Vector2(22, -27),
			Vector2(22, -17),
			Vector2(26, -17),
			Vector2(26, -7),
			Vector2(29, -7),
			Vector2(29, 0),
			Vector2(18, 0),
			Vector2(18, 3),
			Vector2(9, 3),
			Vector2(9, 0),
			Vector2(-5, 0),
			Vector2(-5, 3),
			Vector2(-19, 3),
			Vector2(-19, 0)
		],
		Color("88d662"),
		edge
	)
	canvas.draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-24, -9),
				Vector2(-15, -5),
				Vector2(10, -5),
				Vector2(25, -13),
				Vector2(25, -2),
				Vector2(15, -2),
				Vector2(15, 1),
				Vector2(11, 1),
				Vector2(11, -2),
				Vector2(-8, -2),
				Vector2(-8, 1),
				Vector2(-17, 1),
				Vector2(-17, -2),
				Vector2(-23, -2)
			]
		),
		Color("399274")
	)
	canvas.draw_rect(Rect2(-14 + wobble, -29, 8, 3), Color("e5ffc4"))
	canvas.draw_rect(Rect2(-18 + wobble, -25, 4, 6), Color("c5f49c"))
	canvas.draw_rect(Rect2(13, -13, 4, 4), Color("b2ef8e"))
	canvas.draw_rect(Rect2(-20, -9, 3, 3), Color("b2ef8e"))
	for x in [-10, 7]:
		canvas.draw_rect(Rect2(x - 2, -22, 9, 12), edge)
		canvas.draw_rect(Rect2(x - 1, -22, 7, 8), Color("f3ffe2"))
		canvas.draw_rect(Rect2(x, -18, 4, 6), Color("18343b"))
	canvas.draw_line(Vector2(-2, -8), Vector2(4, -8), edge, 2)
	canvas.draw_rect(Rect2(-1, -6, 5, 2), Color("c5f49c"))


static func _draw_beetle(canvas: Node2D, age: float, gentle: bool) -> void:
	var edge := Color("302936")
	# Three pairs of jointed legs move independently of the armored body.
	for leg in 3:
		var x := -12.0 + leg * 13
		var step := 0.0 if gentle else roundf(sin(age * 13 + leg * PI) * 3)
		canvas.draw_polyline(
			PackedVector2Array([Vector2(x, -12), Vector2(x + 8, -5), Vector2(x + 13 - step, 0)]),
			Color("6b4650"),
			3
		)
	_shape(
		canvas,
		[
			Vector2(-16, -11),
			Vector2(-17, -23),
			Vector2(-10, -31),
			Vector2(1, -35),
			Vector2(16, -32),
			Vector2(24, -25),
			Vector2(27, -14),
			Vector2(20, -7),
			Vector2(-7, -7)
		],
		Color("c66c38"),
		edge
	)
	canvas.draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(8, -32),
				Vector2(20, -26),
				Vector2(24, -15),
				Vector2(17, -10),
				Vector2(7, -10),
				Vector2(3, -28)
			]
		),
		Color("904347")
	)
	canvas.draw_polyline(
		PackedVector2Array([Vector2(-12, -23), Vector2(-7, -29), Vector2(0, -31), Vector2(8, -30)]),
		Color("ffce7b"),
		3
	)
	canvas.draw_line(Vector2(1, -32), Vector2(6, -10), edge, 2)
	for y in [-24, -18]:
		canvas.draw_line(Vector2(10, y), Vector2(18, y + 2), Color("e9a35e"), 2)
	_shape(
		canvas,
		[
			Vector2(-26, -23),
			Vector2(-15, -22),
			Vector2(-11, -15),
			Vector2(-15, -7),
			Vector2(-27, -7),
			Vector2(-31, -13)
		],
		Color("6f4650"),
		edge
	)
	for offset in [0, 8]:
		canvas.draw_polyline(
			PackedVector2Array(
				[Vector2(-23 + offset, -22), Vector2(-29 + offset, -31), Vector2(-36 + offset, -33)]
			),
			edge,
			3
		)
		canvas.draw_rect(Rect2(-38 + offset, -35, 4, 4), Color("ffd085"))
	canvas.draw_rect(Rect2(-27, -19, 7, 6), Color("fff1cb"))
	canvas.draw_rect(Rect2(-27, -18, 3, 4), edge)
	canvas.draw_line(Vector2(-28, -10), Vector2(-34, -6), Color("edbe83"), 3)
	for leg in 3:
		var x := -13.0 + leg * 13
		var step := 0.0 if gentle else roundf(sin(age * 13 + leg * PI) * 3)
		canvas.draw_polyline(
			PackedVector2Array(
				[
					Vector2(x, -11),
					Vector2(x - 4, -4),
					Vector2(x - 8 + step, 1),
					Vector2(x - 12 + step, 1)
				]
			),
			edge,
			3
		)
		canvas.draw_line(Vector2(x - 4, -4), Vector2(x - 8 + step, 0), Color("d99564"), 2)


static func _draw_bat(canvas: Node2D, age: float, gentle: bool) -> void:
	var edge := Color("302b43")
	var flap := 0.45 if gentle else (sin(age * 11) + 1) * 0.5
	var wing_tip := Vector2(45, roundf(lerpf(-39, -5, flap)))
	for side in [-1, 1]:
		var points: Array[Vector2] = [
			Vector2(10, -20),
			Vector2(24, roundf(lerpf(-30, -17, flap))),
			wing_tip,
			Vector2(38, roundf(lerpf(-15, 7, flap))),
			Vector2(31, roundf(lerpf(-20, -2, flap))),
			Vector2(26, roundf(lerpf(-5, 5, flap))),
			Vector2(21, -10),
			Vector2(15, -3),
			Vector2(10, -8)
		]
		for index in points.size():
			points[index].x *= side
		_shape(canvas, points, Color("a58ed4"), edge)
		for finger in [3, 5, 7]:
			canvas.draw_line(Vector2(side * 12, -20), points[finger], Color("6d508f"), 2)
		canvas.draw_line(Vector2(side * 12, -21), wing_tip * Vector2(side, 1), Color("d9b9ec"), 2)
		_shape(
			canvas,
			[Vector2(side * 3, -23), Vector2(side * 15, -41), Vector2(side * 13, -20)],
			Color("79628f"),
			edge
		)
		canvas.draw_line(Vector2(side * 8, -24), Vector2(side * 12, -33), Color("ebaebf"), 3)
	_shape(
		canvas,
		[
			Vector2(-12, -26),
			Vector2(12, -26),
			Vector2(15, -20),
			Vector2(13, -6),
			Vector2(7, 0),
			Vector2(-7, 0),
			Vector2(-13, -6),
			Vector2(-15, -20)
		],
		Color("695479"),
		edge
	)
	canvas.draw_rect(Rect2(-9, -23, 18, 4), Color("9376a3"))
	for x in [-9, 3]:
		canvas.draw_rect(Rect2(x, -19, 7, 7), Color("ffe8a5"))
		canvas.draw_rect(Rect2(x + 2, -18, 3, 5), edge)
	canvas.draw_rect(Rect2(-3, -11, 6, 3), Color("d69bad"))
	canvas.draw_line(Vector2(-6, -7), Vector2(6, -7), edge, 2)
	for x in [-5, 3]:
		canvas.draw_rect(Rect2(x, -7, 2, 4), Color("fff0d7"))
