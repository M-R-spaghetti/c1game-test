extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)

var player: CharacterBody2D
var npc: Node2D
var hotspots: Node2D
var prompt_label: Label
var dialog_panel: Panel
var speaker_label: Label
var dialog_label: Label
var vignette: ColorRect
var dialog_open := false
var current_interaction := -1
var reveal_time := 0.0
var reveal_text := ""
var npc_visits := 0

var interactions := [
	{
		"name": "ЗАВОДНАЯ СЦЕНА",
		"position": Vector2(461.0, 249.0),
		"text":
		(
			"Крошечный дирижёр машет палочкой без музыки. "
			+ "Когда ты подходишь ближе, он отбивает ритм твоих шагов."
		),
	},
	{
		"name": "ДВЕРЬ-УЛЫБКА",
		"position": Vector2(641.0, 248.0),
		"text":
		(
			"На табличке нет слов, только свежая царапина: "
			+ "«АПЛОДИСМЕНТЫ ОТКРЫВАЮТ НЕ ВСЕ ДВЕРИ». Дверь тихо хихикает."
		),
	},
	{
		"name": "МАДАМ ТОК",
		"position": Vector2(930.0, 373.0),
		"npc": true,
		"lines":
		[
			"Ах, новый артист! Билет вам не нужен. Здесь платят воспоминанием.",
			"Вы вернулись! Колокольчик говорит, что это уже маленькая традиция.",
			"Третий разговор подряд? Любопытство — самая дорогая валюта цирка.",
			"П-погодите... в вашем билете появилась строка, которой секунду назад не было!",
		],
	},
	{
		"name": "СБОЙНОЕ ЗЕРКАЛО",
		"position": Vector2(1164.0, 407.0),
		"text":
		"Отражение запаздывает на полсекунды. Потом подмигивает первым. Кажется, оно довольно собой.",
	},
]


func _ready() -> void:
	_build_background()
	_build_collision()
	_build_atmosphere()
	_build_npc()
	_build_player()
	_build_ui()
	_start_intro()
	if "--capture" in OS.get_cmdline_user_args() or "--capture-npc" in OS.get_cmdline_user_args():
		_capture_qa_frame.call_deferred()


func _capture_qa_frame() -> void:
	if "--capture-npc" in OS.get_cmdline_user_args():
		player.position = Vector2(835.0, 410.0)
		npc_visits = 3
		_open_dialog(2)
	await get_tree().create_timer(1.6).timeout
	var frame := get_viewport().get_texture().get_image()
	frame.save_png("res://docs/qa-gameplay.png")
	get_tree().quit()


func _process(delta: float) -> void:
	_update_interaction_target()
	_update_typewriter(delta)
	if dialog_open:
		if Input.is_key_pressed(KEY_ESCAPE):
			_close_dialog()
		elif (
			Input.is_key_pressed(KEY_E)
			or Input.is_key_pressed(KEY_SPACE)
			or Input.is_key_pressed(KEY_ENTER)
		):
			if not get_meta("input_lock", false):
				_close_dialog()
	else:
		if (
			(Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE))
			and current_interaction >= 0
		):
			if not get_meta("input_lock", false):
				_open_dialog(current_interaction)

	var key_down := (
		Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_SPACE)
		or Input.is_key_pressed(KEY_ENTER)
		or Input.is_key_pressed(KEY_ESCAPE)
	)
	set_meta("input_lock", key_down)


func _build_background() -> void:
	var background := TextureRect.new()
	background.texture = preload("res://assets/generated/velvet_error_room.png")
	background.position = Vector2.ZERO
	background.size = VIEW_SIZE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -20
	add_child(background)


func _build_collision() -> void:
	_add_wall(Vector2(640.0, 700.0), Vector2(1280.0, 34.0))
	_add_wall(Vector2(34.0, 465.0), Vector2(68.0, 500.0))
	_add_wall(Vector2(1246.0, 465.0), Vector2(68.0, 500.0))
	_add_wall(Vector2(640.0, 257.0), Vector2(270.0, 62.0))
	_add_wall(Vector2(250.0, 260.0), Vector2(370.0, 95.0))
	_add_wall(Vector2(905.0, 265.0), Vector2(220.0, 90.0))
	_add_wall(Vector2(1133.0, 343.0), Vector2(170.0, 180.0))
	_add_wall(Vector2(116.0, 455.0), Vector2(145.0, 230.0))
	_add_wall(Vector2(930.0, 367.0), Vector2(42.0, 48.0))


