extends Node2D

var _time := 0.0
var _dust: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 73119
	for index in 32:
		(
			_dust
			. append(
				{
					"pos": Vector2(rng.randf_range(90.0, 1190.0), rng.randf_range(275.0, 665.0)),
					"phase": rng.randf_range(0.0, TAU),
					"size": rng.randf_range(0.7, 1.8),
					"speed": rng.randf_range(0.25, 0.7),
				}
			)
		)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for mote in _dust:
		var position: Vector2 = (
			mote.pos
			+ Vector2(
				sin(_time * mote.speed + mote.phase) * 7.0, -fmod(_time * 5.0 * mote.speed, 22.0)
			)
		)
		var alpha := 0.12 + 0.1 * sin(_time * 1.7 + mote.phase)
		draw_circle(position, mote.size, Color(0.96, 0.76, 0.37, alpha))

	# Gentle pools of colored stage light keep the static painting alive.
	for ring in 5:
		var pulse := 0.018 + sin(_time * 1.2 + ring) * 0.006
		draw_circle(
			Vector2(640.0, 505.0), 115.0 + ring * 13.0, Color(0.18, 0.9, 0.95, pulse), false, 2.0
		)
