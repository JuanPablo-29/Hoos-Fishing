extends Node2D
var player: Player
@export var sprite: ColorRect
@export var button: Button
var close_enough: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var distance = global_position.distance_to(player.global_position)
	if distance <= 70:
		sprite.color = Color.BEIGE
		close_enough = true
	else:
		sprite.color = Color.BROWN
		close_enough = false
	button.disabled = !close_enough



func _on_button_pressed() -> void:
	print("pressed!")
