extends CharacterBody2D

signal player_died
signal stats_changed(hunger: float, thirst: float, stamina: float, health: float)

@export var hunger: float = 100.0
@export var thirst: float = 100.0
@export var stamina: float = 100.0
@export var health: float = 100.0

# Difficulty scaling (set by World each stage transition)
@export var difficulty_stage: int = 1
@export var decay_multiplier: float = 1.0
var score_multiplier: float = 1.0

const WALK_SPEED: float = 160.0
const RUN_SPEED: float = 280.0
const JUMP_VELOCITY: float = -520.0
const GRAVITY: float = 980.0
const STAMINA_DRAIN: float = 30.0
const STAMINA_REGEN: float = 20.0
const HUNGER_DECAY: float = 1.0
const THIRST_DECAY: float = 1.5

var is_dead: bool = false
var bob_timer: float = 0.0
var body_rect: ColorRect
var start_x: float = 0.0

func _ready() -> void:
	start_x = global_position.x

	# Collision shape
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22, 40)
	col.shape = shape
	col.position = Vector2(0, -20)
	add_child(col)

	# Body visual (teal rectangle)
	body_rect = ColorRect.new()
	body_rect.size = Vector2(22, 40)
	body_rect.position = Vector2(-11, -40)
	body_rect.color = Color("#1AE0C8")
	add_child(body_rect)

	# Head
	var head := ColorRect.new()
	head.size = Vector2(18, 16)
	head.position = Vector2(-9, -56)
	head.color = Color("#1AE0C8").lightened(0.2)
	add_child(head)

	# Eyes
	var eye_l := ColorRect.new()
	eye_l.size = Vector2(4, 4)
	eye_l.position = Vector2(-6, -52)
	eye_l.color = Color("#1a1a2e")
	add_child(eye_l)

	var eye_r := ColorRect.new()
	eye_r.size = Vector2(4, 4)
	eye_r.position = Vector2(2, -52)
	eye_r.color = Color("#1a1a2e")
	add_child(eye_r)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	var is_running := Input.is_action_pressed("run") and stamina > 0.0
	var speed := RUN_SPEED if is_running else WALK_SPEED

	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 2.0 * delta)

	# Stamina management
	if is_running and direction != 0.0:
		stamina = max(0.0, stamina - STAMINA_DRAIN * delta)
	else:
		stamina = min(100.0, stamina + STAMINA_REGEN * delta)

	move_and_slide()

func _process(delta: float) -> void:
	if is_dead:
		return

	# Stat decay — scaled by current difficulty multiplier
	hunger = max(0.0, hunger - HUNGER_DECAY * decay_multiplier * delta)
	thirst = max(0.0, thirst - THIRST_DECAY * decay_multiplier * delta)

	# Death check
	if hunger <= 0.0 or thirst <= 0.0:
		_die()
		return

	# Walk bob animation
	if abs(velocity.x) > 10.0 and is_on_floor():
		bob_timer += delta * 10.0
		body_rect.position.y = -40.0 + sin(bob_timer) * 3.0
	else:
		bob_timer = 0.0
		body_rect.position.y = -40.0

	emit_signal("stats_changed", hunger, thirst, stamina, health)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	# Tint red on death
	body_rect.color = Color("#e94560")
	emit_signal("player_died")

func apply_stat_change(stat: String, amount: float) -> void:
	match stat:
		"food":
			hunger = clamp(hunger + amount, 0.0, 100.0)
		"water":
			thirst = clamp(thirst + amount, 0.0, 100.0)
		"health":
			health = clamp(health + amount, 0.0, 100.0)
		"stamina":
			stamina = clamp(stamina + amount, 0.0, 100.0)

func get_distance() -> float:
	return (global_position.x - start_x) / 100.0  # in "meters"
