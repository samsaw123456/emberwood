class_name ForestBackdrop
extends Node2D
## Screen-sized woodland layers. The game supplies the camera's left edge.

const VIEW_SIZE := Vector2(1152, 648)
const TREE: Texture2D = preload("res://assets/pixel/nature/sunnyland/tree.png")
const PINE: Texture2D = preload("res://assets/pixel/nature/sunnyland/pine.png")

var chapter_index := 0
var view_x: float = 0.0
var reduced_motion: bool = false
var _time: float = 0.0
var _fireflies: Array[Vector3] = []


func _ready() -> void:
	z_index = -30
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var random := RandomNumberGenerator.new()
	random.seed = 4762
	for index in range(28):
		_fireflies.append(
			Vector3(random.randf_range(0, 1450), random.randf_range(180, 550), random.randf() * TAU)
		)


func _process(delta: float) -> void:
	# Cancelling the camera translation keeps the sky fixed; each layer scrolls separately.
	position.x = view_x
	if not reduced_motion:
		_time += delta
	queue_redraw()


func _draw() -> void:
	match ForestChapters.theme(chapter_index):
		&"mill":
			_draw_mill_valley()
		&"canopy":
			_draw_high_branches()
		&"cavern":
			_draw_caverns()
		&"ridge":
			_draw_ridge()
		&"river":
			_draw_river_trail()
		&"frost":
			_draw_frost_trail()
		&"ancient":
			_draw_ancient_trail()
		_:
			_draw_emberwood()


func _draw_emberwood() -> void:
	var moonlight := smoothstep(2600.0, 4000.0, view_x)
	_draw_sky(moonlight)
	_draw_distant_woods(moonlight)
	_draw_tree_layer(0.22, 290.0, Color("355960").lerp(Color("354b61"), moonlight), 0.75)
	_draw_art_trees(moonlight)
	_draw_tree_layer(0.47, 590.0, Color("173b43").lerp(Color("233748"), moonlight), 1.1)
	_draw_canopy(moonlight)
	_draw_fireflies()


func _draw_sky(moonlight: float) -> void:
	var top := Color("244855").lerp(Color("222b49"), moonlight)
	var bottom := Color("d7ba80").lerp(Color("718c9b"), moonlight)
	for band in range(54):
		var amount := float(band) / 53.0
		draw_rect(Rect2(0, band * 12, VIEW_SIZE.x, 13), top.lerp(bottom, amount))
	var light_position := Vector2(875 - sin(view_x * 0.0003) * 70, 260)
	var light_color := Color("edcf8e").lerp(Color("e4e6cd"), moonlight)
	draw_circle(light_position, 122, Color(light_color, 0.025))
	draw_circle(light_position, 92, Color(light_color, 0.05))
	draw_circle(light_position, 65, light_color)
	var crater_color := Color(0.54, 0.62, 0.65, moonlight * 0.24)
	draw_circle(light_position + Vector2(-18, -10), 11, crater_color)
	draw_circle(light_position + Vector2(19, 20), 16, crater_color)
	draw_circle(light_position + Vector2(24, -25), 6, crater_color)
	var ray_color := Color(1.0, 0.86, 0.60, 0.045).lerp(Color(0.77, 0.88, 1.0, 0.045), moonlight)
	for index in range(4):
		var start := 350.0 + index * 260.0 - fposmod(view_x * 0.08, 170)
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(start, 0),
					Vector2(start + 42, 0),
					Vector2(start - 220, 600),
					Vector2(start - 350, 600)
				]
			),
			ray_color
		)


func _draw_distant_woods(moonlight: float) -> void:
	var offset := fposmod(view_x * 0.10, 120.0)
	var trees := Color("6a897d").lerp(Color("607786"), moonlight)
	for index in range(-1, 12):
		var x := index * 120.0 - offset
		var height := 250.0 + sin(index * 5.7) * 70.0
		draw_rect(Rect2(x + 45, 510 - height, 12, height), trees)
		for tier in range(3):
			var y := 510.0 - height + tier * 46.0
			var width := 38.0 + tier * 12.0
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x + 51, y - 75),
						Vector2(x + 51 - width, y + 36),
						Vector2(x + 51 + width, y + 36)
					]
				),
				trees
			)
	draw_rect(Rect2(0, 495, VIEW_SIZE.x, 153), Color("527573").lerp(Color("4a6575"), moonlight))


