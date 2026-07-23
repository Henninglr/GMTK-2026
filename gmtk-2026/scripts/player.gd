class_name Player
extends CharacterBody2D

enum FacingDirection {
	DOWN,
	LEFT,
	RIGHT,
	UP
}

enum AnimationState {
	IDLE,
	WALK,
	SPRINT,
	ATTACK
}

@export var walk_speed : float = 220.0
@export var sprint_speed : float = 320.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var facing_direction: FacingDirection = FacingDirection.DOWN
var animation_state: AnimationState = AnimationState.IDLE
var is_attacking: bool = false
var is_sprinting: bool = false

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	play_animation(AnimationState.IDLE)

func _physics_process(_delta: float) -> void:
	update_input_states()
	handle_attack()
	handle_movement()
	
func update_input_states() -> void:
	is_sprinting = Input.is_action_pressed("Sprint")

func handle_attack() -> void:
	if Input.is_action_just_pressed("Attack") and not is_attacking:
		is_attacking = true
		play_animation(AnimationState.ATTACK)

func handle_movement() -> void:
	var input_direction: Vector2 = get_movement_input()
	var current_speed: float = walk_speed

	if is_sprinting:
		current_speed = sprint_speed

	velocity = input_direction * current_speed
	move_and_slide()

	if is_attacking:
		return

	if input_direction == Vector2.ZERO:
		play_animation(AnimationState.IDLE)
		return

	update_facing_direction(input_direction)

	if is_sprinting:
		play_animation(AnimationState.SPRINT)
	else:
		play_animation(AnimationState.WALK)

func update_facing_direction(input_direction: Vector2) -> void:
	if abs(input_direction.x) > abs(input_direction.y):
		facing_direction = (
			FacingDirection.RIGHT
			if input_direction.x > 0
			else FacingDirection.LEFT
		)
	else:
		facing_direction = (
			FacingDirection.DOWN
			if input_direction.y > 0
			else FacingDirection.UP
		)

func play_animation(new_state: AnimationState) -> void:
	animation_state = new_state

	var animation_name: String = (
		get_animation_state_name(animation_state)
		+ "_"
		+ get_facing_direction_name(facing_direction)
	)
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func get_animation_state_name(state: AnimationState) -> String:
	match state:
		AnimationState.IDLE:
			return "idle"
		AnimationState.WALK:
			return "walk"
		AnimationState.SPRINT:
			return "sprint"
		AnimationState.ATTACK:
			return "attack"
	return "idle"

func get_facing_direction_name(direction: FacingDirection) -> String:
	match direction:
		FacingDirection.DOWN:
			return "down"
		FacingDirection.LEFT:
			return "left"
		FacingDirection.RIGHT:
			return "right"
		FacingDirection.UP:
			return "up"
	return "down"

func _on_animation_finished() -> void:
	if animation_state != AnimationState.ATTACK:
		return

	is_attacking = false

	if velocity == Vector2.ZERO:
		play_animation(AnimationState.IDLE)
	elif is_sprinting:
		play_animation(AnimationState.SPRINT)
	else:
		play_animation(AnimationState.WALK)

func get_movement_input() -> Vector2:
	return Input.get_vector(
		"Left",
		"Right",
		"Up",
		"Down"
	)
