extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var content_box: VBoxContainer = $ContentBox
@onready var time_label: Label = $ContentBox/TimeLabel
@onready var distance_label: Label = $ContentBox/DistanceLabel
@onready var score_label: Label = $ContentBox/ScoreLabel
@onready var restart_label: Label = $ContentBox/RestartLabel

var is_showing: bool = false

func _ready() -> void:
	hide_screen()
	# Start blink tween for restart label (always running, label visibility gates it)
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

	background.visible = true
	content_box.visible = true

	# Fade in background
	background.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 1.0)

func hide_screen() -> void:
	is_showing = false
	background.visible = false
	content_box.visible = false

func _input(event: InputEvent) -> void:
	if is_showing and event is InputEventKey:
		if event.pressed and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
