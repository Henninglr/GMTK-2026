class_name TimeComponent
extends Node

signal time_changed(current_time: float, maximum_time: float)
signal time_depleted

@export var starting_time: float = 120.0
@export var maximum_time: float = 120.0
@export var countdown_enabled: bool = true

var current_time: float


func _ready() -> void:
	current_time = clamp(starting_time, 0.0, maximum_time)
	time_changed.emit(current_time, maximum_time)


func _process(delta: float) -> void:
	if not countdown_enabled:
		return

	remove_time(delta)


func add_time(amount: float) -> void:
	if amount <= 0.0:
		return

	current_time = min(current_time + amount, maximum_time)
	time_changed.emit(current_time, maximum_time)


func remove_time(amount: float) -> void:
	if amount <= 0.0 or current_time <= 0.0:
		return

	current_time = max(current_time - amount, 0.0)
	time_changed.emit(current_time, maximum_time)

	if current_time <= 0.0:
		countdown_enabled = false
		time_depleted.emit()


func has_enough_time(amount: float) -> bool:
	return current_time >= amount


func spend_time(amount: float) -> bool:
	if amount <= 0.0:
		return true

	if not has_enough_time(amount):
		return false

	remove_time(amount)
	return true


func pause_countdown() -> void:
	countdown_enabled = false


func resume_countdown() -> void:
	if current_time > 0.0:
		countdown_enabled = true