func _draw_tree_layer(parallax: float, spacing: float, color: Color, size: float) -> void:
	var offset := fposmod(view_x * parallax, spacing)
	for index in range(-1, int(ceil(VIEW_SIZE.x / spacing)) + 2):
		var x := index * spacing - offset
		var trunk_width := 27.0 * size
		var base := 570.0
		var lean := sin(index * 2.7) * 24.0
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x - trunk_width * 1.5, base),
					Vector2(x - trunk_width * 0.5, 240),
					Vector2(x + lean - trunk_width * 0.35, -20),
					Vector2(x + lean + trunk_width * 0.35, -20),
					Vector2(x + trunk_width * 0.6, 300),
					Vector2(x + trunk_width * 1.7, base)
				]
			),
			color
		)
		draw_line(Vector2(x, 243), Vector2(x - 86 * size, 154), color, 14 * size)
		draw_line(Vector2(x, 310), Vector2(x + 92 * size, 218), color, 11 * size)
		draw_line(Vector2(x - 58 * size, 181), Vector2(x - 55 * size, 112), color, 7 * size)
		draw_line(Vector2(x + 59 * size, 250), Vector2(x + 138 * size, 234), color, 6 * size)
		for leaf in range(5):
			var leaf_x := x - 80 * size + leaf * 42 * size
			var leaf_y := 103 + sin(leaf * 3.1 + index) * 25
			draw_circle(Vector2(leaf_x, leaf_y), 60 * size, color)


func _draw_art_trees(moonlight: float) -> void:
	var spacing := 440.0
	var offset := fposmod(view_x * 0.32, spacing)
	var tree_tint := Color("749380").lerp(Color("7a879b"), moonlight)
	var pine_tint := Color("658f80").lerp(Color("70849b"), moonlight)
	for index in range(-1, 5):
		var x := index * spacing - offset
		draw_texture_rect(TREE, Rect2(x, 252, 226, 270), false, tree_tint)
		draw_texture_rect(PINE, Rect2(x + 254, 266, 148, 260), false, pine_tint)


func _draw_canopy(moonlight: float) -> void:
	var offset := fposmod(view_x * 0.38, 180.0)
	var leaves := Color("163b44").lerp(Color("25364b"), moonlight)
	var highlights := Color("1e454b").lerp(Color("2b4055"), moonlight)
	for index in range(-1, 9):
		var x := index * 180.0 - offset
		draw_circle(Vector2(x, -40), 117, leaves)
		draw_circle(Vector2(x + 90, -58), 124, leaves)
		draw_circle(Vector2(x + 46, -35), 91, highlights)
	# Fine hanging vines make the forest ceiling readable without obscuring the route.
	var vines := Color("2e5655").lerp(Color("3a5367"), moonlight)
	var vine_leaves := Color("376561").lerp(Color("476779"), moonlight)
	for index in range(7):
		var x := fposmod(index * 211.0 - view_x * 0.4, 1400) - 80
		var end_y := 99.0 + sin(index * 4.0) * 29.0
		draw_line(Vector2(x, 0), Vector2(x + 13, end_y), vines, 3.0)
		draw_circle(Vector2(x + 8, end_y - 15), 5, vine_leaves)
		draw_circle(Vector2(x + 16, end_y - 29), 5, vine_leaves)


func _draw_fireflies() -> void:
	for fly in _fireflies:
		var glow := 0.4 + 0.3 * sin(_time * 1.5 + fly.z)
		var point := Vector2(
			fposmod(fly.x - view_x * 0.6 + sin(_time * 0.4 + fly.z) * 15, 1400) - 100,
			fly.y + sin(_time * 0.6 + fly.z) * 12
		)
		draw_circle(point, 8, Color(0.98, 0.85, 0.48, glow * 0.07))
		draw_circle(point, 3.5, Color(0.98, 0.87, 0.57, glow * 0.15))
		draw_rect(Rect2(point - Vector2.ONE, Vector2(2, 2)), Color(1, 0.92, 0.65, glow))


