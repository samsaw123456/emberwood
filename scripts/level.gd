class_name ForestLevel
extends Node2D

const WORLD_WIDTH := 6520.0
const FLOOR_Y := 536.0
const ROUTE_FONT := preload("res://assets/fonts/DejaVuSans.ttf")
const GEM := preload("res://assets/pixel/items/sunnyland/gem-sparkle-sheet.png")
const SPIKES := preload("res://assets/pixel/hazards/sunnyland/spikes.png")
const OPOSSUM := preload("res://assets/pixel/animals/sunnyland/opossum-run-sheet.png")
const TREE := preload("res://assets/pixel/nature/sunnyland/tree.png")
const PINE := preload("res://assets/pixel/nature/sunnyland/pine.png")
const BUSH := preload("res://assets/pixel/nature/sunnyland/bush.png")
const SHROOM := preload("res://assets/pixel/nature/sunnyland/shrooms.png")
const ROCK := preload("res://assets/pixel/nature/sunnyland/rock-2.png")

var stage_index := 0
var world_width := WORLD_WIDTH
var title := "Emberwood"
var required_acorns := 3
var gate_label := "The forest gate"
var gate_open := true

var platforms: Array[ForestPlatform] = []
var spikes: Array[Rect2] = []
var gems: Array[Vector2] = []
var taken_gems: Dictionary = {}
var acorns: Array[Vector2] = [Vector2(1610, 356), Vector2(3660, 346), Vector2(5650, 326)]
var taken_acorns: Dictionary = {}
var camps: Array[Vector2] = [
	Vector2(140, 536), Vector2(1840, 536), Vector2(3870, 536), Vector2(4950, 536)
]
var camp_index := 0
var mushrooms: Array[Vector2] = [Vector2(4770, 536)]
var critters: Array[Dictionary] = []
var signs: Array[Dictionary] = []
var decorations: Array[Dictionary] = []
var active := false
var reduced_motion := false
var age := 0.0
var camera_x := 0.0
var gate := Vector2(6280, 536)
var secret := Vector2(2870, 292)
var secret_found := false
var _water_spans: Array[Vector2] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if stage_index > 0:
		_build_chapter()
		_build_decorations()
		return
	_build_terrain()
	_build_pickups()
	_build_decorations()
	add_sign(315, 440, "Space to jump", "Press again for a double jump")
	add_sign(985, 420, "Mind the gap!", "Hold jump to go higher")
	add_sign(1945, 404, "Bramble Crossing", "Blue platforms carry you")
	add_sign(3000, 400, "Keep moving", "Cracked bridges crumble")
	add_sign(4050, 420, "Moonlit Grove", "The last acorn is up ahead")
	add_sign(4660, 410, "Boing!", "Pink mushrooms bounce you")
	add_sign(670, 370, "A quick dash", "Shift dashes in the direction you face.")
	critters = [
		{"home": Vector2(1370, 536), "range": 90.0, "speed": 1.5, "out": false},
		{"home": Vector2(2670, 536), "range": 100.0, "speed": 1.7, "out": false},
		{"home": Vector2(4680, 536), "range": 65.0, "speed": 1.6, "out": false},
		{"home": Vector2(5850, 536), "range": 90.0, "speed": 1.9, "out": false},
	]


func _build_chapter() -> void:
	var data := ForestChapters.layout(stage_index)
	title = data.title
	world_width = data.width
	gate = data.gate
	gate_label = data.gate_label
	acorns.assign(data.acorns)
	camps.assign(data.camps)
	mushrooms.assign(data.mushrooms)
	gems.assign(data.gems)
	critters.assign(data.critters)
	secret = data.secret
	var bank_end := 0.0
	for span: Vector2 in data.ground:
		if span.x > bank_end:
			_water_spans.append(Vector2(bank_end, span.x))
		add_platform(Rect2(span.x, FLOOR_Y, span.y - span.x, 180))
		bank_end = span.y
	for rect: Rect2 in data.ledges:
		add_platform(rect, "ledge")
	for entry: Array in data.moving:
		add_platform(entry[0], "moving", entry[1])
	for rect: Rect2 in data.crumble:
		add_platform(rect, "crumble")
	for patch: Vector2 in data.spikes:
		spikes.append(Rect2(patch.x, FLOOR_Y - 20, patch.y, 20))
	for sign: Array in data.signs:
		add_sign(sign[0].x, sign[0].y, sign[1], sign[2])
	add_platform(Rect2(-40, -300, 40, 1050), "wall")
	add_platform(Rect2(world_width, -300, 40, 1050), "wall")


