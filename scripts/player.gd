extends CharacterBody2D

const WALK_SPEED := 225.0
const ACCELERATION := 1350.0
const DECELERATION := 1800.0
const WALK_SCALE := 0.31
const WALK_DOWN := preload("res://assets/generated/miro_walk_down_8_clean.png")
const WALK_UP := preload("res://assets/generated/miro_walk_up_8_clean.png")
const WALK_SIDE := preload("res://assets/generated/miro_walk_right_8_clean.png")

var movement_enabled := true
var _walk_phase := 0.0
var _sprite: Sprite2D
var _shadow: Polygon2D


func _ready() -> void:
	_shadow = Polygon2D.new()
	_shadow.polygon = _ellipse_points(Vector2(31.0, 10.0), 24)
	_shadow.color = Color(0.08, 0.015, 0.09, 0.42)
	_shadow.position = Vector2(0.0, -3.0)
	_shadow.z_index = -1
	add_child(_shadow)

	_sprite = Sprite2D.new()
	_sprite.texture = WALK_DOWN
	_sprite.hframes = 4
	_sprite.vframes = 2
	_sprite.frame = 3
	_sprite.scale = Vector2.ONE * WALK_SCALE
	_sprite.position = Vector2(0.0, -78.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)

	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 42.0
	collision.shape = capsule
	collision.position = Vector2(0.0, -18.0)
	add_child(collision)


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if movement_enabled:
		direction.x = (
			float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
			- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		)
		direction.y = (
			float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
			- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
		)
		direction = direction.normalized()

	var target := direction * WALK_SPEED
	var rate := ACCELERATION if direction != Vector2.ZERO else DECELERATION
	velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()
	_animate_character(delta, direction)


func _animate_character(delta: float, direction: Vector2) -> void:
	var speed_ratio := clampf(velocity.length() / WALK_SPEED, 0.0, 1.0)
	if speed_ratio > 0.05:
		_update_facing(direction)
		_walk_phase += delta * lerpf(7.0, 11.5, speed_ratio)
		var bounce := absf(cos(_walk_phase))
		_sprite.frame = int(_walk_phase * 1.25) % 8
		_sprite.position.y = -78.0 - bounce * 1.2
		_sprite.rotation = 0.0
		_sprite.scale = Vector2.ONE * WALK_SCALE
		_shadow.scale = Vector2(1.0 - bounce * 0.08, 1.0 - bounce * 0.03)
	else:
		_walk_phase += delta * 1.8
		var breath := sin(_walk_phase) * 0.008
		_sprite.position.y = -78.0 + sin(_walk_phase) * 0.8
		_sprite.rotation = lerpf(_sprite.rotation, 0.0, delta * 7.0)
		_sprite.frame = 3
		_sprite.scale = Vector2(WALK_SCALE - breath * 0.35, WALK_SCALE + breath)
		_shadow.scale = Vector2.ONE


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_sprite.texture = WALK_SIDE
		_sprite.flip_h = direction.x < 0.0
	elif direction.y < 0.0:
		_sprite.texture = WALK_UP
		_sprite.flip_h = false
	else:
		_sprite.texture = WALK_DOWN
		_sprite.flip_h = false
	_sprite.hframes = 4
	_sprite.vframes = 2


func _ellipse_points(radii: Vector2, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