func _draw_mill_valley() -> void:
	# Silt, old timber and cloudy reflected light distinguish the mill from the woods.
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("8d9992"))
	for band in 6:
		draw_rect(
			Rect2(0, 235 + band * 60, 1152, 61),
			Color("8d9992").lerp(Color("536d71"), float(band + 1) / 6)
		)
	_draw_tree_layer(0.12, 410, Color("657c75"), 0.7)
	var mill_x := 440.0 - view_x * 0.24
	draw_rect(Rect2(mill_x, 260, 360, 300), Color("535955"))
	draw_colored_polygon(
		PackedVector2Array(
			[Vector2(mill_x - 25, 260), Vector2(mill_x + 170, 148), Vector2(mill_x + 390, 260)]
		),
		Color("484e4c")
	)
	for x in range(0, 361, 90):
		draw_rect(Rect2(mill_x + x, 260, 13, 300), Color("353f3f"))
	for y in [280, 390, 515]:
		draw_rect(Rect2(mill_x, y, 360, 10), Color("353f3f"))
	for x in [28, 123, 218]:
		draw_rect(Rect2(mill_x + x, 305, 44, 56), Color("adad8f"))
		draw_line(Vector2(mill_x + x + 22, 305), Vector2(mill_x + x + 22, 361), Color("353f3f"), 5)
	var wheel := Vector2(mill_x + 410, 455)
	var turn := 0.0 if reduced_motion else _time * 0.10
	draw_arc(wheel, 94, 0, TAU, 48, Color("3b4948"), 11)
	draw_arc(wheel, 75, 0, TAU, 48, Color("78877c"), 5)
	for spoke in 10:
		var direction := Vector2.from_angle(turn + spoke * TAU / 10)
		draw_line(wheel, wheel + direction * 96, Color("3b4948"), 7)
		draw_line(
			wheel + direction * 98 - direction.orthogonal() * 16,
			wheel + direction * 98 + direction.orthogonal() * 16,
			Color("73837a"),
			7
		)
	draw_circle(wheel, 14, Color("384748"))
	for x in range(-100, 1350, 260):
		var post := x - fposmod(view_x * 0.4, 260)
		draw_rect(Rect2(post, 460, 12, 190), Color("465b5c"))
		draw_line(Vector2(post, 477), Vector2(post + 260, 530), Color("465b5c"), 4)


func _draw_high_branches() -> void:
	# Open sky above a distant forest floor makes the canopy's height legible.
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("9caba2"))
	for band in 16:
		var shade := Color("9caba2").lerp(Color("d6c9a6"), float(band) / 15)
		draw_rect(Rect2(0, 260 + band * 26, 1152, 27), shade)
	for layer in 3:
		var drift := fposmod(view_x * (0.05 + layer * 0.04), 240)
		var shade: Color = [Color("95a99d"), Color("7e9a8e"), Color("647e76")][layer]
		for index in range(-1, 7):
			var x := index * 240.0 - drift
			var top := 470.0 + layer * 40 + sin(index * 4.0) * 20
			draw_colored_polygon(
				PackedVector2Array([Vector2(x, 648), Vector2(x + 110, top), Vector2(x + 220, 648)]),
				shade
			)
	var offset := fposmod(view_x * 0.28, 660)
	for index in range(-1, 3):
		var x := index * 660.0 - offset
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x, 648),
					Vector2(x + 35, 100),
					Vector2(x + 66, -50),
					Vector2(x + 92, -50),
					Vector2(x + 80, 390),
					Vector2(x + 100, 648)
				]
			),
			Color("596d63")
		)
		draw_polyline(
			PackedVector2Array(
				[Vector2(x + 53, 355), Vector2(x + 160, 312), Vector2(x + 260, 220)]
			),
			Color("596d63"),
			22
		)
		draw_texture_rect(PINE, Rect2(x + 115, 151, 164, 260), false, Color("8a9a78"))
		for twig in 4:
			draw_line(
				Vector2(x + 170 + twig * 18, 301 - twig * 16),
				Vector2(x + 176 + twig * 18, 249 - twig * 24),
				Color("596d63"),
				5
			)
	_draw_fireflies()


