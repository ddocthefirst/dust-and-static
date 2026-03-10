extends CanvasLayer

signal choice_made(choice_index: int)

var panel: Panel
var name_label: Label
var dialogue_label: Label
var button_container: VBoxContainer
var is_visible_box: bool = false

func _ready() -> void:
	_build_ui()
	hide_box()

func _build_ui() -> void:
	# Dark overlay
	var overlay := ColorRect.new()
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0, 0, 0, 0.5)
	add_child(overlay)

	# Panel
	panel = Panel.new()
	panel.size = Vector2(520, 260)
	panel.position = Vector2((1280 - 520) / 2.0, (720 - 260) / 2.0)

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
	add_child(panel)

	# NPC name
	name_label = Label.new()
	name_label.position = Vector2(20, 16)
	name_label.size = Vector2(480, 28)
	name_label.add_theme_color_override("font_color", Color("#e94560"))
	name_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(name_label)

	# Dialogue text
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(20, 52)
	dialogue_label.size = Vector2(480, 60)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_color_override("font_color", Color("#ccccee"))
	dialogue_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(dialogue_label)

	# Button container
	button_container = VBoxContainer.new()
	button_container.position = Vector2(20, 128)
	button_container.size = Vector2(480, 120)
	button_container.add_theme_constant_override("separation", 8)
	panel.add_child(button_container)

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

	# Slide-in animation
	panel.position.y = 800.0
	var target_y := (720.0 - 260.0) / 2.0
	var tween := create_tween()
	tween.tween_property(panel, "position:y", target_y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	panel.visible = true
	# Show the overlay too
	get_child(0).visible = true

func _on_choice(index: int) -> void:
	hide_box()
	emit_signal("choice_made", index)

func hide_box() -> void:
	is_visible_box = false
	panel.visible = false
	if get_child_count() > 0:
		get_child(0).visible = false
