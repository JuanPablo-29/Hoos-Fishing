extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("Container/QuitButton").pressed.connect(_on_quit_pressed)
	get_node("Container/ResumeButton").pressed.connect(_on_resume_pressed)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_resume_pressed() -> void:
	toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