func zone_title(x: float) -> String:
	if stage_index == 1:
		return "The Millpond" if x < 1580 else "The Broken Race"
	if stage_index == 2:
		return "Branch Walk" if x < 2500 else "Old Croak's Hollow"
	if stage_index == 3:
		return "Root Galleries" if x < 1720 else "Daylight Passage"
	if stage_index == 4:
		return "Stone Shelves" if x < 1900 else "Summit Approach"
	if x >= 3950:
		return "Moonlit Grove"
	return "Bramble Crossing" if x >= 1900 else "Mossy Trail"


func _build_terrain() -> void:
	for span in [
		Vector2(0, 1060),
		Vector2(1230, 1980),
		Vector2(2320, 3060),
		Vector2(3400, 4100),
		Vector2(4520, 5200),
		Vector2(5520, 6520)
	]:
		add_platform(Rect2(span.x, FLOOR_Y, span.y - span.x, 180))
	# Short ledges teach double jumping before the first required acorn.
	for rect in [
		Rect2(710, 436, 130, 28),
		Rect2(930, 356, 100, 28),
		Rect2(1500, 436, 100, 28),
		Rect2(1580, 386, 130, 28),
		Rect2(2490, 440, 120, 28),
		Rect2(2710, 350, 100, 28),
		Rect2(2830, 322, 120, 28),
		Rect2(3530, 440, 110, 28),
		Rect2(3610, 376, 130, 28),
		Rect2(4210, 470, 100, 28),
		Rect2(4370, 410, 100, 28),
		Rect2(4840, 350, 140, 28),
		Rect2(5540, 440, 100, 28),
		Rect2(5600, 356, 140, 28)
	]:
		add_platform(rect, "ledge")
	add_platform(Rect2(2110, 475, 132, 28), "moving", Vector2(104, 0))
	add_platform(Rect2(3130, 480, 94, 28), "crumble")
	add_platform(Rect2(3260, 450, 94, 28), "crumble")
	add_platform(Rect2(5300, 450, 124, 28), "moving", Vector2(80, 45))
	for patch in [
		Vector2(510, 90),
		Vector2(850, 90),
		Vector2(1720, 60),
		Vector2(2400, 60),
		Vector2(2910, 90),
		Vector2(3740, 60),
		Vector2(3980, 60),
		Vector2(5050, 90),
		Vector2(5970, 120)
	]:
		spikes.append(Rect2(patch.x, FLOOR_Y - 20, patch.y, 20))
	add_platform(Rect2(-40, -300, 40, 1050), "wall")
	add_platform(Rect2(WORLD_WIDTH, -300, 40, 1050), "wall")


func add_platform(rect: Rect2, kind: String = "ground", motion := Vector2.ZERO) -> void:
	var platform := ForestPlatform.new()
	platform.setup(rect, kind, motion)
	if kind == "wall":
		platform.visible = false
	if stage_index == 1:
		platform.modulate = Color("c7c4af")
	elif stage_index == 2:
		platform.modulate = Color("c0cda7")
	elif stage_index == 3:
		platform.modulate = Color("a4b8a1")
	elif stage_index == 4:
		platform.modulate = Color("dbc99b")
	add_child(platform)
	platforms.append(platform)


