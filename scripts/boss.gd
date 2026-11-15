class_name ForestBoss
extends Node2D
## Forest guardians mark a landing, leap, then expose their caps while resting.
## The game owns the fox's health; this encounter only reports damaging contact.

signal player_hit
signal damaged(remaining: int)
signal defeated_boss

const GuardianArt := preload("res://scripts/guardian_art.gd")
const MAX_HEALTH := 3
const FLOOR_Y := 536.0
const LEAP_HEIGHT := 110.0
const LEAP_DURATION := 0.82
const BODY_SIZE := Vector2(88, 72)
const CAP_HALF_WIDTH := 37.0
const CAP_TOP := -13.0
const CAP_BOTTOM := 13.0
const IDLE := preload("res://assets/pixel/animals/sunnyland/frog-idle-sheet.png")
const JUMP_UP := preload("res://assets/pixel/animals/sunnyland/frog-jump-frame-01.png")
const JUMP_DOWN := preload("res://assets/pixel/animals/sunnyland/frog-jump-frame-02.png")

var guardian_name := "Old Croak"
var species: StringName = &"frog"
var body_size := BODY_SIZE
var cap_height := -79.0
var cap_color := Color("627545")
var warning_duration := 1.1
var leap_duration := LEAP_DURATION
var leap_height := LEAP_HEIGHT
var wave_speed := 170.0
var rest_duration := 2.1
var crown_points := 0
var fox: ForestFox
var active := false
var engaged := false
var defeated := false
var health := MAX_HEALTH
var phase := "waiting"
var arena_min := 2600.0
var arena_max := 3400.0
var reduced_motion := false
var landing_x := 2970.0
var phase_time := 0.0
var waves: Array[Dictionary] = []

var _home := Vector2(2970, FLOOR_Y)
var _leap_start := Vector2.ZERO
var _animation_time := 0.0
var _contact_cooldown := 0.0
var _facing_left := true


func configure(chapter: int) -> void:
	var profile := ForestChapters.guardian(chapter)
	guardian_name = profile.name
	species = profile.animal
	if species == &"opossum":
		body_size = Vector2(88, 56)
		cap_height = -61.0
	cap_color = Color(profile.cap)
	warning_duration = profile.warning
	leap_duration = profile.leap
	leap_height = profile.height
	wave_speed = profile.wave
	rest_duration = profile.rest
	crown_points = chapter / 3
	if chapter > 2:
		arena_min = 3000.0
		arena_max = 3800.0
	position = Vector2(arena_min + 370, FLOOR_Y)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 5
	_home = global_position
	reset_battle()


func begin() -> void:
	if engaged or defeated:
		return
	engaged = true
	_warn()


func reset_battle() -> void:
	engaged = false
	defeated = false
	health = MAX_HEALTH
	phase = "waiting"
	phase_time = 0.0
	_animation_time = 0.0
	_contact_cooldown = 0.0
	global_position = _home
	landing_x = _home.x
	_leap_start = _home
	waves.clear()
	queue_redraw()


func status_text() -> String:
	match phase:
		"warning":
			return "Move away from the marked landing spot."
		"leap", "landing":
			return "Jump over the ripples."
		"rest":
			return "Gold cap: double-jump onto it, or shoot!"
		"hurt":
			return "He's getting his breath back."
		"defeated":
			return "%s has yielded. The path is open." % guardian_name
	return "%s guards the clearing." % guardian_name


func _physics_process(delta: float) -> void:
	if not active or not engaged or defeated:
		return
	_animation_time += delta
	phase_time += delta
	_contact_cooldown = maxf(0, _contact_cooldown - delta)
	_advance_phase()
	_update_waves(delta)
	_check_contact(delta)
	queue_redraw()


func _advance_phase() -> void:
	match phase:
		"warning":
			if phase_time >= warning_duration - (MAX_HEALTH - health) * 0.1:
				_leap_start = global_position
				_set_phase("leap")
		"leap":
			var progress := minf(phase_time / leap_duration, 1.0)
			global_position = Vector2(
				lerpf(_leap_start.x, landing_x, progress),
				FLOOR_Y - sin(progress * PI) * leap_height
			)
			if progress >= 1.0:
				_land()
		"landing":
			if phase_time >= 0.28:
				_set_phase("rest")
		"rest":
			if phase_time >= rest_duration:
				_warn()
		"hurt":
			if phase_time >= 0.65:
				_warn()


