class_name ForestFinds
extends Node2D
## Optional discoveries: one dash chest per trail and a rescued gem-collecting friend.

const MAGNET_RADIUS := 115.0
const CHEST_STARTS := [430.0, 450.0, 430.0, 520.0, 450.0]
const FONT := preload("res://assets/fonts/DejaVuSans.ttf")

var chest := Vector2.ZERO
var chest_open := false
var leaf_shield := false
var companion := false
var fox: ForestFox
var age := 0.0
var gentle := false
var friend_position := Vector2.ZERO


func start_chapter(index: int) -> void:
	chest = Vector2(CHEST_STARTS[index] if index < CHEST_STARTS.size() else 1940.0, 536)
	chest_open = false
	leaf_shield = false
	age = 0.0
	snap_to_fox()


func snap_to_fox() -> void:
	friend_position = fox.position + Vector2(-fox.facing * 38, -64)
	queue_redraw()


func chest_bounds() -> Rect2:
	return Rect2(chest - Vector2(25, 34), Vector2(50, 34))


func try_open() -> bool:
	if chest_open or fox.dash_left <= 0 or not fox.body_bounds().intersects(chest_bounds()):
		return false
	chest_open = true
	leaf_shield = true
	queue_redraw()
	return true


func absorb_hit() -> bool:
	if not leaf_shield:
		return false
	leaf_shield = false
	queue_redraw()
	return true


func can_fetch(point: Vector2) -> bool:
	var origin := fox.position - Vector2(0, 20)
	if not companion or origin.distance_to(point) > MAGNET_RADIUS:
		return false
	# The friend never pulls gems through solid platforms or walls.
	var query := PhysicsRayQueryParameters2D.create(origin, point, 1, [fox.get_rid()])
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func advance(delta: float, reduced_motion: bool) -> void:
	age += delta
	gentle = reduced_motion
	var target := fox.position + Vector2(-fox.facing * 38, -64)
	if not gentle:
		target.y += sin(age * 4) * 5
	friend_position = target if gentle else friend_position.lerp(target, 1 - exp(-10 * delta))
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(fox):
		return
	_draw_chest()
	if leaf_shield:
		# A small leaf crest shows the extra block without covering the fox or its armor.
		var pos := fox.position + Vector2(fox.facing * 26, -24)
		draw_colored_polygon(
			PackedVector2Array(
				[
					pos + Vector2(-9, -13),
					pos + Vector2(10, -8),
					pos + Vector2(7, 8),
					pos + Vector2(0, 15),
					pos + Vector2(-8, 5)
				]
			),
			Color("c8e590")
		)
		draw_line(pos + Vector2(-5, -9), pos + Vector2(0, 11), Color("466b49"), 2)
		for side in [-1, 1]:
			draw_line(pos + Vector2(-2, 1), pos + Vector2(side * 6, -5), Color("466b49"), 2)
	if companion:
		var wing := 0.0 if gentle else sin(age * 18) * 2
		for side in [-1, 1]:
			draw_circle(friend_position + Vector2(side * 9, -3 - wing), 6, Color("e0f2de"))
		draw_circle(friend_position, 7, Color("384a39"))
		draw_circle(friend_position + Vector2(0, 3), 5, Color("fff0a1"))
		draw_rect(Rect2(friend_position + Vector2(-3, -5), Vector2(2, 2)), Color("ffffff"))
		draw_rect(Rect2(friend_position + Vector2(2, -5), Vector2(2, 2)), Color("ffffff"))


func _draw_chest() -> void:
	var edge := Color("422f30")
	var lid_y := -46.0 if chest_open else -34.0
	draw_rect(Rect2(chest + Vector2(-27, -24), Vector2(54, 24)), edge)
	draw_rect(Rect2(chest + Vector2(-24, -22), Vector2(48, 19)), Color("ab7147"))
	for x in [-16, 13]:
		draw_rect(Rect2(chest + Vector2(x, -22), Vector2(4, 19)), Color("e4bd75"))
	draw_rect(Rect2(chest + Vector2(-26, lid_y), Vector2(52, 15)), edge)
	draw_rect(Rect2(chest + Vector2(-23, lid_y + 3), Vector2(46, 9)), Color("cb9659"))
	draw_line(chest + Vector2(-22, -9), chest + Vector2(22, -9), Color("805239"), 2)
	if not chest_open:
		draw_rect(Rect2(chest + Vector2(-5, -25), Vector2(10, 12)), Color("ffe3a2"))
		draw_rect(Rect2(chest + Vector2(-1, -22), Vector2(3, 6)), edge)
		if fox.position.distance_to(chest) < 180:
			var label := chest + Vector2(-105, -55)
			draw_string_outline(
				FONT,
				label,
				"Shift: dash into chest",
				HORIZONTAL_ALIGNMENT_CENTER,
				210,
				16,
				4,
				Color("263b35")
			)
			draw_string(
				FONT,
				label,
				"Shift: dash into chest",
				HORIZONTAL_ALIGNMENT_CENTER,
				210,
				16,
				Color("fff0cb")
			)
