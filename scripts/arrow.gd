class_name ForestArrow
extends Node2D
## The arrow tip sweeps the whole flight segment, including thin terrain.

signal struck(at: Vector2, target: String)

const SPEED := 700.0
const MAX_RANGE := 700.0

var active := true
var traveled := 0.0

var _direction := 1
var _origin := Vector2.ZERO
var _world: ForestLevel
var _boss: ForestBoss
var _excluded: Array[RID] = []
var _spent := false


func setup(
	origin: Vector2,
	direction: int,
	world: ForestLevel,
	boss: ForestBoss = null,
	shooter: PhysicsBody2D = null
) -> void:
	_origin = origin
	_direction = -1 if direction < 0 else 1
	_world = world
	_boss = boss
	if is_instance_valid(shooter):
		_excluded.append(shooter.get_rid())


func _ready() -> void:
	global_position = _origin
	z_index = 9
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	if not active or _spent:
		return
	if not is_instance_valid(_world):
		queue_free()
		return
	var distance := minf(SPEED * delta, MAX_RANGE - traveled)
	var start := global_position
	var end := start + Vector2(_direction * distance, 0)
	var nearest := distance + 0.001
	var target := ""
	var hit_critter: Dictionary = {}
	var query := PhysicsRayQueryParameters2D.create(start, end, 1, _excluded)
	query.hit_from_inside = true
	var terrain := get_world_2d().direct_space_state.intersect_ray(query)
	if not terrain.is_empty():
		nearest = start.distance_to(terrain.position)
		target = "blocked"
	for critter in _world.critters:
		if critter.out:
			continue
		var entry := _entry_distance(_world.critter_bounds(critter), start, distance)
		if entry < nearest:
			nearest = entry
			target = "critter"
			hit_critter = critter
	if is_instance_valid(_boss) and not _boss.defeated:
		var entry := _entry_distance(_boss.body_bounds(), start, distance)
		if entry < nearest:
			nearest = entry
			target = "boss"
	if not target.is_empty():
		global_position = start + Vector2(_direction * nearest, 0)
		_spent = true
		if target == "critter":
			hit_critter.out = true
			_world.queue_redraw()
		elif target == "boss" and not _boss.arrow_hit():
			target = "blocked"
		struck.emit(global_position, target)
		queue_free()
		return
	global_position = end
	traveled += distance
	if traveled >= MAX_RANGE:
		_spent = true
		queue_free()


func _entry_distance(bounds: Rect2, start: Vector2, distance: float) -> float:
	# Horizontal travel allows exact swept rectangle contact without sampled overlap.
	if start.y < bounds.position.y or start.y > bounds.end.y:
		return INF
	var entry := bounds.position.x - start.x if _direction > 0 else start.x - bounds.end.x
	var exit_distance := bounds.end.x - start.x if _direction > 0 else start.x - bounds.position.x
	if exit_distance < 0 or entry > distance:
		return INF
	return maxf(0.0, entry)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(_direction, 1))
	draw_line(Vector2(-24, 0), Vector2(-5, 0), Color("b88c55"), 3)
	draw_line(Vector2(-23, -4), Vector2(-17, 0), Color("c8d6a5"), 3)
	draw_line(Vector2(-23, 4), Vector2(-17, 0), Color("c8d6a5"), 3)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-7, -4), Vector2(0, 0), Vector2(-7, 4)]), Color("f3e4bd")
	)
	draw_set_transform(Vector2.ZERO)
