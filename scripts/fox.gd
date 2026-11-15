class_name ForestFox
extends CharacterBody2D
## A forgiving double-jump controller. The node's origin is the fox's feet.

signal jumped(double_jump: bool)
signal landed
signal dashed
signal shot_requested

const RUN_SPEED := 250.0
const GRAVITY := 1500.0
const JUMP_SPEED := -540.0
const DOUBLE_JUMP_SPEED := -510.0
const MAX_FALL_SPEED := 900.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12
const DASH_SPEED := 620.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 0.65
const BODY_SIZE := Vector2(22.0, 36.0)
const ART_PATH := "res://assets/pixel/characters/sunnyland/fox-%s-frame-%02d.png"

var active := false
var jumps_left := 2
var facing := 1
var sprite: AnimatedSprite2D
var dash_left := 0.0
var dash_cooldown_left := 0.0
var reduced_motion := false:
	set(value):
		reduced_motion = value
		queue_redraw()
var weapon_id: StringName = &"":
	set(value):
		weapon_id = value
		_redraw_gear()
var armor_id: StringName = &"":
	set(value):
		armor_id = value
		_redraw_gear()
var bow_equipped := false:
	set(value):
		bow_equipped = value
		_redraw_gear()
var armor_equipped := false:
	set(value):
		armor_equipped = value
		_redraw_gear()
var armor_charged := false:
	set(value):
		armor_charged = value
		_redraw_gear()

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _jump_cut_available := false
var _ignore_jump_until_release := false
var _ignore_dash_until_release := false
var _air_dash_available := true
var _dash_direction := 1
var _gear_art: Node2D
var _discard_floor_contact := true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 6.0
	floor_stop_on_slope = true
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_DO_NOTHING
	var shape := RectangleShape2D.new()
	shape.size = BODY_SIZE
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0.0, -BODY_SIZE.y / 2.0)
	add_child(collider)
	_build_sprite()
	_gear_art = Node2D.new()
	_gear_art.z_index = 1
	_gear_art.draw.connect(_draw_gear)
	add_child(_gear_art)


func _physics_process(delta: float) -> void:
	if not active:
		return
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	# A teleport or external bounce invalidates the previous slide's floor contact.
	var grounded := is_on_floor() and not _discard_floor_contact
	if grounded:
		_coyote_left = COYOTE_TIME
		jumps_left = 2
		_air_dash_available = true
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		if dash_left <= 0.0:
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		# Walking off an edge still leaves one air jump, never two air jumps.
		if _coyote_left <= 0.0 and jumps_left == 2:
			jumps_left = 1
	_update_jump_input(delta)
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := 2200.0 if grounded else 1500.0
	if dash_left <= 0.0 and not is_zero_approx(direction):
		facing = 1 if direction > 0.0 else -1
	var starting_jump := false
	if _jump_buffer_left > 0.0 and jumps_left > 0:
		dash_left = 0.0
		_start_jump(not grounded and _coyote_left <= 0.0)
		starting_jump = true
	if not Input.is_action_pressed("dash"):
		_ignore_dash_until_release = false
	if Input.is_action_just_pressed("dash") and not _ignore_dash_until_release:
		if can_dash() and not starting_jump:
			_start_dash()
	if dash_left > 0.0:
		# Account for the final partial tick so distance does not depend on tick rate.
		velocity = Vector2(_dash_direction * DASH_SPEED * minf(1.0, dash_left / delta), 0.0)
	else:
		velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	if Input.is_action_just_released("jump"):
		if _jump_cut_available and velocity.y < 0.0:
			velocity.y *= 0.45
		_jump_cut_available = false
	move_and_slide()
	if dash_left > 0.0:
		dash_left = 0.0 if is_on_wall() else maxf(0.0, dash_left - delta)
		if dash_left <= 0.0:
			velocity.x = clampf(velocity.x, -RUN_SPEED, RUN_SPEED)
	if is_on_floor() and not grounded and velocity.y >= 0.0:
		landed.emit()
	_discard_floor_contact = false
	_update_animation()
	_redraw_gear()
	queue_redraw()
	# Resolve weapon input after movement so a same-tick turn uses the visible facing.
	if Input.is_action_just_pressed("shoot"):
		shot_requested.emit()


