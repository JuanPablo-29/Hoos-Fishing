class_name SwimmingFish
extends CharacterBody2D

@export var swim_speed: float = 50.0
@export var left_boundary: float = 50.0
@export var right_boundary: float = 500.0
@export var top_boundary: float = 200.0
@export var bottom_boundary: float = 600.0

@onready var sprite: Sprite2D = $Sprite2D

var swim_direction: Vector2 = Vector2.RIGHT
var vertical_offset: float = 0.0
var swim_time: float = 0.0

@export var min_turn_time: float = 2.0
@export var max_turn_time: float = 5.0

var turn_timer: float = 0.0

func _physics_process(delta: float) -> void:
	swim_time += delta
	turn_timer -= delta

	if turn_timer <= 0.0:
		swim_direction.x *= -1
		_reset_turn_timer()

	# Gentle up-and-down swimming motion
	vertical_offset = sin(swim_time * 2.0) * 10.0

	velocity.x = swim_direction.x * swim_speed
	velocity.y = vertical_offset

	move_and_slide()
	
	if global_position.y <= top_boundary:
		global_position.y = top_boundary
		swim_time = 0.0

	elif global_position.y >= bottom_boundary:
		global_position.y = bottom_boundary
		swim_time = 0.0

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
		
func _reset_turn_timer() -> void:
	turn_timer = randf_range(min_turn_time, max_turn_time)
	
func _ready() -> void:
	_reset_turn_timer()
