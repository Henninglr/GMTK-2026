extends Control

@export_file("*.tscn") var game_scene_path: String
@export_file("*.tscn") var main_menu_scene_path: String


func _ready() -> void:
	$GameOverUI/CenterContainer/VBoxContainer/RetryButton.pressed.connect(
		_on_retry_button_pressed
	)

	$GameOverUI/CenterContainer/VBoxContainer/MainMenuButton.pressed.connect(
		_on_main_menu_button_pressed
	)

	$GameOverUI/CenterContainer/VBoxContainer/QuitButton.pressed.connect(
		_on_quit_button_pressed
	)


func _on_retry_button_pressed() -> void:
	if game_scene_path.is_empty():
		push_warning("No game scene has been assigned.")
		return

	get_tree().change_scene_to_file(game_scene_path)


func _on_main_menu_button_pressed() -> void:
	if main_menu_scene_path.is_empty():
		push_warning("No main menu scene has been assigned.")
		return

	get_tree().change_scene_to_file(main_menu_scene_path)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