func reset_at(location: Vector2) -> void:
	global_position = location
	velocity = Vector2.ZERO
	jumps_left = 2
	facing = 1
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_jump_cut_available = false
	dash_left = 0.0
	dash_cooldown_left = 0.0
	_air_dash_available = true
	_discard_floor_contact = true
	# Holding jump through a retry must not turn into a new jump on respawn.
	_ignore_jump_until_release = Input.is_action_pressed("jump")
	_ignore_dash_until_release = Input.is_action_pressed("dash")
	modulate = Color.WHITE
	_redraw_gear()
	queue_redraw()
	if is_instance_valid(sprite):
		sprite.flip_h = false
		sprite.play(&"idle")


func can_dash() -> bool:
	return active and dash_left <= 0.0 and dash_cooldown_left <= 0.0 and _air_dash_available


func bounce(speed: float) -> void:
	velocity.y = speed
	jumps_left = 1
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_jump_cut_available = false
	dash_left = 0.0
	_discard_floor_contact = true


func body_bounds() -> Rect2:
	return Rect2(global_position - Vector2(BODY_SIZE.x / 2.0, BODY_SIZE.y), BODY_SIZE)


func show_pose(animation: StringName) -> void:
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)


func _update_jump_input(delta: float) -> void:
	_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)
	if not Input.is_action_pressed("jump"):
		_ignore_jump_until_release = false
	if Input.is_action_just_pressed("jump") and not _ignore_jump_until_release:
		_jump_buffer_left = JUMP_BUFFER_TIME


func _start_jump(double_jump: bool) -> void:
	velocity.y = DOUBLE_JUMP_SPEED if double_jump else JUMP_SPEED
	jumps_left -= 1
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_jump_cut_available = true
	jumped.emit(double_jump)


func _start_dash() -> void:
	dash_left = DASH_DURATION
	dash_cooldown_left = DASH_COOLDOWN
	_dash_direction = facing
	_air_dash_available = false
	dashed.emit()


func _redraw_gear() -> void:
	if is_instance_valid(_gear_art):
		_gear_art.queue_redraw()


func _draw_gear() -> void:
	_gear_art.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	if armor_equipped:
		_draw_armor()
	var weapon := weapon_id if not weapon_id.is_empty() else (&"bow" if bow_equipped else &"")
	if not weapon.is_empty():
		_gear_art.draw_rect(Rect2(7, -21, 14, 5), Color("b96841"))
		_gear_art.draw_rect(Rect2(10, -21, 11, 3), Color("e5ad73"))
	match weapon:
		&"bow":
			_draw_bow()
		&"spear":
			_gear_art.draw_line(Vector2(-13, -19), Vector2(32, -19), Color("9b683d"), 3)
			_gear_art.draw_line(Vector2(-13, -20), Vector2(30, -20), Color("d2ad70"), 1)
			_gear_art.draw_colored_polygon(
				PackedVector2Array([Vector2(29, -24), Vector2(42, -19), Vector2(29, -14)]),
				Color("c9d4c7")
			)
			_gear_art.draw_rect(Rect2(26, -22, 4, 6), Color("5c7068"))
		&"seed_bomb":
			_gear_art.draw_rect(Rect2(-15, -19, 9, 14), Color("795b39"))
			_gear_art.draw_rect(Rect2(-14, -18, 7, 3), Color("c29a55"))
			_gear_art.draw_circle(Vector2(22, -21), 8, Color("547344"))
			_gear_art.draw_rect(Rect2(17, -27, 7, 11), Color("a5b56a"))
			_gear_art.draw_line(Vector2(22, -28), Vector2(25, -33), Color("b6c98b"), 2)
			_gear_art.draw_line(Vector2(24, -31), Vector2(29, -32), Color("7e9b56"), 3)
	_gear_art.draw_set_transform(Vector2.ZERO)


func _draw_armor() -> void:
	var armor := armor_id if not armor_id.is_empty() else &"armor"
	var definition := ForestEquipment.definition(armor)
	var base: Color = definition.armor_color
	var edge: Color = definition.armor_edge
	if not armor_charged:
		base = base.darkened(0.35)
	_gear_art.draw_rect(Rect2(-7, -22, 16, 15), edge)
	_gear_art.draw_rect(Rect2(-5, -22, 12, 12), base)
	_draw_armor_pattern(definition.armor_art, base, edge)
	_gear_art.draw_rect(Rect2(-5, -8, 12, 3), Color("a5784e"))