func _add_wall(position_value: Vector2, size_value: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position_value
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _build_atmosphere() -> void:
	var effects := Node2D.new()
	effects.set_script(preload("res://scripts/room_fx.gd"))
	effects.z_index = -2
	add_child(effects)

	hotspots = Node2D.new()
	hotspots.set_script(preload("res://scripts/hotspots.gd"))
	var point_list: Array[Vector2] = []
	for item in interactions:
		point_list.append(item.position)
	hotspots.points = point_list
	hotspots.z_index = 2
	add_child(hotspots)


func _build_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(preload("res://scripts/player.gd"))
	player.position = Vector2(640.0, 585.0)
	player.z_index = 5
	add_child(player)


func _build_npc() -> void:
	npc = Node2D.new()
	npc.set_script(preload("res://scripts/npc.gd"))
	npc.position = Vector2(930.0, 373.0)
	npc.z_index = 4
	add_child(npc)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	var title := Label.new()
	title.text = "THE VELVET ERROR"
	title.position = Vector2(35.0, 25.0)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.98, 0.83, 0.48))
	title.add_theme_color_override("font_shadow_color", Color(0.08, 0.01, 0.09, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(title)

	var controls := Label.new()
	controls.text = "WASD / СТРЕЛКИ — ДВИЖЕНИЕ     E / ПРОБЕЛ — ВЗАИМОДЕЙСТВИЕ"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.position = Vector2(625.0, 31.0)
	controls.size = Vector2(620.0, 30.0)
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color(0.82, 0.9, 0.93, 0.76))
	canvas.add_child(controls)

	prompt_label = Label.new()
	prompt_label.visible = false
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(390.0, 570.0)
	prompt_label.size = Vector2(500.0, 40.0)
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0.03, 0.01, 0.05))
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(prompt_label)

	dialog_panel = Panel.new()
	dialog_panel.position = Vector2(105.0, 515.0)
	dialog_panel.size = Vector2(1070.0, 165.0)
	dialog_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.012, 0.04, 0.96)
	panel_style.border_color = Color(0.95, 0.77, 0.35)
	panel_style.set_border_width_all(4)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0.2, 0.0, 0.25, 0.7)
	panel_style.shadow_size = 10
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(dialog_panel)

	speaker_label = Label.new()
	speaker_label.position = Vector2(30.0, 18.0)
	speaker_label.size = Vector2(1000.0, 28.0)
	speaker_label.add_theme_font_size_override("font_size", 17)
	speaker_label.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0))
	dialog_panel.add_child(speaker_label)

	dialog_label = Label.new()
	dialog_label.position = Vector2(30.0, 53.0)
	dialog_label.size = Vector2(1000.0, 92.0)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_label.add_theme_font_size_override("font_size", 20)
	dialog_label.add_theme_color_override("font_color", Color(0.97, 0.94, 0.88))
	dialog_panel.add_child(dialog_label)

	vignette = ColorRect.new()
	vignette.color = Color(0.03, 0.0, 0.07, 1.0)
	vignette.position = Vector2.ZERO
	vignette.size = VIEW_SIZE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(vignette)


func _start_intro() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(vignette, "color:a", 0.0, 1.35)
	tween.tween_callback(vignette.queue_free)


func _update_interaction_target() -> void:
	if dialog_open:
		prompt_label.visible = false
		return
	var closest := -1
	var closest_distance := 100.0
	for index in interactions.size():
		var distance := player.position.distance_to(interactions[index].position)
		if distance < closest_distance:
			closest = index
			closest_distance = distance
	current_interaction = closest
	hotspots.active_index = closest
	prompt_label.visible = closest >= 0
	if closest >= 0:
		prompt_label.text = "[ E ]  " + interactions[closest].name


func _open_dialog(index: int) -> void:
	dialog_open = true
	player.movement_enabled = false
	dialog_panel.visible = true
	speaker_label.text = "◆  " + interactions[index].name
	if interactions[index].get("npc", false):
		var reaction := mini(npc_visits, 3)
		npc.react(reaction)
		reveal_text = interactions[index].lines[reaction]
		npc_visits += 1
	else:
		reveal_text = interactions[index].text
	dialog_label.text = ""
	reveal_time = 0.0
	prompt_label.visible = false


func _close_dialog() -> void:
	dialog_open = false
	player.movement_enabled = true
	dialog_panel.visible = false
	npc.reset()


func _update_typewriter(delta: float) -> void:
	if not dialog_open or dialog_label.text.length() >= reveal_text.length():
		return
	reveal_time += delta * 44.0
	var count := mini(int(reveal_time), reveal_text.length())
	dialog_label.text = reveal_text.left(count)
