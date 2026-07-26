extends Control

@export_file("*.tscn") var game_scene_path: String


func _ready() -> void:
	$MenuUI/CenterContainer/VBoxContainer/StartButton.pressed.connect(
		_on_start_button_pressed
	)

	$MenuUI/CenterContainer/VBoxContainer/ControlsButton.pressed.connect(
		_on_controls_button_pressed
	)

	$MenuUI/CenterContainer/VBoxContainer/QuitButton.pressed.connect(
		_on_quit_button_pressed
	)


func _on_start_button_pressed() -> void:
	if game_scene_path.is_empty():
		push_warning("No game scene has been assigned.")
		return

	get_tree().change_scene_to_file(game_scene_path)


func _on_controls_button_pressed() -> void:
	print("Controls button pressed")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