func _build_pickups() -> void:
	for point in [
		Vector2(360, 492),
		Vector2(520, 440),
		Vector2(565, 412),
		Vector2(610, 440),
		Vector2(760, 400),
		Vector2(975, 320),
		Vector2(1110, 430),
		Vector2(1170, 430),
		Vector2(1300, 492),
		Vector2(1530, 398),
		Vector2(1660, 347),
		Vector2(1840, 490),
		Vector2(2040, 420),
		Vector2(2150, 415),
		Vector2(2270, 420),
		Vector2(2525, 402),
		Vector2(2750, 312),
		Vector2(2910, 284),
		Vector2(3180, 442),
		Vector2(3300, 410),
		Vector2(3460, 492),
		Vector2(3570, 402),
		Vector2(3700, 338),
		Vector2(3900, 492),
		Vector2(4250, 432),
		Vector2(4410, 372),
		Vector2(4600, 492),
		Vector2(4890, 312),
		Vector2(5110, 425),
		Vector2(5350, 390),
		Vector2(5580, 402),
		Vector2(5700, 318),
		Vector2(5900, 492),
		Vector2(6010, 420),
		Vector2(6070, 420),
		Vector2(6150, 492)
	]:
		gems.append(point)


func _build_decorations() -> void:
	for platform in platforms:
		if platform.kind != "ground":
			continue
		var x := platform.position.x + 55.0
		while x < platform.position.x + platform.size.x - 90:
			var index := int(x / 53) % 4
			decorations.append({"pos": Vector2(x, FLOOR_Y), "kind": index})
			x += 170 + int(x) % 110


func add_sign(x: float, y: float, title: String, hint: String) -> void:
	signs.append({"pos": Vector2(x, y), "title": title, "hint": hint})


func set_active(value: bool) -> void:
	active = value
	for platform in platforms:
		platform.active = value


func reset_run() -> void:
	taken_gems.clear()
	taken_acorns.clear()
	camp_index = 0
	secret_found = false
	reset_hazards()


func reset_hazards() -> void:
	age = 0.0
	for critter in critters:
		critter.out = false
	for platform in platforms:
		platform.reset_bridge()
		platform.age = 0.0


func critter_position(critter: Dictionary) -> Vector2:
	return critter.home + Vector2(sin(age * critter.speed) * critter.range, 0)


func critter_bounds(critter: Dictionary) -> Rect2:
	return Rect2(critter_position(critter) - Vector2(25, 29), Vector2(50, 29))


func _physics_process(delta: float) -> void:
	if active:
		age += delta
	queue_redraw()


func _draw() -> void:
	if stage_index == 1:
		_draw_millpond()
	_draw_decorations()
	_draw_spikes()
	_draw_collectibles()
	_draw_camps()
	_draw_critters()
	_draw_gate()
	for pos in mushrooms:
		draw_texture_rect(SHROOM, Rect2(pos - Vector2(34, 42), Vector2(68, 42)), false)
		draw_arc(pos - Vector2(0, 28), 40, PI * 1.12, PI * 1.88, 16, Color(1, 0.7, 0.7, 0.32), 2)
	for sign in signs:
		if absf(sign.pos.x - camera_x - 576) < 750:
			_draw_sign(sign)


func _draw_decorations() -> void:
	for decor in decorations:
		var point: Vector2 = decor.pos
		if absf(point.x - camera_x - 576) > 850:
			continue
		if stage_index == 3:
			_draw_cavern_growth(point, decor.kind)
			continue
		if stage_index == 4 and decor.kind == 0:
			draw_texture_rect(
				PINE, Rect2(point - Vector2(75, 250), Vector2(150, 250)), false, Color("b2b78a")
			)
			continue
		match decor.kind:
			0:
				draw_texture_rect(
					TREE,
					Rect2(point - Vector2(119, 222), Vector2(238, 222)),
					false,
					Color("a2bdab")
				)
			1:
				draw_texture_rect(
					BUSH, Rect2(point - Vector2(46, 48), Vector2(92, 56)), false, Color("abc6a2")
				)
			2:
				draw_texture_rect(ROCK, Rect2(point - Vector2(46, 75), Vector2(92, 80)), false)
			3:
				draw_texture_rect(
					SHROOM, Rect2(point - Vector2(16, 24), Vector2(32, 30)), false, Color("a5a0ba")
				)