func _warn() -> void:
	_set_phase("warning")
	var target := fox.global_position.x if is_instance_valid(fox) else _home.x
	# Lock the marker before launch. The fox always gets time to move clear.
	landing_x = clampf(target, arena_min + 120, arena_max - 120)
	_facing_left = landing_x < global_position.x


func _set_phase(next: String) -> void:
	phase = next
	phase_time = 0.0


func _land() -> void:
	global_position = Vector2(landing_x, FLOOR_Y)
	_set_phase("landing")
	var speed := wave_speed + (MAX_HEALTH - health) * 25.0
	for direction in [-1, 1]:
		waves.append({"x": landing_x + direction * 46, "speed": speed * direction})


func _update_waves(delta: float) -> void:
	for wave in waves:
		wave.x += wave.speed * delta
	waves = waves.filter(
		func(wave: Dictionary) -> bool: return wave.x > arena_min - 30 and wave.x < arena_max + 30
	)


func _check_contact(delta: float) -> void:
	if not is_instance_valid(fox) or not fox.active or fox.global_position.y > FLOOR_Y + 30:
		return
	var bounds := fox.body_bounds()
	var body := body_bounds()
	if phase == "rest" and _crossed_cap(delta):
		_take_stomp()
		return
	if _contact_cooldown > 0:
		return
	if phase != "hurt" and bounds.intersects(body.grow(-4)):
		_contact_cooldown = 0.35
		player_hit.emit()
		return
	for wave in waves:
		var wave_bounds := Rect2(wave.x - 15, FLOOR_Y - 16, 30, 16)
		if bounds.intersects(wave_bounds):
			_contact_cooldown = 0.35
			player_hit.emit()
			return


func _take_stomp() -> void:
	fox.bounce(-560)
	_take_hit()


func body_bounds() -> Rect2:
	return Rect2(global_position - Vector2(body_size.x / 2, body_size.y), body_size)


func cap_bounds() -> Rect2:
	return Rect2(
		global_position + Vector2(-CAP_HALF_WIDTH, _cap_y() + CAP_TOP),
		Vector2(CAP_HALF_WIDTH * 2, CAP_BOTTOM - CAP_TOP)
	)


func projectile_bounds() -> Array[Rect2]:
	return [body_bounds(), cap_bounds()]


func _crossed_cap(delta: float) -> bool:
	if fox.velocity.y <= 30:
		return false
	var cap := cap_bounds()
	var previous_feet := fox.global_position - fox.velocity * delta
	# The cap is the target shown to the player. Crossing its top from above
	# counts immediately, before the feet sink into the body. Side entries do not.
	if previous_feet.y > cap.position.y + 3 or fox.global_position.y < cap.position.y:
		return false
	var progress := clampf(
		(cap.position.y - previous_feet.y) / (fox.global_position.y - previous_feet.y), 0, 1
	)
	var crossing_x := lerpf(previous_feet.x, fox.global_position.x, progress)
	return (
		crossing_x + ForestFox.BODY_SIZE.x / 2 > cap.position.x
		and crossing_x - ForestFox.BODY_SIZE.x / 2 < cap.end.x
	)


func arrow_hit() -> bool:
	if not active or not engaged or defeated or phase != "rest":
		return false
	_take_hit()
	return true


func _take_hit() -> void:
	health -= 1
	waves.clear()
	_contact_cooldown = 0.65
	_set_phase("hurt")
	damaged.emit(health)
	if health == 0:
		defeated = true
		engaged = false
		_set_phase("defeated")
		defeated_boss.emit()
	queue_redraw()


