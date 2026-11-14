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
	if chapter_index == 1:
		_draw_mill_valley()
		return
	if chapter_index == 2:
		_draw_high_branches()
		return
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
