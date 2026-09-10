extends Node2D

var points: Array[Vector2] = []
var active_index := -1
var time := 0.0


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	for index in points.size():
		var point := points[index]
		var is_active := index == active_index
		var radius := (16.0 if is_active else 10.0) + sin(time * 3.0 + index) * 2.0
		var color := Color(0.42, 0.96, 1.0, 0.72) if is_active else Color(0.96, 0.71, 0.28, 0.25)
		draw_circle(point, radius, color, false, 2.0)
		if is_active:
			draw_circle(point, 4.0, Color(1.0, 0.9, 0.55, 0.9))