func _draw_armor_pattern(art: StringName, base: Color, edge: Color) -> void:
	match art:
		&"leaf":
			_gear_art.draw_rect(Rect2(-1, -21, 2, 13), Color("c3b171"))
			_gear_art.draw_line(Vector2(-5, -18), Vector2(5, -14), Color("526b48"), 2)
		&"bark", &"ironwood", &"copper":
			for x in [-3, 3]:
				_gear_art.draw_line(Vector2(x, -21), Vector2(x - 1, -10), edge, 2)
			_gear_art.draw_rect(Rect2(-9, -23, 7, 5), base.lightened(0.12))
			_gear_art.draw_rect(Rect2(5, -23, 7, 5), base.lightened(0.12))
			if art == &"ironwood":
				for x in [-5, 5]:
					_gear_art.draw_rect(Rect2(x, -19, 2, 2), Color("d5d4a8"))
				_gear_art.draw_rect(Rect2(-6, -11, 14, 4), Color("b8c1ab"))
			elif art == &"copper":
				_gear_art.draw_line(Vector2(-5, -22), Vector2(6, -9), edge, 3)
				for point in [Vector2(-6, -21), Vector2(6, -21), Vector2(-5, -11), Vector2(5, -11)]:
					_gear_art.draw_rect(Rect2(point, Vector2(3, 3)), Color("e1bd80"))
		&"reeds":
			for x in [-5, -1, 3, 7]:
				_gear_art.draw_line(Vector2(x, -25), Vector2(x, -7), base.lightened(0.2), 2)
			for y in [-20, -14, -9]:
				_gear_art.draw_line(Vector2(-7, y), Vector2(9, y), edge, 2)
		&"frost":
			_gear_art.draw_rect(Rect2(-9, -26, 21, 6), Color("d8ded0"))
			_gear_art.draw_rect(Rect2(-10, -20, 4, 14), base.darkened(0.1))
			_gear_art.draw_rect(Rect2(-2, -20, 3, 12), Color("d8ded0"))
			_gear_art.draw_rect(Rect2(7, -20, 4, 8), Color("d8ded0"))
		&"slate":
			for y in [-23, -17, -11]:
				_gear_art.draw_rect(Rect2(-7, y, 16, 5), base.lightened(0.08))
				_gear_art.draw_line(Vector2(-6, y + 4), Vector2(8, y + 4), edge, 1)
			_gear_art.draw_rect(Rect2(-11, -25, 8, 8), edge)
			_gear_art.draw_rect(Rect2(5, -25, 8, 8), edge)
		&"sunleaf":
			for side in [-1, 1]:
				_gear_art.draw_colored_polygon(
					PackedVector2Array(
						[
							Vector2(side * 2, -23),
							Vector2(side * 13, -29),
							Vector2(side * 10, -18),
							Vector2(side * 3, -15)
						]
					),
					base.lightened(0.15)
				)
			_gear_art.draw_rect(Rect2(-2, -20, 5, 7), Color("f0dc9a"))
			_gear_art.draw_line(Vector2(-5, -11), Vector2(7, -11), edge, 2)


func _draw_bow() -> void:
	_gear_art.draw_polyline(
		PackedVector2Array(
			[
				Vector2(15, -34),
				Vector2(21, -29),
				Vector2(24, -21),
				Vector2(21, -13),
				Vector2(15, -8)
			]
		),
		Color("cb975b"),
		3
	)
	_gear_art.draw_line(Vector2(15, -33), Vector2(15, -9), Color("f0ddad"), 1)
	_gear_art.draw_rect(Rect2(19, -24, 5, 6), Color("795239"))


func _draw() -> void:
	if dash_left <= 0.0 or reduced_motion:
		return
	for row in 3:
		var point := Vector2(-_dash_direction * (20 + row * 5), -10 - row * 9)
		draw_line(point, point + Vector2(-_dash_direction * 14, 0), Color("d8d8a2"), 2)


func _update_animation() -> void:
	sprite.flip_h = facing < 0
	if not is_on_floor():
		sprite.play(&"jump")
		sprite.frame = 0 if velocity.y < 0.0 else 1
	elif absf(velocity.x) > 15.0:
		sprite.play(&"run")
	else:
		sprite.play(&"idle")


func _build_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# SunnyLand's 32 px frame has transparent space above, and feet at its bottom.
	sprite.position = Vector2(0.0, -32.0)
	sprite.scale = Vector2(2.0, 2.0)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var animations := {"idle": 4, "run": 6, "jump": 2, "hurt": 2, "victory": 1}
	for animation: String in animations:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, 12.0 if animation == "run" else 7.0)
		frames.set_animation_loop(animation, animation in ["idle", "run"])
		for frame_number: int in range(1, animations[animation] + 1):
			var texture := load(ART_PATH % [animation, frame_number]) as Texture2D
			frames.add_frame(animation, texture)
	sprite.sprite_frames = frames
	add_child(sprite)
	sprite.play(&"idle")
