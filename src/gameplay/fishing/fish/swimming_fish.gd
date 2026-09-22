class_name SwimmingFish
extends CharacterBody2D

@export var swim_speed: float = 50.0
@export var left_boundary: float = 50.0
@export var right_boundary: float = 500.0

@onready var sprite: Sprite2D = $Sprite2D

var swim_direction: Vector2 = Vector2.RIGHT
var vertical_offset: float = 0.0
var swim_time: float = 0.0


func _physics_process(delta: float) -> void:
	swim_time += delta

	# Gentle up-and-down swimming motion
	vertical_offset = sin(swim_time * 2.0) * 10.0

	velocity.x = swim_direction.x * swim_speed
	velocity.y = vertical_offset

	move_and_slide()

	if global_position.x >= right_boundary:
		swim_direction = Vector2.LEFT
	elif global_position.x <= left_boundary:
		swim_direction = Vector2.RIGHT

	_update_facing_direction()


func _update_facing_direction() -> void:
	if swim_direction.x > 0:
		sprite.flip_h = false
	elif swim_direction.x < 0:
		sprite.flip_h = true