func _draw_caverns() -> void:
	# Roots and weathered stone continue the forest beneath its floor.
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("30473f"))
	for layer in 2:
		var spacing := 340.0 + layer * 110.0
		var offset := fposmod(view_x * (0.08 + layer * 0.10), spacing)
		var stone: Color = [Color("40554a"), Color("526254")][layer]
		for index in range(-1, 5):
			var x := index * spacing - offset
			var shoulder := 225.0 + sin(index * 3.7) * 65
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x, 648),
						Vector2(x + 15, shoulder + 150),
						Vector2(x + 70, shoulder),
						Vector2(x + 165, shoulder - 35),
						Vector2(x + 245, shoulder + 70),
						Vector2(x + 310, 648)
					]
				),
				stone
			)
			draw_polyline(
				PackedVector2Array(
					[
						Vector2(x + 70, shoulder),
						Vector2(x + 120, shoulder + 100),
						Vector2(x + 90, shoulder + 240)
					]
				),
				Color("344a40"),
				5
			)
	# Small breaks in the roof admit daylight without brightening the whole cavern.
	var opening_x := 705.0 - fposmod(view_x * 0.14, 1500)
	for offset in [0.0, 1500.0]:
		var x: float = opening_x + offset
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x, 0),
					Vector2(x + 86, 0),
					Vector2(x + 122, 250),
					Vector2(x + 50, 315),
					Vector2(x - 38, 230)
				]
			),
			Color("73856b")
		)
		draw_line(Vector2(x + 40, 0), Vector2(x + 25, 110), Color("c0c191"), 14)
	var drift := fposmod(view_x * 0.32, 290)
	for index in range(-1, 6):
		var x := index * 290.0 - drift
		var tip := 100.0 + sin(index * 4.1) * 27
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x - 15, 0),
					Vector2(x + 305, 0),
					Vector2(x + 300, 75),
					Vector2(x + 225, 95),
					Vector2(x + 192, tip + 45),
					Vector2(x + 155, 95),
					Vector2(x + 70, 130),
					Vector2(x + 28, 77)
				]
			),
			Color("263e36")
		)
		var root := PackedVector2Array(
			[Vector2(x + 66, 20), Vector2(x + 92, 105), Vector2(x + 75, 160), Vector2(x + 115, 225)]
		)
		draw_polyline(root, Color("7c7755"), 7)
		draw_line(Vector2(x + 80, 150), Vector2(x + 42, 180), Color("7c7755"), 3)
		draw_line(Vector2(x + 110, 214), Vector2(x + 137, 199), Color("7c7755"), 3)
		for moss in 4:
			draw_rect(
				Rect2(x + 145 + moss * 13, 83 + moss % 2 * 8, 9, 18 + moss * 3), Color("72815b")
			)


func _draw_ridge() -> void:
	# Warm exposed rock and distant blue-grey ridgelines replace the tree ceiling.
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("dfcfaa"))
	for cloud in 4:
		var x := cloud * 340.0 - fposmod(view_x * 0.06, 340) - 70
		var y := 145.0 + cloud % 2 * 45
		draw_rect(Rect2(x, y, 150, 12), Color("f0e5c8"))
		draw_rect(Rect2(x + 35, y - 12, 83, 12), Color("f0e5c8"))
	for layer in 3:
		var spacing := 460.0
		var drift := fposmod(view_x * (0.035 + layer * 0.045), spacing)
		var shade: Color = [Color("a7b4a7"), Color("8b9a8e"), Color("707e70")][layer]
		for index in range(-1, 4):
			var x := index * spacing - drift
			var peak := 235.0 + layer * 80 + sin(index * 2.7 + layer) * 45
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x - 40, 648),
						Vector2(x + 45, peak + 90),
						Vector2(x + 160, peak),
						Vector2(x + 225, peak + 60),
						Vector2(x + 280, peak + 50),
						Vector2(x + 500, 648)
					]
				),
				shade
			)
			if layer == 0:
				draw_colored_polygon(
					PackedVector2Array(
						[
							Vector2(x + 120, peak + 32),
							Vector2(x + 160, peak),
							Vector2(x + 205, peak + 42),
							Vector2(x + 162, peak + 27)
						]
					),
					Color("dedcc1")
				)
	var offset := fposmod(view_x * 0.30, 510)
	for index in range(-1, 4):
		var x := index * 510.0 - offset
		draw_texture_rect(PINE, Rect2(x + 35, 312, 142, 246), false, Color("8c9875"))
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x + 190, 648),
					Vector2(x + 220, 500),
					Vector2(x + 280, 465),
					Vector2(x + 370, 510),
					Vector2(x + 440, 648)
				]
			),
			Color("8d8970")
		)
		draw_line(Vector2(x + 280, 470), Vector2(x + 290, 565), Color("716f5d"), 4)


