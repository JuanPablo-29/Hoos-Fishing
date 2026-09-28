class_name  Player
extends CharacterBody2D
@export var speed : float = 500
var direction : Vector2
var wallet := PlayerWallet.new()
@export var wallet_ui: Control

func _ready() -> void:
	wallet.balance = 500

func _process(delta: float) -> void:
	wallet_ui.get_child(0).text = "$%d" % wallet.balance

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _physics_process(delta) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	
	if direction:
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	move_and_slide()
	update_animation()

func update_animation() -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	
	if direction != Vector2.ZERO:
		sprite.play("fly")
	else:
		sprite.play("idle")