func _draw_spikes() -> void:
	for rect in spikes:
		for x in range(int(rect.position.x), int(rect.end.x), 30):
			draw_texture_rect(SPIKES, Rect2(x, rect.position.y, 30, 20), false)
		draw_rect(Rect2(rect.position.x, rect.end.y - 3, rect.size.x, 3), Color("e2987f"))


func _draw_collectibles() -> void:
	var frame := int(age * 8) % 5
	for index in gems.size():
		if taken_gems.has(index):
			continue
		var bob := 0.0 if reduced_motion else sin(age * 2.5 + index) * 4.0
		var pos := gems[index] + Vector2(0, bob)
		draw_circle(pos, 19, Color(0.57, 0.9, 0.9, 0.08))
		draw_texture_rect_region(
			GEM, Rect2(pos - Vector2(15, 13), Vector2(30, 26)), Rect2(frame * 15, 0, 15, 13)
		)
	for index in acorns.size():
		if taken_acorns.has(index):
			continue
		var pos := acorns[index]
		if not reduced_motion:
			pos.y += sin(age * 2.5) * 4.0
		draw_circle(pos, 27, Color(1, 0.76, 0.4, 0.12))
		draw_circle(pos, 20, Color(1, 0.76, 0.4, 0.12))
		draw_acorn(pos)
	if not secret_found:
		var pulse := 1.0 if reduced_motion else 0.85 + 0.15 * sin(age * 3)
		draw_circle(secret, 20 * pulse, Color(1, 0.9, 0.5, 0.18))
		draw_circle(secret, 6, Color("fff5a5"))
		draw_circle(secret + Vector2(-9, -4), 5, Color(0.9, 1, 0.9, 0.7))
		draw_circle(secret + Vector2(9, -4), 5, Color(0.9, 1, 0.9, 0.7))


func draw_acorn(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-9, -4), Vector2(18, 18)), Color("ffd68b"))
	draw_rect(Rect2(pos + Vector2(-5, 14), Vector2(10, 4)), Color("efab62"))
	draw_rect(Rect2(pos + Vector2(-13, -10), Vector2(26, 9)), Color("a8674d"))
	draw_rect(Rect2(pos + Vector2(-9, -14), Vector2(18, 4)), Color("dd9562"))
	draw_rect(Rect2(pos + Vector2(0, -21), Vector2(4, 8)), Color("b8d287"))
	draw_rect(Rect2(pos + Vector2(4, -20), Vector2(9, 4)), Color("c5e6a0"))
	draw_rect(Rect2(pos + Vector2(-5, 0), Vector2(4, 9)), Color("fff2bd"))


func _draw_camps() -> void:
	for index in camps.size():
		var pos := camps[index]
		draw_line(pos + Vector2(-20, -4), pos + Vector2(20, -4), Color("a87e67"), 7)
		draw_line(pos + Vector2(-14, -12), pos + Vector2(14, 2), Color("715550"), 6)
		var lit := index <= camp_index
		if not lit:
			_draw_camp_reward(index, pos + Vector2(0, -66))
		if lit:
			draw_circle(pos + Vector2(0, -17), 36, Color(1, 0.62, 0.3, 0.12))
			var flicker := 0.0 if reduced_motion else sin(age * 12) * 3
			draw_colored_polygon(
				PackedVector2Array(
					[
						pos + Vector2(-12, -7),
						pos + Vector2(-6, -25),
						pos + Vector2(2, -40 - flicker),
						pos + Vector2(5, -22),
						pos + Vector2(13, -6)
					]
				),
				Color("ffa65d")
			)
			draw_circle(pos + Vector2(0, -13), 7, Color("ffe6a1"))
		var color := Color("ffda9b") if lit else Color("c1cec6")
		draw_string(
			ROUTE_FONT,
			pos + Vector2(-38, 33),
			"CAMP %d" % (index + 1),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			color
		)


