extends Area2D

signal collected(resource_type: String, amount: float)
signal player_entered_range
signal player_exited_range

@export var resource_type: String = "food"  # food / water / medicine / fuel

var player_in_range: bool = false
var prompt_label: Label
var crate_rect: ColorRect

# Resource amounts by type
const AMOUNTS := {
	"food": 30.0,
	"water": 25.0,
	"medicine": 20.0,
	"fuel": 15.0
}

const RESOURCE_COLORS := {
	"food": Color("#00ff88"),
	"water": Color("#00e6ff"),
	"medicine": Color("#ff88cc"),
	"fuel": Color("#ffd700")
}

func _ready() -> void:
	# Collision
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36, 36)
	col.shape = shape
	col.position = Vector2(0, -18)
	add_child(col)

	# Crate visual - amber box
	crate_rect = ColorRect.new()
	crate_rect.size = Vector2(36, 36)
	crate_rect.position = Vector2(-18, -36)
	crate_rect.color = RESOURCE_COLORS.get(resource_type, Color("#E8A020"))
	add_child(crate_rect)

	# Stripe detail
	var stripe := ColorRect.new()
	stripe.size = Vector2(36, 5)
	stripe.position = Vector2(-18, -24)
	stripe.color = Color(0, 0, 0, 0.3)
	add_child(stripe)

	# Interaction label
	prompt_label = Label.new()
	prompt_label.text = "[E] Search"
	prompt_label.position = Vector2(-28, -58)
	prompt_label.add_theme_color_override("font_color", Color("#ffd700"))
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.visible = false
	add_child(prompt_label)

	# Pulse tween
	var tween := create_tween().set_loops()
	tween.tween_property(crate_rect, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(crate_rect, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
		prompt_label.visible = true
		emit_signal("player_entered_range")

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		prompt_label.visible = false
		emit_signal("player_exited_range")

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		var amount: float = AMOUNTS.get(resource_type, 20.0) as float
		emit_signal("collected", resource_type, amount)
		queue_free()
