extends CharacterBody2D

signal interact_requested(survivor: CharacterBody2D)
signal player_entered_range
signal player_exited_range

var archetype: String = "Wanderer"  # Merchant / Wanderer / Hostile
var player_in_range: bool = false
var name_label: Label
var body_color: Color

const ARCHETYPES := ["Merchant", "Wanderer", "Hostile"]
const ARCHETYPE_COLORS := {
	"Merchant": Color("#ffd700"),
	"Wanderer": Color("#88aaff"),
	"Hostile": Color("#e94560")
}
const ARCHETYPE_NAMES := {
	"Merchant": ["Trader Joe", "Scrap Kate", "Barrel Pete", "Chem Mira"],
	"Wanderer": ["Drifter", "Old Moss", "Nameless", "Whisperer"],
	"Hostile": ["Raider", "Scrapper", "Grunt", "Brute"]
}

var display_name: String = ""
var detection_area: Area2D

func _ready() -> void:
	# Assign random archetype
	archetype = ARCHETYPES[randi() % ARCHETYPES.size()]
	var names_list: Array = ARCHETYPE_NAMES[archetype]
	display_name = names_list[randi() % names_list.size()]
	body_color = ARCHETYPE_COLORS[archetype]

	# Collision for physics (don't block player)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 40)
	col.shape = shape
	col.position = Vector2(0, -20)
	add_child(col)

	# Body visual
	var body_rect := ColorRect.new()
	body_rect.size = Vector2(20, 40)
	body_rect.position = Vector2(-10, -40)
	body_rect.color = body_color
	add_child(body_rect)

	# Head
	var head := ColorRect.new()
	head.size = Vector2(16, 14)
	head.position = Vector2(-8, -54)
	head.color = body_color.lightened(0.15)
	add_child(head)

	# Eyes
	var eye_l := ColorRect.new()
	eye_l.size = Vector2(3, 3)
	eye_l.position = Vector2(-5, -50)
	eye_l.color = Color("#1a1a2e")
	add_child(eye_l)

	var eye_r := ColorRect.new()
	eye_r.size = Vector2(3, 3)
	eye_r.position = Vector2(2, -50)
	eye_r.color = Color("#1a1a2e")
	add_child(eye_r)

	# Archetype label above head
	name_label = Label.new()
	name_label.text = display_name + "\n[" + archetype + "]"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-40, -80)
	name_label.add_theme_color_override("font_color", body_color.lightened(0.3))
	name_label.add_theme_font_size_override("font_size", 11)
	add_child(name_label)

	# Idle sway tween
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 4, 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, 1.2).set_trans(Tween.TRANS_SINE)

	# Detection area
	detection_area = Area2D.new()
	var det_col := CollisionShape2D.new()
	var det_shape := RectangleShape2D.new()
	det_shape.size = Vector2(80, 60)
	det_col.shape = det_shape
	detection_area.add_child(det_col)
	add_child(detection_area)

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		player_in_range = true
		emit_signal("player_entered_range")

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		player_in_range = false
		emit_signal("player_exited_range")

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		emit_signal("interact_requested", self)
