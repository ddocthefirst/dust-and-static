extends Node2D

const SupplyCrateScene := preload("res://scenes/world/SupplyCrate.tscn")
const SurvivorScene := preload("res://scenes/npcs/Survivor.tscn")

# ── Difficulty stage config ────────────────────────────────────────────────
# Each entry: [decay_mult, score_mult, crate_gap_min, crate_gap_max, bg_scroll_mult]
const STAGE_DATA := {
	1: { "name": "CALM",   "color": Color("#00ff88"), "decay_mult": 1.0, "score_mult": 1.0,
	     "crate_gap_min": 250, "crate_gap_max": 400,  "scroll_mult": 1.0 },
	2: { "name": "TENSE",  "color": Color("#ffd700"), "decay_mult": 1.5, "score_mult": 2.0,
	     "crate_gap_min": 350, "crate_gap_max": 550,  "scroll_mult": 1.2 },
	3: { "name": "HARSH",  "color": Color("#ff8800"), "decay_mult": 2.2, "score_mult": 3.5,
	     "crate_gap_min": 500, "crate_gap_max": 750,  "scroll_mult": 1.5 },
	4: { "name": "BRUTAL", "color": Color("#ff2640"), "decay_mult": 3.5, "score_mult": 6.0,
	     "crate_gap_min": 700, "crate_gap_max": 1000, "scroll_mult": 2.0 },
}

func _get_stage(t: float) -> int:
	if t < 60.0:  return 1
	if t < 180.0: return 2
	if t < 360.0: return 3
	return 4

var player: CharacterBody2D
var hud: CanvasLayer
var dialogue_box: CanvasLayer
var death_screen: CanvasLayer
var camera: Camera2D

# Spawn tracking
var ground_spawn_x: float = 0.0
var next_platform_x: float = 400.0
var next_crate_x: float = 0.0
var next_survivor_x: float = 0.0

# Object lists for despawning
var platforms: Array = []
var crates: Array = []
var survivors: Array = []

# Stats / difficulty
var time_survived: float = 0.0
var game_over: bool = false
var difficulty_stage: int = 1
var score: float = 0.0

# Hostile block timer
var block_timer: float = 0.0
var player_blocked: bool = false

const GROUND_Y: float = 500.0
const DESPAWN_DIST: float = 1200.0
const INITIAL_WORLD_WIDTH: float = 2000.0

func _ready() -> void:
	randomize()

	# Get sibling nodes from parent (Main)
	player = get_parent().get_node_or_null("Player")
	hud = get_parent().get_node_or_null("HUD")
	dialogue_box = get_parent().get_node_or_null("DialogueBox")
	death_screen = get_parent().get_node_or_null("DeathScreen")

	# Setup camera
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.zoom = Vector2(1.0, 1.0)
	# Constrain camera so player can't see above sky or below ground
	camera.limit_top = -300
	camera.limit_bottom = 620
	camera.limit_left = -100000
	camera.limit_right = 100000
	add_child(camera)

	# Connect player signals
	if player:
		player.player_died.connect(_on_player_died)
		next_crate_x = player.global_position.x + randi_range(400, 800)
		next_survivor_x = player.global_position.x + randi_range(800, 1200)

	# Connect dialogue
	if dialogue_box:
		dialogue_box.choice_made.connect(_on_dialogue_choice)

	# Generate initial world
	_generate_ground(0.0, INITIAL_WORLD_WIDTH)
	ground_spawn_x = INITIAL_WORLD_WIDTH

	# Add parallax background
	_build_background()

func _build_background() -> void:
	# Dark sky / wasteland background
	var bg := ColorRect.new()
	bg.size = Vector2(100000, 720)
	bg.position = Vector2(-10000, 0)
	bg.color = Color("#1a1a2e")
	bg.z_index = -10
	add_child(bg)

	# Distant "ruins" silhouette layer — just rectangles
	for i in range(80):
		var ruin := ColorRect.new()
		var w := randi_range(20, 60)
		var h := randi_range(40, 160)
		ruin.size = Vector2(w, h)
		ruin.position = Vector2(i * 120 - 200, GROUND_Y - h)
		ruin.color = Color(0.12, 0.1, 0.18)
		ruin.z_index = -5
		add_child(ruin)

func _physics_process(delta: float) -> void:
	if game_over:
		return

	time_survived += delta

	# ── Difficulty stage update ──────────────────────────────────────────
	var new_stage := _get_stage(time_survived)
	if new_stage != difficulty_stage:
		difficulty_stage = new_stage
		_apply_stage(difficulty_stage)

	if player_blocked:
		block_timer -= delta
		if block_timer <= 0.0:
			player_blocked = false
			if player:
				player.is_dead = false  # re-enable movement

func _apply_stage(stage: int) -> void:
	var cfg: Dictionary = STAGE_DATA[stage]
	if player:
		player.difficulty_stage   = stage
		player.decay_multiplier   = cfg["decay_mult"]
		player.score_multiplier   = cfg["score_mult"]
	if hud:
		hud.update_stage(stage, cfg["name"], cfg["color"])