func _draw_river_trail() -> void:
	var reach := chapter_index - 5
	var sky: Color = [
		Color("a4b8a4"), Color("9caf9c"), Color("b7bca6"), Color("9eafa4"), Color("aabdb0")
	][reach]
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), sky)
	_draw_tree_layer(0.10, 370, Color("799184"), 0.64)
	draw_rect(Rect2(0, 420, 1152, 228), Color("6e928b"))
	for row in 5:
		var drift := fposmod(view_x * 0.12 + (0 if reduced_motion else _time * 4), 230)
		for index in range(-1, 6):
			draw_rect(
				Rect2(index * 230 - drift + row * 31, 439 + row * 32, 107, 3), Color("9bb2a0")
			)
	if reach == 2:
		_draw_aqueduct(270.0 - view_x * 0.20)
	elif reach == 4:
		var fall_x := 720.0 - view_x * 0.17
		draw_rect(Rect2(fall_x - 100, 200, 340, 370), Color("698576"))
		_draw_distant_fall(Vector2(fall_x, 218), Vector2(90, 330), Color("b4cbc0"))
		_draw_aqueduct(fall_x - 540)
	else:
		var offset := fposmod(view_x * 0.28, 470)
		for index in range(-1, 4):
			var x := index * 470.0 - offset
			draw_texture_rect(TREE, Rect2(x, 270, 230, 260), false, Color(Color("75967f"), 0.36))
			if reach == 1:
				for strand in 6:
					var strand_x := x + 30 + strand * 29
					draw_line(
						Vector2(strand_x, 300),
						Vector2(strand_x + 8, 390 + strand % 3 * 27),
						Color("64866b"),
						4
					)
			elif reach == 3:
				# Distant standing herons are scenery, below and behind the play surface.
				var bird := Vector2(x + 290, 485)
				draw_line(bird, bird + Vector2(0, -30), Color("536f69"), 3)
				draw_line(bird + Vector2(0, -30), bird + Vector2(-11, -48), Color("536f69"), 5)
				draw_line(bird + Vector2(-11, -48), bird + Vector2(-23, -46), Color("536f69"), 3)
	var reeds_offset := fposmod(view_x * 0.40, 160)
	for index in range(-1, 9):
		var x := index * 160.0 - reeds_offset
		for stem in 4:
			var tip := Vector2(x + stem * 13, 516 - (stem % 3) * 18)
			draw_line(Vector2(x + stem * 11, 610), tip, Color("547b65"), 3)
			draw_rect(Rect2(tip - Vector2(3, 15), Vector2(6, 18)), Color("6e7860"))


func _draw_aqueduct(start_x: float) -> void:
	for index in 5:
		var x := start_x + index * 200
		# A missing upper span identifies the broken aqueduct without adding false platforms.
		if index != 2:
			draw_rect(Rect2(x - 7, 255, 214, 35), Color("74877b"))
			draw_line(Vector2(x, 267), Vector2(x + 197, 267), Color("a1ad96"), 4)
		draw_rect(Rect2(x - 9, 305, 30, 270), Color("697d72"))
		draw_arc(Vector2(x + 102, 365), 94, PI, TAU, 24, Color("7d8d7e"), 21)
		for row in 5:
			draw_line(
				Vector2(x - 8, 340 + row * 42), Vector2(x + 20, 340 + row * 42), Color("536e64"), 3
			)


