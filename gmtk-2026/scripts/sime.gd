extends CharacterBody2D

@export var SPEED = 30.0
@export var MIN_MOVE_SPEED_FOR_ANIM = 28
@export var MIN_DISTANCE_TO_PLAYER = 28
@export var DETECTION_RANGE = 100
enum Directions {LEFT, RIGHT, UP, DOWN}
var facing_direction = Directions.DOWN
var player_ref

func _ready() -> void:
	$Sprite.play("idle_down")
	# store the player node 
	player_ref = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	#print(velocity)
	
	# Update the sprite
	
	# If moving
	if velocity.length() > MIN_MOVE_SPEED_FOR_ANIM:
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
	else:
		match facing_direction:
			Directions.UP:
				$Sprite.play("idle_up")
			Directions.DOWN:
				$Sprite.play("idle_down")
			Directions.LEFT:
				$Sprite.play("idle_left")
			Directions.RIGHT:
				$Sprite.play("idle_right")
	# stopped or almost stopped

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