func _draw_critters() -> void:
	for critter in critters:
		if critter.out:
			continue
		var pos := critter_position(critter)
		var frame := int(age * 10) % 6
		var facing := -1.0 if cos(age * critter.speed) > 0 else 1.0
		draw_set_transform(pos, 0, Vector2(facing, 1))
		draw_texture_rect_region(OPOSSUM, Rect2(-36, -50, 72, 56), Rect2(frame * 36, 0, 36, 28))
		draw_set_transform(Vector2.ZERO)


func _draw_camp_reward(index: int, pos: Vector2) -> void:
	for item in ForestEquipment.ITEMS:
		if item.chapter != stage_index or item.camp != index:
			continue
		if item.id == &"bow":
			draw_polyline(
				PackedVector2Array(
					[
						pos + Vector2(-5, -18),
						pos + Vector2(8, -10),
						pos + Vector2(12, 0),
						pos + Vector2(8, 10),
						pos + Vector2(-5, 18)
					]
				),
				Color("e8b879"),
				4
			)
			draw_line(pos + Vector2(-5, -18), pos + Vector2(-5, 18), Color("eee6c8"), 1)
		elif item.id == &"spear":
			draw_line(pos + Vector2(-16, 17), pos + Vector2(13, -12), Color("9b683d"), 4)
			draw_colored_polygon(
				PackedVector2Array(
					[pos + Vector2(9, -16), pos + Vector2(23, -23), pos + Vector2(16, -9)]
				),
				Color("c9d4c7")
			)
			draw_line(pos + Vector2(9, -7), pos + Vector2(14, -12), Color("68835a"), 5)
		elif item.id == &"seed_bomb":
			draw_circle(pos, 14, Color("547344"))
			draw_rect(Rect2(pos + Vector2(-9, -7), Vector2(18, 14)), Color("a5b56a"))
			draw_line(pos + Vector2(0, -13), pos + Vector2(3, -21), Color("728b51"), 3)
			draw_colored_polygon(
				PackedVector2Array(
					[
						pos + Vector2(2, -16),
						pos + Vector2(6, -26),
						pos + Vector2(17, -22),
						pos + Vector2(10, -15)
					]
				),
				Color("a8bc72")
			)
		else:
			var armor_color := Color("9ab880")
			if item.id == &"bark_armor":
				armor_color = Color("b38a57")
			elif item.id == &"ironwood_armor":
				armor_color = Color("83948c")
			draw_colored_polygon(
				PackedVector2Array(
					[
						pos + Vector2(-14, -16),
						pos + Vector2(14, -16),
						pos + Vector2(12, 5),
						pos + Vector2(0, 19),
						pos + Vector2(-12, 5)
					]
				),
				armor_color
			)
			draw_line(pos + Vector2(0, -12), pos + Vector2(0, 12), Color("e6d9a8"), 3)
			if item.id == &"bark_armor":
				draw_line(pos + Vector2(-7, -10), pos + Vector2(-7, 5), Color("63472e"), 2)
				draw_line(pos + Vector2(7, -10), pos + Vector2(7, 5), Color("63472e"), 2)
			elif item.id == &"ironwood_armor":
				for row in [-8, 0, 8]:
					draw_line(pos + Vector2(-8, row), pos + Vector2(8, row), Color("3a514e"), 3)
		draw_string(
			ROUTE_FONT,
			pos + Vector2(-80, -31),
			item.name,
			HORIZONTAL_ALIGNMENT_CENTER,
			160,
			16,
			Color("f5e6be")
		)


