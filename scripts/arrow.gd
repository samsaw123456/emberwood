class_name ForestArrow
extends Node2D
## Swept projectiles share terrain and enemy contact rules for every weapon.

signal struck(at: Vector2, target: String)

const BURST_DURATION := 0.24

var active := true
var traveled := 0.0
var weapon_id: StringName = &"bow"

var _direction := 1
var _origin := Vector2.ZERO
var _world: ForestLevel
var _boss: ForestBoss
var _excluded: Array[RID] = []
var _spent := false
var _stats: Dictionary
var _velocity := Vector2.ZERO
var _age := 0.0
var _hits_left := 1
var _burst_left := 0.0


func setup(
	origin: Vector2,
	direction: int,
	world: ForestLevel,
	boss: ForestBoss = null,
	shooter: PhysicsBody2D = null,
	selected_weapon: StringName = &"bow"
) -> void:
	_origin = origin
	_direction = -1 if direction < 0 else 1
	_world = world
	_boss = boss
	weapon_id = selected_weapon
	_stats = ForestEquipment.definition(weapon_id)
	if _stats.is_empty() or _stats.get("category") != &"weapon":
		weapon_id = &"bow"
		_stats = ForestEquipment.definition(weapon_id)
	_velocity = Vector2(_direction * float(_stats.speed), float(_stats.get("lift", 0.0)))
	_hits_left = int(_stats.pierce)
	if is_instance_valid(shooter):
		_excluded.append(shooter.get_rid())


func _ready() -> void:
	global_position = _origin
	z_index = 9
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(_world):
		queue_free()
		return
	if _spent:
		_burst_left = maxf(0.0, _burst_left - delta)
		queue_redraw()
		if _burst_left <= 0.0:
			queue_free()
		return
	_age += delta
	var gravity := float(_stats.get("gravity", 0.0))
	var movement := _velocity * delta + Vector2(0, gravity * delta * delta * 0.5)
	_velocity.y += gravity * delta
	var remaining := float(_stats.range) - traveled
	if movement.length() > remaining:
		movement = movement.normalized() * remaining
	var start := global_position
	var end := start + movement
	_move_projectile(start, end)
	if _spent:
		return
	traveled += movement.length()
	if weapon_id == &"seed_bomb" and _age >= float(_stats.fuse):
		_burst_at(global_position)
	elif traveled >= float(_stats.range):
		_spent = true
		queue_free()
	queue_redraw()


func _move_projectile(start: Vector2, end: Vector2) -> void:
	# A spear can contact both targets in one physics step. Each defeated critter
	# is removed from subsequent queries, while terrain always remains blocking.
	while _hits_left > 0:
		var hit := _first_hit(start, end)
		if hit.is_empty():
			global_position = end
			return
		global_position = hit.position
		if weapon_id == &"seed_bomb":
			# Keep the blast on the approach side of a wall so its visibility rays
			# neither originate inside terrain nor reach through it.
			_burst_at(hit.position + hit.normal * 2.0)
			return
		var target: String = hit.target
		if target == "critter":
			hit.critter.out = true
			_world.queue_redraw()
			_hits_left -= 1
		elif target == "boss" and not _boss.arrow_hit():
			target = "blocked"
		struck.emit(global_position, target)
		if target != "critter" or _hits_left <= 0:
			_spent = true
			queue_free()
			return
		start = global_position


func _first_hit(start: Vector2, end: Vector2) -> Dictionary:
	var length := start.distance_to(end)
	var nearest := length + 0.001
	var result: Dictionary = {}
	var terrain := _terrain_between(start, end)
	if not terrain.is_empty():
		nearest = start.distance_to(terrain.position)
		result = {"position": terrain.position, "normal": terrain.normal, "target": "blocked"}
	for critter in _world.critters:
		if critter.out:
			continue
		var fraction := _entry_fraction(_world.critter_bounds(critter), start, end)
		if fraction * length < nearest:
			nearest = fraction * length
			result = {
				"position": start.lerp(end, fraction),
				"normal": Vector2.ZERO,
				"target": "critter",
				"critter": critter
			}
	if is_instance_valid(_boss) and not _boss.defeated:
		for bounds in _boss.projectile_bounds():
			var fraction := _entry_fraction(bounds, start, end)
			if fraction * length < nearest:
				nearest = fraction * length
				result = {
					"position": start.lerp(end, fraction), "normal": Vector2.ZERO, "target": "boss"
				}
	return result