func _draw() -> void:
	_draw_ground_marks()
	_draw_guardian()
	_draw_cap()
	if phase == "rest":
		# Two amber chevrons identify the weak point even without sound or animation.
		var bob := 0.0 if reduced_motion else sin(_animation_time * 5) * 3
		for side in [-1, 1]:
			var point := Vector2(side * 32, _cap_y() - 16 + bob)
			draw_line(point + Vector2(-4, -4), point, Color("ffe29b"), 3)
			draw_line(point + Vector2(4, -4), point, Color("ffe29b"), 3)


func _draw_ground_marks() -> void:
	if phase in ["warning", "leap"]:
		var target := Vector2(landing_x, FLOOR_Y) - global_position
		var ink := Color("dfb87a")
		draw_line(target + Vector2(-45, -2), target + Vector2(45, -2), ink, 3)
		for side in [-1, 1]:
			draw_line(target + Vector2(side * 45, -2), target + Vector2(side * 45, -10), ink, 3)
		draw_line(target + Vector2(-6, -17), target + Vector2(6, -7), ink, 3)
		draw_line(target + Vector2(-6, -7), target + Vector2(6, -17), ink, 3)
	for wave in waves:
		var point := Vector2(wave.x, FLOOR_Y) - global_position
		var direction: float = signf(wave.speed)
		draw_polyline(
			PackedVector2Array(
				[
					point + Vector2(-direction * 17, -2),
					point + Vector2(-direction * 7, -11),
					point + Vector2(direction * 5, -15),
					point + Vector2(direction * 16, -2)
				]
			),
			Color("c5d9bd"),
			4
		)
		draw_line(point + Vector2(-19, 0), point + Vector2(18, 0), Color("799b8b"), 3)


func _draw_guardian() -> void:
	if species == &"frog":
		_draw_frog()
		return
	var tint := Color("efd7ad") if phase == "hurt" else Color.WHITE
	if defeated:
		tint = Color("b4c9b4")
	GuardianArt.draw_animal(
		self, species, _animation_time, phase, _facing_left, tint, defeated or reduced_motion
	)


func _draw_frog() -> void:
	var rect := Rect2(-70, -108, 140, 128)
	var tint := Color.WHITE
	if phase == "warning":
		rect = Rect2(-74, -99, 148, 118)
	elif phase == "hurt":
		tint = Color("efd7ad")
	elif defeated:
		rect = Rect2(-70, -96, 140, 114)
		tint = Color("b4c9b4")
	# Mirror around the feet; negative draw rectangles otherwise shift the artwork.
	if not _facing_left:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	if phase == "leap":
		rect.position.y = -128
		var image := JUMP_UP if phase_time < leap_duration / 2 else JUMP_DOWN
		draw_texture_rect(image, rect, false, tint)
	else:
		var frame := int(_animation_time * 5) % 4 if not defeated else 0
		draw_texture_rect_region(IDLE, rect, Rect2(frame * 35, 0, 35, 32), tint)
	draw_set_transform(Vector2.ZERO)


func _cap_y() -> float:
	var y := cap_height
	if phase == "leap" and species == &"frog":
		y -= 32
	elif phase == "warning":
		y += 7
	elif defeated:
		y += 14
	return y


func _draw_cap() -> void:
	var y := _cap_y()
	var leaf := Color("b9aa68") if phase == "rest" else cap_color
	var stem := Color("766442")
	# Small reed/crystal tips distinguish later guardians without changing the hitbox.
	for point in crown_points:
		var x := (point - (crown_points - 1) / 2.0) * 9
		draw_line(Vector2(x, y + 2), Vector2(x, y - 10), leaf, 3)
		draw_rect(Rect2(x - 2, y - 12, 4, 4), Color("ffe29b"))
	for side in [-1, 1]:
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(0, y + 7),
					Vector2(side * 24, y + 2),
					Vector2(side * CAP_HALF_WIDTH, y + CAP_TOP),
					Vector2(side * 10, y - 8)
				]
			),
			leaf
		)
		draw_line(Vector2(0, y + 5), Vector2(side * 27, y - 7), stem, 2)
	draw_rect(Rect2(-18, y + 6, 36, 7), Color("b79b57") if phase == "rest" else stem)
	if phase == "rest":
		draw_rect(Rect2(-14, y + 4, 28, 4), Color("ffe29b"))
