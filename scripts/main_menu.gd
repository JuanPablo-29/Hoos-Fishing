extends Control

func _ready() -> void:
	$MenuPanel/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$MenuPanel/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
