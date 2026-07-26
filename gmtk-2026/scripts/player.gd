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
@export var camera_follow_speed := 8.0
@export var look_ahead_distance := 10.0
@export_category("Special Ability")
@export var ability_time_cost: float = 20.0
@export var ability_cooldown: float = 2.0
@export_category("Ability Visual")
@export var ability_visual_duration: float = 0.35
@export var ability_visual_colour: Color = Color(0.3, 0.7, 1.0, 0.45)
@export var ability_visual_segments: int = 48
@export var invulnerability_duration: float = 1.0

@export_file("*.tscn") var game_over_scene_path: String


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var time_component: Node = $TimeComponent
@onready var time_label: RichTextLabel = $UI/TimeLabel
@onready var camera_component: Camera2D = $Camera2D
@onready var ability_area: Area2D = $AbilityArea
@onready var ability_collision: CollisionShape2D = $AbilityArea/CollisionShape2D
@onready var ability_visual: Polygon2D = $AbilityVisual
@export var knockback_strength: float = 100.0
@export var knockback_duration: float = 0.15


var facing_direction: FacingDirection = FacingDirection.DOWN
var animation_state: AnimationState = AnimationState.IDLE
var is_attacking: bool = false
var is_sprinting: bool = false
var attack_has_hit: bool = false
var is_hurt: bool = false
var is_dead: bool = false
var ability_on_cooldown: bool = false
var is_invulnerable: bool = false
var is_being_knocked_back: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

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
	
	create_ability_visual()
	play_animation(AnimationState.IDLE)
	
	time_label.pivot_offset = time_label.size / 2.0
	
	# Assuming player starts with gameplay... start gameplay music
	SoundManager.play_music("gameplay")
func create_ability_visual() -> void:
	var circle_shape := ability_collision.shape as CircleShape2D

	if circle_shape == null:
		push_warning("AbilityArea requires a CircleShape2D.")
		return

	var points := PackedVector2Array()

	for index in range(ability_visual_segments):
		var angle := TAU * float(index) / float(ability_visual_segments)
		var point := Vector2(cos(angle), sin(angle)) * circle_shape.radius
		points.append(point)

	ability_visual.polygon = points
	ability_visual.color = ability_visual_colour
	ability_visual.scale = Vector2.ZERO
	ability_visual.visible = false
	
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
	
	
	# Sound cue
	SoundManager.play_sfx("player_death")
	
	if game_over_scene_path.is_empty():
		push_warning("No game-over scene has been assigned to the player.")
		return

	get_tree().change_scene_to_file(game_over_scene_path)
	
func _on_time_changed(current_time: float, _maximum_time: float) -> void:
	time_label.text = format_time(current_time)
	
func format_time(time_in_seconds: float) -> String:
	var total_seconds: int = max(ceil(time_in_seconds), 0)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60

	var text: String = "%02d:%02d" % [minutes, seconds]
	if is_hurt or is_sprinting:
		text = "[color=red][shake rate=15 level=30 color=red]" + text + "[/shake][/color]"

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
	handle_special_ability()
	handle_movement(delta)
	
func update_input_states() -> void:
	var sprint_pressed = Input.is_action_pressed("Sprint")
	if sprint_pressed and not is_sprinting:
		is_sprinting = true
		SoundManager.is_sprinting = true
	elif is_sprinting and not sprint_pressed:
		is_sprinting = false
		SoundManager.is_sprinting = false
		

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
		
func handle_special_ability() -> void:
	if not Input.is_action_just_pressed("SpecialAbility"):
		return

	if not can_use_special_ability():
		return

	use_special_ability()
	
func can_use_special_ability() -> bool:
	if is_dead:
		return false

	if is_hurt:
		return false

	if is_attacking:
		return false

	if ability_on_cooldown:
		return false

	return time_component.has_enough_time(ability_time_cost)
	
func use_special_ability() -> void:
	if not time_component.spend_time(ability_time_cost):
		return

	ability_on_cooldown = true

	play_ability_visual()
	perform_aoe_attack()
	start_ability_cooldown()
	
func play_ability_visual() -> void:
	ability_visual.visible = true
	ability_visual.scale = Vector2.ZERO
	ability_visual.modulate.a = 1.0

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		ability_visual,
		"scale",
		Vector2.ONE,
		ability_visual_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		ability_visual,
		"modulate:a",
		0.0,
		ability_visual_duration
	)

	tween.finished.connect(_on_ability_visual_finished)
	
func _on_ability_visual_finished() -> void:
	ability_visual.visible = false
	ability_visual.scale = Vector2.ZERO
	ability_visual.modulate.a = 1.0
	
func perform_aoe_attack() -> void:
	var enemies_hit: Array[Node] = []

	for body in ability_area.get_overlapping_bodies():
		var enemy: Node = find_enemy_from_node(body)

		if enemy == null:
			continue

		if enemy in enemies_hit:
			continue

		enemies_hit.append(enemy)

	for enemy in enemies_hit:
		kill_enemy(enemy)
		
func start_ability_cooldown() -> void:
	await get_tree().create_timer(ability_cooldown).timeout

	if not is_inside_tree():
		return

	ability_on_cooldown = false

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
	
	SoundManager.play_sfx("sword_attack")

	for body in attack_hitbox.get_overlapping_bodies():
		var enemy: Node = find_enemy_from_node(body)

		if enemy != null:
			kill_enemy(enemy)
			# Hit sound
			SoundManager.play_sfx("hit_slime")
			
		


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
	
	SoundManager.play_walk(animation_state == AnimationState.WALK or animation_state == AnimationState.SPRINT)

	if can_sprint:
		time_component.remove_time(sprint_time_cost_per_second * delta)

		if is_dead:
			velocity = Vector2.ZERO
			return
	
	if is_being_knocked_back:
		velocity = knockback_velocity
	elif is_hurt:
		velocity = Vector2.ZERO
	else:
		velocity = input_direction * current_speed

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
			take_hit(collider)
			return
			
func take_hit(enemy: Node2D) -> void:
	if is_hurt or is_dead or is_invulnerable:
		return

	is_hurt = true
	is_invulnerable = true
	is_attacking = false
	attack_has_hit = false

	var knockback_direction: Vector2 = enemy.global_position.direction_to(global_position)
	start_knockback(knockback_direction)

	time_component.remove_time(damage_time_loss)
	
	# Sound cue
	SoundManager.play_sfx("player_hurt")

	if is_dead:
		return

	play_animation(AnimationState.HURT)
	start_invulnerability()
	
func start_knockback(direction: Vector2) -> void:
	is_being_knocked_back = true
	knockback_velocity = direction * knockback_strength

	await get_tree().create_timer(knockback_duration).timeout

	if not is_inside_tree():
		return

	is_being_knocked_back = false
	knockback_velocity = Vector2.ZERO
	
func start_invulnerability() -> void:
	await get_tree().create_timer(invulnerability_duration).timeout

	if not is_inside_tree():
		return

	is_invulnerable = false

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