func _draw_gate() -> void:
	var unlocked := taken_acorns.size() == acorns.size() and gate_open
	var color := Color("c3f5be") if unlocked else Color("ac99ae")
	draw_circle(gate - Vector2(0, 66), 83, Color(color, 0.08))
	draw_rect(Rect2(gate - Vector2(42, 100), Vector2(84, 100)), Color("223c40"))
	draw_arc(gate - Vector2(0, 93), 43, PI, TAU, 20, Color("b0b2aa"), 12)
	for side in [-1, 1]:
		draw_rect(Rect2(gate + Vector2(side * 45 - 7, -96), Vector2(14, 96)), Color("889c94"))
		for y in range(18, 96, 24):
			draw_line(
				gate + Vector2(side * 45 - 7, -y),
				gate + Vector2(side * 45 + 7, -y),
				Color("536f6c"),
				3
			)
	if unlocked:
		draw_rect(Rect2(gate - Vector2(33, 94), Vector2(66, 94)), Color(0.6, 0.95, 0.7, 0.3))
		for n in 6:
			var y := fposmod(n * 19 - age * 25, 94.0)
			draw_circle(gate + Vector2(sin(n * 6.0 + age) * 22, -y), 3, color)
	for n in 3:
		draw_circle(
			gate + Vector2((n - 1) * 24, -150),
			7,
			Color("ffdc96") if taken_acorns.has(n) else Color("526761")
		)
	draw_string(
		ROUTE_FONT,
		gate + Vector2(-130, -177),
		gate_label,
		HORIZONTAL_ALIGNMENT_CENTER,
		260,
		17,
		Color("304638") if stage_index == 4 else Color("f7e7be")
	)
	var hint := "Continue the trail" if unlocked else "Find all 3 magic acorns"
	if stage_index == 2:
		hint = "The hollow is open" if unlocked else "Collect 3 acorns and pass Old Croak"
	draw_string(
		ROUTE_FONT, gate + Vector2(-140, 34), hint, HORIZONTAL_ALIGNMENT_CENTER, 280, 13, color
	)


func _draw_sign(sign: Dictionary) -> void:
	var pos: Vector2 = sign.pos
	var font := ROUTE_FONT
	var title_color := Color("304638") if stage_index == 4 else Color("ffdeab")
	var hint_color := Color("344b40") if stage_index == 4 else Color("e2e5ce")
	draw_string(font, pos, sign.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, title_color)
	draw_string(
		font, pos + Vector2(0, 24), sign.hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, hint_color
	)


func _draw_millpond() -> void:
	for span in _water_spans:
		draw_rect(Rect2(span.x, 600, span.y - span.x, 120), Color("365d66"))
		for row in 4:
			var shift := 0.0 if reduced_motion else fposmod(age * 12 + row * 17, 70)
			for x in range(int(span.x), int(span.y), 70):
				var start := minf(x + shift, span.y)
				var end := minf(start + 29, span.y)
				draw_line(
					Vector2(start, 607 + row * 14), Vector2(end, 607 + row * 14), Color("729494"), 2
				)
	for platform in platforms:
		if platform.kind == "wall" or platform.kind == "ground":
			continue
		var x := platform.position.x + platform.size.x * 0.5
		if platform.kind == "ledge":
			draw_rect(
				Rect2(x - 5, platform.position.y + 25, 10, 680 - platform.position.y),
				Color("494b49")
			)


func _draw_cavern_growth(point: Vector2, kind: int) -> void:
	if kind % 2 == 0:
		draw_texture_rect(
			ROCK, Rect2(point - Vector2(50, 81), Vector2(100, 86)), false, Color("a2b09a")
		)
		for root_index in 3:
			var start := point + Vector2(-27 + root_index * 19, -50 + root_index * 9)
			draw_polyline(
				PackedVector2Array([start, start + Vector2(9, 19), start + Vector2(3, 40)]),
				Color("7f8058"),
				3
			)
	else:
		draw_texture_rect(
			SHROOM, Rect2(point - Vector2(25, 34), Vector2(50, 38)), false, Color("a9b990")
		)
		draw_texture_rect(
			BUSH, Rect2(point + Vector2(16, -24), Vector2(45, 28)), false, Color("87a778")
		)
