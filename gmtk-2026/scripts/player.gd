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
	ATTACK,
	HURT
}

@export var walk_speed : float = 220.0
@export var sprint_speed : float = 320.0
@export var attack_frame: int = 3
@export var attack_range: float = 32.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D

var facing_direction: FacingDirection = FacingDirection.DOWN
var animation_state: AnimationState = AnimationState.IDLE
var is_attacking: bool = false
var is_sprinting: bool = false
var attack_has_hit: bool = false
var is_hurt: bool = false

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)

	play_animation(AnimationState.IDLE)

func _physics_process(_delta: float) -> void:
	update_input_states()
	handle_attack()
	handle_movement()
	
func update_input_states() -> void:
	is_sprinting = Input.is_action_pressed("Sprint")

func handle_attack() -> void:
	if (
		Input.is_action_just_pressed("Attack")
		and not is_attacking
		and not is_hurt
	):
		is_attacking = true
		attack_has_hit = false

		update_attack_hitbox_position()
		play_animation(AnimationState.ATTACK)

func update_attack_hitbox_position() -> void:
	match facing_direction:
		FacingDirection.DOWN:
			attack_hitbox.position = Vector2(0.0, attack_range)
			attack_hitbox.rotation = 0.0

		FacingDirection.UP:
			attack_hitbox.position = Vector2(0.0, -attack_range)
			attack_hitbox.rotation = 0.0

		FacingDirection.LEFT:
			attack_hitbox.position = Vector2(-attack_range, 0.0)
			attack_hitbox.rotation = 0.0

		FacingDirection.RIGHT:
			attack_hitbox.position = Vector2(attack_range, 0.0)
			attack_hitbox.rotation = 0.0
			
func _on_animation_frame_changed() -> void:
	if animation_state != AnimationState.ATTACK:
		return

	if animated_sprite.frame == attack_frame and not attack_has_hit:
		perform_attack()
		
func perform_attack() -> void:
	if attack_has_hit:
		return

	attack_has_hit = true

	for body in attack_hitbox.get_overlapping_bodies():
		var enemy: Node = find_enemy_from_node(body)

		if enemy != null:
			kill_enemy(enemy)


func find_enemy_from_node(node: Node) -> Node:
	var current_node: Node = node

	while current_node != null:
		if current_node.is_in_group("enemies"):
			return current_node

		current_node = current_node.get_parent()

	return null


func kill_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return

	if enemy.has_method("die"):
		enemy.call("die")
	else:
		enemy.queue_free()

func handle_movement() -> void:
	var input_direction: Vector2 = get_movement_input()
	var current_speed: float = walk_speed

	if is_sprinting and not is_attacking and not is_hurt:
		current_speed = sprint_speed

	if is_hurt:
		velocity = Vector2.ZERO
	else:
		velocity = input_direction * current_speed

	move_and_slide()
	check_enemy_collisions()

	if is_attacking or is_hurt:
		return

	if input_direction == Vector2.ZERO:
		play_animation(AnimationState.IDLE)
		return

	update_facing_direction(input_direction)

	if is_sprinting:
		play_animation(AnimationState.SPRINT)
	else:
		play_animation(AnimationState.WALK)
		
func check_enemy_collisions() -> void:
	if is_hurt:
		return

	for collision_index in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(collision_index)
		var collider: Object = collision.get_collider()

		if collider is Node and collider.is_in_group("enemies"):
			take_hit()
			return
			
func take_hit() -> void:
	if is_hurt:
		return

	is_hurt = true
	is_attacking = false
	attack_has_hit = false
	velocity = Vector2.ZERO

	play_animation(AnimationState.HURT)

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
		AnimationState.HURT:
			return "hurt"
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
	match animation_state:
		AnimationState.ATTACK:
			is_attacking = false
			attack_has_hit = false

		AnimationState.HURT:
			is_hurt = false

		_:
			return

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
