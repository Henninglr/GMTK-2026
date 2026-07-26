extends CharacterBody2D

@export var SPEED = 30.0
@export var MIN_MOVE_SPEED_FOR_ANIM = 28
@export var MIN_DISTANCE_TO_PLAYER = 28
@export var DETECTION_RANGE = 100
@export var ATTACK_RANGE = 50
@export var ATTACK_COOLDOWN = 2
enum Directions {LEFT, RIGHT, UP, DOWN}
var facing_direction = Directions.DOWN
var player_ref
var is_attacking = false
var attack_cooldown = 0

func attack(delta: float) -> void:
	if not is_attacking:
		is_attacking = true
		$Sprite.play("attack_down")
		$SlimeAttack.trigger_aoe()
		attack_cooldown = ATTACK_COOLDOWN

func _ready() -> void:
	$Sprite.play("idle_down")
	# store the player node 
	player_ref = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	#print(velocity)
	
	var player_pcsition = player_ref.get_position()
	var distance_to_player = position.distance_to(player_pcsition)
	
	# Update the sprite
	
	# If moving
	if velocity.length() > MIN_MOVE_SPEED_FOR_ANIM and not is_attacking:
		var angle = atan2(velocity.y, velocity.x) # angle in [-PI, PI]
		if abs(angle) < 0.25 * PI:
			$Sprite.play("walk_right")
			facing_direction = Directions.RIGHT
		elif abs(angle) > 0.75 * PI:
			$Sprite.play("walk_left")
			facing_direction = Directions.LEFT
		elif angle > 0.0:
			$Sprite.play("walk_down")
			facing_direction = Directions.DOWN
		else:
			$Sprite.play("walk_up")
			facing_direction = Directions.UP
	#If still
	elif not is_attacking:
		match facing_direction:
			Directions.UP:
				$Sprite.play("idle_up")
			Directions.DOWN:
				$Sprite.play("idle_down")
			Directions.LEFT:
				$Sprite.play("idle_left")
			Directions.RIGHT:
				$Sprite.play("idle_right")
	
	if distance_to_player <= ATTACK_RANGE:
		attack(delta)
	
	# Check if finished any attacks attack
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			is_attacking = false
			$SlimeAttack/CollisionShape2D.disabled = true
	

func _physics_process(delta):
	# Calculate the direction to the player and normalize it
	var direction = global_position.direction_to(player_ref.get_position())
	
	# Move the enemy using move_and_slide
	if position.distance_to(player_ref.get_position()) > MIN_DISTANCE_TO_PLAYER and position.distance_to(player_ref.get_position()) <= DETECTION_RANGE:
		# Set the velocity and multiply by speed
		velocity = direction * SPEED
		move_and_slide()
	else:
		velocity = Vector2.ZERO
