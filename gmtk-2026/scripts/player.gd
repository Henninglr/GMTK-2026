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
	HURT,
	DEATH
}

@export var walk_speed : float = 50.0
@export var sprint_speed : float = 150.0
@export var attack_frame: int = 3
@export var attack_range: float = 32.0
@export var damage_time_loss: float = 10.0
@export var enemy_kill_time_reward: float = 5.0
@export var sprint_time_cost_per_second: float = 2.0
@export var camera_follow_speed := 4.0
@export var look_ahead_distance := 20.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var time_component: Node = $TimeComponent
@onready var time_label: RichTextLabel = $UI/TimeLabel
@onready var camera_component: Camera2D = $Camera2D

var facing_direction: FacingDirection = FacingDirection.DOWN
var animation_state: AnimationState = AnimationState.IDLE
var is_attacking: bool = false
var is_sprinting: bool = false
var attack_has_hit: bool = false
var is_hurt: bool = false
var is_dead: bool = false

var pulse_time_remaining : float = 0.0
var is_pulsing : bool = false

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)
	
	time_component.time_changed.connect(_on_time_changed)
	time_component.time_depleted.connect(_on_time_depleted)
	
	_on_time_changed(
		time_component.current_time,
		time_component.maximum_time
	)

	play_animation(AnimationState.IDLE)
	
	time_label.pivot_offset = time_label.size / 2.0
	
func _on_time_depleted() -> void:
	die()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_hurt = false
	is_attacking = false
	is_sprinting = false
	attack_has_hit = false
	velocity = Vector2.ZERO

	time_component.pause_countdown()
	play_animation(AnimationState.DEATH)
	
func _on_time_changed(current_time: float, _maximum_time: float) -> void:
	time_label.text = format_time(current_time)
	
func format_time(time_in_seconds: float) -> String:
	var total_seconds: int = max(ceil(time_in_seconds), 0)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60

	var text: String = "%02d:%02d" % [minutes, seconds]
	if is_hurt:
		text =  "[shake rate=10 level=20]" + text + "[/shake]"

	return text
	
# Fade the time label to green
func start_pulse() -> void:
	is_pulsing = true

	var tween = create_tween()
	tween.parallel().tween_property(time_label, "scale", Vector2.ONE * 1.3, 0.1)
	tween.parallel().tween_property(time_label, "modulate", Color.LIME_GREEN, 0.1)

# Fade the time label back to white
func end_pulse() -> void:
	is_pulsing = false

	var tween = create_tween()
	tween.parallel().tween_property(time_label, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(time_label, "modulate", Color.WHITE, 0.2)

func _process(delta: float) -> void:
	if is_pulsing:
		pulse_time_remaining -= delta

		if pulse_time_remaining <= 0.0:
			end_pulse()
			
	# Update the camera position
	var camera_target: Vector2 = global_position + velocity.normalized() * look_ahead_distance
	camera_component.global_position = camera_component.global_position.lerp(camera_target, camera_follow_speed * delta)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	update_input_states()
	handle_attack()
	handle_movement(delta)
	
func update_input_states() -> void:
	is_sprinting = Input.is_action_pressed("Sprint")

func handle_attack() -> void:
	if (
		Input.is_action_just_pressed("Attack")
		and not is_attacking
		and not is_hurt
		and not is_dead
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

	pulse_time_remaining += 0.25
	start_pulse()
	time_component.add_time(enemy_kill_time_reward)


func handle_movement(delta: float) -> void:
	var input_direction: Vector2 = get_movement_input()

	var can_sprint: bool = (
		is_sprinting
		and input_direction != Vector2.ZERO
		and not is_attacking
		and not is_hurt
	)

	var current_speed: float = sprint_speed if can_sprint else walk_speed

	if is_hurt:
		velocity = Vector2.ZERO
	else:
		velocity = input_direction * current_speed

	if can_sprint:
		time_component.remove_time(sprint_time_cost_per_second * delta)

		if is_dead:
			velocity = Vector2.ZERO
			return

	move_and_slide()
	check_enemy_collisions()

	if is_attacking or is_hurt or is_dead:
		return

	if input_direction == Vector2.ZERO:
		play_animation(AnimationState.IDLE)
		return

	update_facing_direction(input_direction)

	if can_sprint:
		play_animation(AnimationState.SPRINT)
	else:
		play_animation(AnimationState.WALK)
		
func check_enemy_collisions() -> void:
	if is_hurt or is_dead:
		return

	for collision_index in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(collision_index)
		var collider: Object = collision.get_collider()

		if collider is Node and collider.is_in_group("enemies"):
			take_hit()
			return
			
func take_hit() -> void:
	if is_hurt or is_dead:
		return

	is_hurt = true
	is_attacking = false
	attack_has_hit = false
	velocity = Vector2.ZERO

	time_component.remove_time(damage_time_loss)

	if is_dead:
		return

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
		AnimationState.DEATH:
			return "death"
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

		AnimationState.DEATH:
			_on_death_animation_finished()
			return

		_:
			return

	if is_dead:
		return

	if velocity == Vector2.ZERO:
		play_animation(AnimationState.IDLE)
	elif is_sprinting:
		play_animation(AnimationState.SPRINT)
	else:
		play_animation(AnimationState.WALK)
		
func _on_death_animation_finished() -> void:
	print("Player died.")

func get_movement_input() -> Vector2:
	return Input.get_vector(
		"Left",
		"Right",
		"Up",
		"Down"
	)
