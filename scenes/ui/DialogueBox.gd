extends CanvasLayer

signal choice_made(choice_index: int)

@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $DialoguePanel
@onready var name_label: Label = $DialoguePanel/ContentBox/NameLabel
@onready var dialogue_label: Label = $DialoguePanel/ContentBox/DialogueLabel
@onready var button_container: VBoxContainer = $DialoguePanel/ContentBox/ButtonContainer

var is_visible_box: bool = false

# Centered offset_top when panel is fully visible
const PANEL_CENTER_OFFSET_TOP: float = -200.0
# Starting offset_top for slide-in (panel below screen)
const PANEL_HIDDEN_OFFSET_TOP: float = 500.0

func _ready() -> void:
	_apply_panel_style()
	hide_box()

func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0d0d1e")
	style.border_color = Color("#e94560")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

func show_for_npc(npc_name: String, archetype: String) -> void:
	if is_visible_box:
		return
	is_visible_box = true

	# Clear old buttons
	for child in button_container.get_children():
		child.queue_free()

	name_label.text = npc_name
	var choices: Array = []

	match archetype:
		"Merchant":
			dialogue_label.text = "\"Got supplies. Nothing comes free out here.\""
			choices = ["Trade water (-20) for food (+30)", "No thanks"]
		"Wanderer":
			dialogue_label.text = "\"Saw a cache east of here... take this, traveler.\""
			choices = ["Accept tip (+10 food)", "Ignore"]
		"Hostile":
			dialogue_label.text = "\"This stretch is mine. You want through? Pay up.\""
			choices = ["Give food (-20 food, they let you pass)", "Refuse (blocked 3s)"]

	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = choices[i]
		btn.add_theme_font_size_override("font_size", 12)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("#1a1a3a")
		btn_style.border_color = Color("#e94560")
		btn_style.border_width_bottom = 1
		btn_style.border_width_top = 1
		btn_style.border_width_left = 1
		btn_style.border_width_right = 1
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_color_override("font_color", Color("#e8e8ff"))

		var idx := i
		btn.pressed.connect(func(): _on_choice(idx))
		button_container.add_child(btn)

	# Slide-in animation: start below screen, tween up to center
	panel.offset_top = PANEL_HIDDEN_OFFSET_TOP
	panel.offset_bottom = PANEL_HIDDEN_OFFSET_TOP + 400.0

	overlay.visible = true
	panel.visible = true

	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(panel, "offset_top", PANEL_CENTER_OFFSET_TOP, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "offset_bottom", PANEL_CENTER_OFFSET_TOP + 400.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_choice(index: int) -> void:
	hide_box()
	emit_signal("choice_made", index)

func hide_box() -> void:
	is_visible_box = false
	panel.visible = false
	overlay.visible = false
