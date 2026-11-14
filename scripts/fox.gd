class_name ForestFox
extends CharacterBody2D
## A forgiving double-jump controller. The node's origin is the fox's feet.

signal jumped(double_jump: bool)
signal landed

const RUN_SPEED := 250.0
const GRAVITY := 1500.0
const JUMP_SPEED := -540.0
const DOUBLE_JUMP_SPEED := -510.0
const MAX_FALL_SPEED := 900.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12
const BODY_SIZE := Vector2(22.0, 36.0)
const ART_PATH := "res://assets/pixel/characters/sunnyland/fox-%s-frame-%02d.png"

var active := false
var jumps_left := 2
var facing := 1
var sprite: AnimatedSprite2D

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _ignore_jump_until_release := false
var _just_reset := true


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


func _physics_process(delta: float) -> void:
	if not active:
		return
	# Floor contact belongs to the previous slide, so discard it after teleporting.
	var grounded := is_on_floor() and not _just_reset
	if grounded:
		_coyote_left = COYOTE_TIME
		jumps_left = 2
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		# Walking off an edge still leaves one air jump, never two air jumps.
		if _coyote_left <= 0.0 and jumps_left == 2:
			jumps_left = 1
	_update_jump_input(delta)
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := 2200.0 if grounded else 1500.0
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	if not is_zero_approx(direction):
		facing = 1 if direction > 0.0 else -1
	if _jump_buffer_left > 0.0 and jumps_left > 0:
		_start_jump(not grounded and _coyote_left <= 0.0)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45
	move_and_slide()
	if is_on_floor() and not grounded and velocity.y >= 0.0:
		landed.emit()
	_just_reset = false
	_update_animation()


func reset_at(location: Vector2) -> void:
	global_position = location
	velocity = Vector2.ZERO
	jumps_left = 2
	facing = 1
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_just_reset = true
	# Holding jump through a retry must not turn into a new jump on respawn.
	_ignore_jump_until_release = Input.is_action_pressed("jump")
	modulate = Color.WHITE
	if is_instance_valid(sprite):
		sprite.flip_h = false
		sprite.play(&"idle")


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
	jumped.emit(double_jump)


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