func _process(delta: float) -> void:
	if game_over or not player:
		return

	var px: float = player.global_position.x

	# Camera follow
	camera.global_position = Vector2(
		lerp(camera.global_position.x, player.global_position.x, delta * 5.0),
		lerp(camera.global_position.y, player.global_position.y - 60.0, delta * 3.0)
	)

	# Extend ground as player moves right
	while ground_spawn_x < px + 1600.0:
		_generate_ground(ground_spawn_x, ground_spawn_x + 400.0)
		ground_spawn_x += 400.0

	# Spawn elevated platforms
	while next_platform_x < px + 1200.0:
		_spawn_platform(next_platform_x)
		next_platform_x += randi_range(200, 400)

	# Spawn crates (gap widens each stage)
	var cfg: Dictionary = STAGE_DATA[difficulty_stage]
	while next_crate_x < px + 1000.0:
		_spawn_crate(next_crate_x)
		next_crate_x += randi_range(cfg["crate_gap_min"], cfg["crate_gap_max"])

	# Spawn survivors
	while next_survivor_x < px + 1000.0:
		_spawn_survivor(next_survivor_x)
		next_survivor_x += randi_range(800, 1200)

	# Despawn old objects
	_despawn_old(px)

	# Score: (distance×0.1 + time×0.5) × score_multiplier
	var dist: float = player.get_distance()
	var smult: float = float(STAGE_DATA[difficulty_stage]["score_mult"])
	score = (dist * 0.1 + time_survived * 0.5) * smult

	# Update HUD
	if hud:
		hud.update_distance(dist)
		hud.update_time(time_survived)
		hud.update_score(score)

func _generate_ground(from_x: float, to_x: float) -> void:
	var platform := _create_platform(
		Vector2(from_x + (to_x - from_x) / 2.0, GROUND_Y + 20.0),
		Vector2(to_x - from_x + 4.0, 40.0),
		Color("#2a2a3e")
	)
	platforms.append(platform)

func _spawn_platform(x: float) -> void:
	var w: float = randi_range(80, 200)
	var y: float = GROUND_Y - randi_range(80, 200)
	var platform := _create_platform(
		Vector2(x, y),
		Vector2(w, 18.0),
		Color("#3a2a4e")
	)
	# Accent stripe
	var stripe := ColorRect.new()
	stripe.size = Vector2(w, 3)
	stripe.position = Vector2(-w / 2.0, -9)
	stripe.color = Color("#e94560").darkened(0.4)
	platform.add_child(stripe)
	platforms.append(platform)

func _create_platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var rect := ColorRect.new()
	rect.size = size
	rect.position = Vector2(-size.x / 2.0, -size.y / 2.0)
	rect.color = color
	body.add_child(rect)

	add_child(body)
	return body

func _spawn_crate(x: float) -> void:
	var types := ["food", "water", "medicine", "fuel"]
	var crate: Area2D = SupplyCrateScene.instantiate()
	crate.resource_type = types[randi() % types.size()]
	# Place on nearest ground or platform — default to ground level
	crate.position = Vector2(x, GROUND_Y - 1.0)
	add_child(crate)
	crate.collected.connect(_on_crate_collected)
	crate.player_entered_range.connect(func(): _on_interactable_enter("[E] Search"))
	crate.player_exited_range.connect(_on_interactable_exit)
	crates.append(crate)

func _spawn_survivor(x: float) -> void:
	var survivor: CharacterBody2D = SurvivorScene.instantiate()
	survivor.position = Vector2(x, GROUND_Y - 1.0)
	add_child(survivor)
	survivor.interact_requested.connect(_on_survivor_interact)
	survivor.player_entered_range.connect(func(): _on_interactable_enter("[E] Talk"))
	survivor.player_exited_range.connect(_on_interactable_exit)
	survivors.append(survivor)

func _on_interactable_enter(prompt: String) -> void:
	if hud:
		hud.show_prompt(prompt)

func _on_interactable_exit() -> void:
	if hud:
		hud.hide_prompt()

func _on_crate_collected(resource_type: String, amount: float) -> void:
	if not player:
		return
	match resource_type:
		"food":
			player.apply_stat_change("food", amount)
		"water":
			player.apply_stat_change("water", amount)
		"medicine":
			player.apply_stat_change("health", amount)
		"fuel":
			player.apply_stat_change("stamina", amount)
	if hud:
		hud.hide_prompt()

# Current survivor being interacted with
var _current_survivor: CharacterBody2D = null

func _on_survivor_interact(survivor: CharacterBody2D) -> void:
	if dialogue_box and dialogue_box.is_visible_box:
		return
	_current_survivor = survivor
	if dialogue_box:
		dialogue_box.show_for_npc(survivor.display_name, survivor.archetype)
	if hud:
		hud.hide_prompt()

func _on_dialogue_choice(index: int) -> void:
	if not _current_survivor or not player:
		_current_survivor = null
		return

	match _current_survivor.archetype:
		"Merchant":
			if index == 0:
				player.apply_stat_change("water", -20.0)
				player.apply_stat_change("food", 30.0)
		"Wanderer":
			if index == 0:
				player.apply_stat_change("food", 10.0)
		"Hostile":
			if index == 0:
				player.apply_stat_change("food", -20.0)
			elif index == 1:
				# Block player movement for 3 seconds
				_block_player(3.0)

	_current_survivor = null

func _block_player(duration: float) -> void:
	if not player:
		return
	player_blocked = true
	block_timer = duration
	player.is_dead = true  # re-use is_dead to disable movement temporarily

func _on_player_died() -> void:
	game_over = true
	if death_screen:
		var dist: float = player.get_distance() if player else 0.0
		death_screen.show_screen(time_survived, dist, score)

func _despawn_old(player_x: float) -> void:
	var cutoff := player_x - DESPAWN_DIST

	for obj in platforms.duplicate():
		if is_instance_valid(obj) and obj.position.x < cutoff:
			obj.queue_free()
			platforms.erase(obj)

	for obj in crates.duplicate():
		if is_instance_valid(obj) and obj.position.x < cutoff:
			obj.queue_free()
			crates.erase(obj)

	for obj in survivors.duplicate():
		if is_instance_valid(obj) and obj.position.x < cutoff:
			obj.queue_free()
			survivors.erase(obj)