func _terrain_between(start: Vector2, end: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(start, end, 1, _excluded)
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)


func _entry_fraction(bounds: Rect2, start: Vector2, end: Vector2) -> float:
	# Slab intersection sweeps any direction, including a bomb's descending arc.
	var movement := end - start
	var near := 0.0
	var far := 1.0
	for axis in 2:
		if is_zero_approx(movement[axis]):
			if start[axis] < bounds.position[axis] or start[axis] > bounds.end[axis]:
				return INF
			continue
		var first := (bounds.position[axis] - start[axis]) / movement[axis]
		var last := (bounds.end[axis] - start[axis]) / movement[axis]
		near = maxf(near, minf(first, last))
		far = minf(far, maxf(first, last))
		if near > far:
			return INF
	return near


func _burst_at(point: Vector2) -> void:
	global_position = point
	_spent = true
	_burst_left = BURST_DURATION
	var hit_any := false
	for critter in _world.critters:
		if critter.out:
			continue
		var bounds := _world.critter_bounds(critter)
		if _blast_reaches(bounds):
			critter.out = true
			hit_any = true
			struck.emit(_nearest_point(bounds), "critter")
	if is_instance_valid(_boss) and not _boss.defeated:
		for bounds in _boss.projectile_bounds():
			if _blast_reaches(bounds):
				var target := "boss" if _boss.arrow_hit() else "blocked"
				struck.emit(_nearest_point(bounds), target)
				hit_any = true
				break
	if not hit_any:
		struck.emit(point, "blocked")
	_world.queue_redraw()
	queue_redraw()


func _nearest_point(bounds: Rect2) -> Vector2:
	return global_position.clamp(bounds.position, bounds.end)


func _blast_reaches(bounds: Rect2) -> bool:
	var nearest := _nearest_point(bounds)
	if global_position.distance_to(nearest) > float(_stats.radius):
		return false
	return _terrain_between(global_position, nearest).is_empty()


func _draw() -> void:
	if _burst_left > 0.0:
		_draw_burst()
		return
	if weapon_id == &"seed_bomb":
		draw_set_transform(Vector2.ZERO, _age * _direction * 5)
		draw_rect(Rect2(-7, -6, 14, 12), Color("9d633c"))
		draw_rect(Rect2(-5, -7, 9, 5), Color("d3ae68"))
		draw_rect(Rect2(-3, -11, 3, 6), Color("71915b"))
		draw_rect(Rect2(0, -10, 6, 3), Color("9aae6a"))
	else:
		draw_set_transform(Vector2.ZERO, 0, Vector2(_direction, 1))
		if weapon_id == &"spear":
			_draw_spear()
		else:
			_draw_arrow()
	draw_set_transform(Vector2.ZERO)


func _draw_arrow() -> void:
	draw_line(Vector2(-24, 0), Vector2(-5, 0), Color("b88c55"), 3)
	draw_line(Vector2(-23, -4), Vector2(-17, 0), Color("c8d6a5"), 3)
	draw_line(Vector2(-23, 4), Vector2(-17, 0), Color("c8d6a5"), 3)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-7, -4), Vector2(0, 0), Vector2(-7, 4)]), Color("f3e4bd")
	)


func _draw_spear() -> void:
	draw_line(Vector2(-48, 0), Vector2(-10, 0), Color("ad7951"), 4)
	draw_line(Vector2(-31, -3), Vector2(-26, 3), Color("d5b97d"), 2)
	draw_line(Vector2(-26, -3), Vector2(-21, 3), Color("d5b97d"), 2)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-14, -6), Vector2(0, 0), Vector2(-14, 6), Vector2(-10, 0)]),
		Color("c6d3ca")
	)


func _draw_burst() -> void:
	var progress := 1.0 - _burst_left / BURST_DURATION
	var radius := float(_stats.radius)
	var spread := radius * (0.25 + progress * 0.75)
	if _world.reduced_motion:
		spread = radius * 0.55
	for index in 10:
		var point := Vector2.from_angle(index * TAU / 10) * spread
		var color := Color("e1c281") if index % 2 == 0 else Color("9db777")
		color.a = 1.0 - progress
		draw_rect(Rect2(point - Vector2(4, 4), Vector2(8, 8)), color)
	draw_rect(Rect2(-9, -9, 18, 18), Color(0.88, 0.77, 0.51, 1.0 - progress))
