extends CharacterBody2D

@export var SPEED = 200.0
var MIN_MOVE_SPEED_FOR_ANIM = 10
enum Directions {LEFT, RIGHT, UP, DOWN}
var facing_direction = Directions.DOWN

func _ready() -> void:
	$Sprite.play("idle_down")

func _process(delta: float) -> void:
	print(velocity)
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
	# Get the mouse's current global position
	var mouse_pos = get_global_mouse_position()
	
	# Calculate the direction to the mouse and normalize it
	var direction = global_position.direction_to(mouse_pos)
	
	
	
	# Move the enemy using move_and_slide
	if position.distance_to(mouse_pos) > 10:
		# Set the velocity and multiply by speed
		velocity = direction * SPEED
		move_and_slide()
	else:
		velocity = Vector2.ZERO
