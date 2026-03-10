extends CanvasLayer

var overlay: ColorRect
var died_label: Label
var time_label: Label
var distance_label: Label
var score_label: Label
var restart_label: Label
var is_showing: bool = false

func _ready() -> void:
	_build_ui()
	hide_screen()

func _build_ui() -> void:
	# Full-screen dark overlay
	overlay = ColorRect.new()
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0.05, 0.02, 0.05, 0.88)
	add_child(overlay)

	# YOU DIED
	died_label = Label.new()
	died_label.text = "YOU DIED"
	died_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	died_label.position = Vector2(0, 220)
	died_label.size = Vector2(1280, 80)
	died_label.add_theme_color_override("font_color", Color("#e94560"))
	died_label.add_theme_font_size_override("font_size", 64)
	add_child(died_label)

	# Time survived
	time_label = Label.new()
	time_label.text = "Time Survived: 0:00"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.position = Vector2(0, 330)
	time_label.size = Vector2(1280, 36)
	time_label.add_theme_color_override("font_color", Color("#aaaacc"))
	time_label.add_theme_font_size_override("font_size", 22)
	add_child(time_label)

	# Distance
	distance_label = Label.new()
	distance_label.text = "Distance Travelled: 0m"
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.position = Vector2(0, 374)
	distance_label.size = Vector2(1280, 36)
	distance_label.add_theme_color_override("font_color", Color("#aaaacc"))
	distance_label.add_theme_font_size_override("font_size", 22)
	add_child(distance_label)

	# Final score (prominent)
	score_label = Label.new()
	score_label.text = "FINAL SCORE: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(0, 420)
	score_label.size = Vector2(1280, 40)
	score_label.add_theme_color_override("font_color", Color("#ffffff"))
	score_label.add_theme_font_size_override("font_size", 28)
	add_child(score_label)

	# Restart prompt
	restart_label = Label.new()
	restart_label.text = "PRESS R TO RESTART"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.position = Vector2(0, 476)
	restart_label.size = Vector2(1280, 36)
	restart_label.add_theme_color_override("font_color", Color("#ffd700"))
	restart_label.add_theme_font_size_override("font_size", 20)
	add_child(restart_label)

	# Blink tween for restart label
	var tween := create_tween().set_loops()
	tween.tween_property(restart_label, "modulate:a", 0.2, 0.7)
	tween.tween_property(restart_label, "modulate:a", 1.0, 0.7)

func show_screen(time_survived: float, distance: float, final_score: float = 0.0) -> void:
	is_showing = true
	var mins := int(time_survived) / 60
	var secs := int(time_survived) % 60
	time_label.text = "Time Survived: %d:%02d" % [mins, secs]
	distance_label.text = "Distance Travelled: %.0fm" % distance
	score_label.text = "FINAL SCORE: %d" % int(final_score)

	overlay.visible = true
	died_label.visible = true
	time_label.visible = true
	distance_label.visible = true
	score_label.visible = true
	restart_label.visible = true

	# Fade in
	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 1.0)

func hide_screen() -> void:
	is_showing = false
	overlay.visible = false
	died_label.visible = false
	time_label.visible = false
	distance_label.visible = false
	score_label.visible = false
	restart_label.visible = false

func _input(event: InputEvent) -> void:
	if is_showing and event is InputEventKey:
		if event.pressed and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
