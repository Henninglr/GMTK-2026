class_name Player
extends CharacterBody2D

## Movement speed in pixels per second.
@export var move_speed: float = 220.0

func _physics_process(_delta: float) -> void:
	handle_movement()

func handle_movement() -> void:
	var input_direction: Vector2 = get_movement_input()

	velocity = input_direction * move_speed
	move_and_slide()

func get_movement_input() -> Vector2:
	return Input.get_vector(
		"Left",
		"Right",
		"Up",
		"Down"
	)