func _draw_distant_fall(origin: Vector2, dimensions: Vector2, shade: Color) -> void:
	draw_rect(Rect2(origin, dimensions), shade.darkened(0.12))
	for strip in 5:
		var width := dimensions.x / 6.0
		draw_rect(
			Rect2(origin + Vector2(strip * width + 4, 0), Vector2(width * 0.55, dimensions.y)),
			shade
		)
	var shift := 0.0 if reduced_motion else fposmod(_time * 26, 52)
	for row in int(dimensions.y / 52):
		draw_line(
			origin + Vector2(6, row * 52 + shift),
			origin + Vector2(dimensions.x - 6, row * 52 + shift),
			shade.lightened(0.12),
			2
		)


func _draw_frost_trail() -> void:
	var climb := chapter_index - 10
	var sky: Color = [
		Color("a8b9bf"), Color("b5c6ca"), Color("aebfc0"), Color("bdcbca"), Color("cbd3cd")
	][climb]
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), sky)
	for layer in 3:
		var spacing := 480.0
		var drift := fposmod(view_x * (0.04 + layer * 0.05), spacing)
		var stone: Color = [Color("92a9ac"), Color("748e94"), Color("536f79")][layer]
		for index in range(-1, 4):
			var x := index * spacing - drift
			var peak := 185.0 + layer * 75 + sin(index * 4 + climb) * 32
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x - 60, 648),
						Vector2(x + 160, peak),
						Vector2(x + 220, peak + 75),
						Vector2(x + 300, peak + 58),
						Vector2(x + 490, 648)
					]
				),
				stone
			)
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x + 108, peak + 94),
						Vector2(x + 160, peak),
						Vector2(x + 220, peak + 75),
						Vector2(x + 186, peak + 61),
						Vector2(x + 160, peak + 47)
					]
				),
				Color("dce3d9").darkened(layer * 0.10)
			)
	if climb == 1 or climb == 3:
		var fall_x := 690.0 - view_x * 0.16
		_draw_distant_fall(Vector2(fall_x, 280), Vector2(55, 270), Color("c1d8d7"))
	if climb == 4:
		for cloud in 4:
			var x := cloud * 360.0 - fposmod(view_x * 0.09, 360)
			draw_rect(Rect2(x - 100, 388 + cloud % 2 * 33, 245, 18), Color("d0dad3"))
			draw_rect(Rect2(x - 56, 374 + cloud % 2 * 33, 149, 18), Color("d0dad3"))
	var offset := fposmod(view_x * 0.31, 410)
	for index in range(-1, 4):
		var x := index * 410.0 - offset
		if climb != 2:
			_draw_snow_pine(Vector2(x, 292), 0.9)
			_draw_snow_pine(Vector2(x + 180, 360), 0.65)
		else:
			for slab in 4:
				draw_colored_polygon(
					PackedVector2Array(
						[
							Vector2(x + slab * 37, 590),
							Vector2(x + slab * 37 + 43, 384 + slab * 19),
							Vector2(x + slab * 37 + 67, 407 + slab * 19),
							Vector2(x + slab * 37 + 61, 590)
						]
					),
					Color("607d82")
				)
	if not reduced_motion:
		for flake in 16:
			var point := Vector2(
				fposmod(flake * 173.0 - view_x * 0.22 + _time * 7, 1250) - 50,
				fposmod(flake * 71 + _time * 10, 570)
			)
			draw_rect(Rect2(point, Vector2(2, 2)), Color("dce6df"))


func _draw_snow_pine(origin: Vector2, scale_factor: float) -> void:
	draw_texture_rect(
		PINE, Rect2(origin, Vector2(150, 260) * scale_factor), false, Color(Color("7e9a93"), 0.38)
	)
	for tier in 3:
		var middle := origin + Vector2(77, 42 + tier * 44) * scale_factor
		var width := (19 + tier * 11) * scale_factor
		draw_line(
			middle - Vector2(width, 0),
			middle + Vector2(width, 0),
			Color(Color("cbd9d1"), 0.6),
			5 * scale_factor
		)


