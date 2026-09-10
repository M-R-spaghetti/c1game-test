extends Node2D

const MASTER_SCALE := 0.102
const REACTION_SCALE := 0.22
const MASTER := preload("res://assets/generated/madame_tock_master.png")
const REACTIONS := preload("res://assets/generated/madame_tock_reactions_4_clean.png")

var _sprite: Sprite2D
var _time := 0.0
var _reaction := 0


func _ready() -> void:
	var shadow := Polygon2D.new()
	shadow.polygon = _ellipse_points(Vector2(34.0, 9.0), 24)
	shadow.color = Color(0.07, 0.01, 0.08, 0.38)
	shadow.position = Vector2(0.0, -2.0)
	shadow.z_index = -1
	add_child(shadow)

	_sprite = Sprite2D.new()
	_sprite.texture = MASTER
	_sprite.frame = 0
	_sprite.scale = Vector2.ONE * MASTER_SCALE
	_sprite.position = Vector2(0.0, -79.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	var sway := sin(_time * (1.4 if _reaction == 0 else 2.2))
	_sprite.position.y = -79.0 + sin(_time * 1.8) * 1.2
	_sprite.rotation = sway * (0.008 if _reaction == 0 else 0.016)


func react(reaction_index: int) -> void:
	_reaction = clampi(reaction_index, 0, 3)
	_sprite.texture = REACTIONS
	_sprite.hframes = 2
	_sprite.vframes = 2
	_sprite.frame = _reaction
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sprite.scale = Vector2.ONE * REACTION_SCALE * 0.86
	tween.tween_property(_sprite, "scale", Vector2.ONE * REACTION_SCALE, 0.32)


func reset() -> void:
	_reaction = 0
	_sprite.texture = MASTER
	_sprite.hframes = 1
	_sprite.vframes = 1
	_sprite.frame = 0
	_sprite.scale = Vector2.ONE * MASTER_SCALE


func _ellipse_points(radii: Vector2, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
