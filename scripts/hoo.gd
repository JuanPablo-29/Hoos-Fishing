class_name  Player
extends CharacterBody2D
@export var speed : float = 500
var direction : Vector2

func _physics_process(delta) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	#direction.y = Input.get_axis("move_up", "move_down")
	
	if direction:
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	move_and_slide()
