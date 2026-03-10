extends CanvasLayer

var hunger_bar: ColorRect
var hunger_fill: ColorRect
var thirst_bar: ColorRect
var thirst_fill: ColorRect
var stamina_bar: ColorRect
var stamina_fill: ColorRect
var distance_label: Label
var time_label: Label
var prompt_label: Label

const BAR_WIDTH: float = 160.0
const BAR_HEIGHT: float = 14.0
const BAR_BG_COLOR := Color(0.15, 0.15, 0.2, 0.85)

func _ready() -> void:
	_build_stat_bars()
	_build_top_right_labels()
	_build_prompt_label()

	# Connect to player once the scene is fully ready
	call_deferred("_connect_player")

func _connect_player() -> void:
	var player = get_parent().get_node_or_null("Player")
	if player:
		player.stats_changed.connect(_on_stats_changed)

func _build_stat_bars() -> void:
	var margin := 16
	var y_start := 16
	var labels := ["HUNGER", "THIRST", "STAMINA"]
	var fill_colors := [Color("#00ff88"), Color("#00e6ff"), Color("#ffdd44")]
	var bar_fills := []

	for i in range(3):
		# Label
		var lbl := Label.new()
		lbl.text = labels[i]
		lbl.position = Vector2(margin, y_start + i * 24)
		lbl.add_theme_color_override("font_color", fill_colors[i])
		lbl.add_theme_font_size_override("font_size", 10)
		add_child(lbl)

		# Bar background
		var bg := ColorRect.new()
		bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		bg.position = Vector2(margin + 60, y_start + i * 24 + 1)
		bg.color = BAR_BG_COLOR
		add_child(bg)

		# Bar fill
		var fill := ColorRect.new()
		fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		fill.position = Vector2(margin + 60, y_start + i * 24 + 1)
		fill.color = fill_colors[i]
		add_child(fill)
		bar_fills.append(fill)

	hunger_fill = bar_fills[0]
	thirst_fill = bar_fills[1]
	stamina_fill = bar_fills[2]

func _build_top_right_labels() -> void:
	distance_label = Label.new()
	distance_label.text = "0m"
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	distance_label.position = Vector2(1280 - 200, 16)
	distance_label.size = Vector2(184, 24)
	distance_label.add_theme_color_override("font_color", Color("#e8e8ff"))
	distance_label.add_theme_font_size_override("font_size", 14)
	add_child(distance_label)

	time_label = Label.new()
	time_label.text = "0:00"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.position = Vector2(1280 - 200, 40)
	time_label.size = Vector2(184, 24)
	time_label.add_theme_color_override("font_color", Color("#aaaacc"))
	time_label.add_theme_font_size_override("font_size", 12)
	add_child(time_label)

func _build_prompt_label() -> void:
	prompt_label = Label.new()
	prompt_label.text = ""
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(440, 660)
	prompt_label.size = Vector2(400, 30)
	prompt_label.add_theme_color_override("font_color", Color("#ffd700"))
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.visible = false
	add_child(prompt_label)

func _on_stats_changed(hunger: float, thirst: float, stamina: float, _health: float) -> void:
	hunger_fill.size.x = BAR_WIDTH * (hunger / 100.0)
	thirst_fill.size.x = BAR_WIDTH * (thirst / 100.0)
	stamina_fill.size.x = BAR_WIDTH * (stamina / 100.0)

func update_distance(dist: float) -> void:
	distance_label.text = "%.0fm" % dist

func update_time(seconds: float) -> void:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	time_label.text = "%d:%02d" % [mins, secs]

func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = true

func hide_prompt() -> void:
	prompt_label.visible = false