func _draw_ancient_trail() -> void:
	var depth := chapter_index - 15
	var sky: Color = [
		Color("a7aa7d"), Color("929d7c"), Color("6d8372"), Color("b5b184"), Color("b9b990")
	][depth]
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), sky)
	_draw_tree_layer(0.07, 410, Color("778c6c"), 0.85)
	var offset := fposmod(view_x * 0.25, 520)
	for index in range(-1, 4):
		var x := index * 520.0 - offset
		var copper := Color("6a6e49") if depth != 2 else Color("4b6552")
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x - 15, 648),
					Vector2(x + 49, 290),
					Vector2(x + 58, -20),
					Vector2(x + 107, -20),
					Vector2(x + 101, 320),
					Vector2(x + 155, 648)
				]
			),
			copper
		)
		draw_polyline(
			PackedVector2Array(
				[Vector2(x + 72, 265), Vector2(x + 191, 190), Vector2(x + 295, 170)]
			),
			copper,
			19
		)
		for leaf in 5:
			var leaf_x := x - 24 + leaf * 64
			var leaf_y := 60 + sin(leaf * 3.4 + index) * 25
			draw_rect(
				Rect2(leaf_x, leaf_y, 106, 64), Color("7f8c51") if depth < 3 else Color("a3a464")
			)
		if depth == 0:
			for notch in 6:
				draw_line(
					Vector2(x + 61, 165 + notch * 55),
					Vector2(x + 91, 152 + notch * 55),
					Color("b18958"),
					5
				)
		elif depth == 2:
			var lantern := Vector2(x + 219, 235)
			draw_line(lantern - Vector2(0, 55), lantern, Color("4d6250"), 3)
			draw_rect(Rect2(lantern - Vector2(10, 0), Vector2(20, 27)), Color("596148"))
			draw_rect(Rect2(lantern + Vector2(-6, 4), Vector2(12, 18)), Color("d6bf79"))
		elif depth == 3:
			draw_line(Vector2(x + 80, 365), Vector2(x + 300, 292), Color("77804c"), 12)
			for leaf in 4:
				draw_rect(Rect2(x + 145 + leaf * 42, 317 - leaf * 14, 33, 13), Color("b8b66b"))
	if depth == 1:
		_draw_rooted_ruins(210.0 - view_x * 0.16)
	elif depth == 4:
		_draw_heart_tree(760.0 - view_x * 0.14)
	_draw_fireflies()


func _draw_rooted_ruins(start_x: float) -> void:
	for pillar in 4:
		var x := start_x + pillar * 260
		var top := 315.0 + pillar % 2 * 38
		draw_rect(Rect2(x, top, 61, 270), Color("737e61"))
		draw_rect(Rect2(x - 9, top - 13, 79, 23), Color("8c9371"))
		for row in 5:
			draw_line(
				Vector2(x + 2, top + 33 + row * 43),
				Vector2(x + 60, top + 33 + row * 43),
				Color("596e53"),
				3
			)
		draw_polyline(
			PackedVector2Array(
				[
					Vector2(x + 17, top - 10),
					Vector2(x + 44, top + 52),
					Vector2(x + 20, top + 141),
					Vector2(x + 49, top + 237)
				]
			),
			Color("4f694d"),
			9
		)
		draw_rect(Rect2(x + 14, top + 13, 23, 13), Color("a8a780"))


func _draw_heart_tree(center_x: float) -> void:
	# A single old tree anchors the last level; its roots stay behind the solid route.
	var bark := Color("5b714e")
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(center_x - 190, 648),
				Vector2(center_x - 80, 350),
				Vector2(center_x - 63, 60),
				Vector2(center_x + 65, 60),
				Vector2(center_x + 92, 370),
				Vector2(center_x + 240, 648)
			]
		),
		bark
	)
	for side in [-1, 1]:
		draw_polyline(
			PackedVector2Array(
				[
					Vector2(center_x, 185),
					Vector2(center_x + side * 140, 110),
					Vector2(center_x + side * 260, 92)
				]
			),
			bark,
			36
		)
		draw_polyline(
			PackedVector2Array(
				[
					Vector2(center_x + side * 65, 442),
					Vector2(center_x + side * 220, 525),
					Vector2(center_x + side * 330, 555)
				]
			),
			bark,
			29
		)
	for ring in 5:
		draw_arc(
			Vector2(center_x + 4, 303), 27 + ring * 9, -PI * 0.55, PI * 0.73, 24, Color("89905c"), 3
		)
	for crown in 7:
		draw_rect(Rect2(center_x - 300 + crown * 84, 19 + crown % 3 * 17, 137, 82), Color("929c57"))
