extends CanvasLayer

@onready var hunger_bar: ProgressBar = $Root/StatsPanel/HungerRow/HungerBar
@onready var thirst_bar: ProgressBar = $Root/StatsPanel/ThirstRow/ThirstBar
@onready var stamina_bar: ProgressBar = $Root/StatsPanel/StaminaRow/StaminaBar
@onready var distance_label: Label = $Root/InfoPanel/DistanceLabel
@onready var time_label: Label = $Root/InfoPanel/TimeLabel
@onready var score_label: Label = $Root/InfoPanel/ScoreLabel
@onready var stage_label: Label = $Root/InfoPanel/StageLabel
@onready var prompt_label: Label = $Root/PromptLabel

func _ready() -> void:
	_style_bars()
	call_deferred("_connect_player")

func _style_bars() -> void:
	_style_bar(hunger_bar, Color("#00ff88"))
	_style_bar(thirst_bar, Color("#00e6ff"))
	_style_bar(stamina_bar, Color("#ffdd44"))

func _style_bar(bar: ProgressBar, fill_color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
	bar.add_theme_stylebox_override("background", bg_style)

func _connect_player() -> void:
	var player = get_parent().get_node_or_null("Player")
	if player:
		player.stats_changed.connect(_on_stats_changed)

func _on_stats_changed(hunger: float, thirst: float, stamina: float, _health: float) -> void:
	hunger_bar.value = hunger
	thirst_bar.value = thirst
	stamina_bar.value = stamina

func update_hunger(value: float) -> void:
	hunger_bar.value = value

func update_thirst(value: float) -> void:
	thirst_bar.value = value

func update_stamina(value: float) -> void:
	stamina_bar.value = value

func update_distance(dist: float) -> void:
	distance_label.text = "%.0fm" % dist

func update_time(seconds: float) -> void:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	time_label.text = "%d:%02d" % [mins, secs]

func update_score(s: float) -> void:
	score_label.text = "SCORE: %d" % int(s)

func update_stage(stage: int, stage_name: String, stage_color: Color) -> void:
	stage_label.text = "STAGE %d — %s" % [stage, stage_name]
	stage_label.add_theme_color_override("font_color", stage_color)
	# Flash the stage label briefly
	var tween := create_tween()
	tween.tween_property(stage_label, "modulate:a", 0.1, 0.0)
	tween.tween_property(stage_label, "modulate:a", 1.0, 0.4)
	tween.tween_property(stage_label, "modulate:a", 0.3, 0.2)
	tween.tween_property(stage_label, "modulate:a", 1.0, 0.3)

func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = true

func hide_prompt() -> void:
	prompt_label.visible = false
