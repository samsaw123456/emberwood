class_name ForestPlatform
extends AnimatableBody2D
## Solid terrain and reusable moving/crumbling woodland bridges.

const GROUND_TEXTURE: Texture2D = preload("res://assets/pixel/terrain/sunnyland/block-big.png")
const BRIDGE_TEXTURE: Texture2D = preload("res://assets/pixel/terrain/sunnyland/platform-long.png")
const CRUMBLE_DELAY := 0.55
const RESTORE_DELAY := 3.5

var kind: String = "ground"
var size: Vector2 = Vector2.ZERO
var origin: Vector2 = Vector2.ZERO
var travel: Vector2 = Vector2.ZERO
var phase: float = 0.0
var age: float = 0.0
var crumble_time: float = -1.0
var active: bool = false
var _collision: CollisionShape2D


func setup(rect: Rect2, type: String = "ground", motion: Vector2 = Vector2.ZERO) -> void:
	kind = type
	size = rect.size
	origin = rect.position
	position = origin
	travel = motion
	age = 0.0
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not is_instance_valid(_collision):
		_collision = CollisionShape2D.new()
		add_child(_collision)
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_collision.shape = rectangle
	_collision.position = size / 2.0
	reset_bridge()


func _physics_process(delta: float) -> void:
	if not active:
		return
	age += delta
	if kind == "moving":
		position = origin + travel * sin(age * 1.35 + phase)
	if kind != "crumble" or crumble_time < 0.0:
		return
	crumble_time += delta
	if crumble_time >= RESTORE_DELAY:
		reset_bridge()
	elif crumble_time >= CRUMBLE_DELAY:
		collision_layer = 0
	queue_redraw()


func step_on() -> void:
	if kind == "crumble" and crumble_time < 0.0:
		crumble_time = 0.0
		queue_redraw()


func reset_bridge() -> void:
	crumble_time = -1.0
	collision_layer = 1
	queue_redraw()


func _draw() -> void:
	if kind == "wall":
		return
	if kind == "crumble" and crumble_time >= CRUMBLE_DELAY:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.73, 0.40, 0.16), false, 2.0)
		return
	if kind == "ground":
		_draw_ground()
	else:
		_draw_bridge()


func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("393748"))
	for row in range(int(ceil(size.y / 64.0))):
		for column in range(int(ceil(size.x / 64.0))):
			var tile_position := Vector2(column * 64, row * 64)
			var tile_size := (size - tile_position).min(Vector2(64, 64))
			draw_texture_rect_region(
				GROUND_TEXTURE,
				Rect2(tile_position, tile_size),
				Rect2(Vector2.ZERO, tile_size / 2.0),
				Color(0.43, 0.48, 0.60)
			)
	draw_rect(Rect2(0, 8, size.x, minf(8, size.y - 8)), Color("51806b"))
	draw_rect(Rect2(0, 0, size.x, minf(8, size.y)), Color("a8c87c"))
	for tuft in range(int(size.x / 34.0)):
		var x := 13.0 + tuft * 34.0
		draw_rect(Rect2(x, -3, 3, 5), Color("a8c87c"))
		draw_rect(Rect2(x + 5, -5, 3, 7), Color("a8c87c"))
		draw_rect(Rect2(x + 11, 1, 3, 10), Color("88b675"))


func _draw_bridge() -> void:
	var tint := Color("c0bdad")
	if kind == "crumble":
		tint = Color("f4b47c")
		if crumble_time >= 0.0 and int(crumble_time * 14) % 2 == 0:
			tint = Color("ffe2a4")
	for column in range(int(ceil(size.x / 64.0))):
		var width := minf(64.0, size.x - column * 64.0)
		draw_texture_rect_region(
			BRIDGE_TEXTURE, Rect2(column * 64, 0, width, 32), Rect2(0, 0, width / 2.0, 16), tint
		)
	if kind == "moving":
		draw_rect(Rect2(2, 0, maxf(0, size.x - 4), 4), Color("8edbdc"))
		draw_line(Vector2(8, 9), Vector2(8, 21), Color("628c9b"), 3)
		draw_line(Vector2(size.x - 8, 9), Vector2(size.x - 8, 21), Color("628c9b"), 3)
	elif kind == "crumble":
		draw_rect(Rect2(2, 0, maxf(0, size.x - 4), 4), Color("efad72"))
		for crack in range(int(size.x / 40.0)):
			var x := 22.0 + crack * 40.0
			draw_polyline(
				PackedVector2Array([Vector2(x, 3), Vector2(x - 5, 12), Vector2(x + 3, 21)]),
				Color("593c45"),
				3.0
			)
