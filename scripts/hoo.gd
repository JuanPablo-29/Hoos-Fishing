class_name  Player
extends CharacterBody2D
@export var speed : float = 500
var direction : Vector2
var wallet := PlayerWallet.new()

# Testing for hootbar visual
var inventory := PlayerInventory.new()
var equipped_rod: FishingRod
@export var start_with_demo_inventory: bool = true



@export var wallet_ui: Control

class ItemData:
	var item: Resource
	var slot: int
var current_item: ItemData

func _ready() -> void:
	wallet.balance = 5000
	
	# Fake Data Test
	var rod: FishingRod = preload("res://src/gameplay/fishing/rods/basic_rod.tres")
	wallet.add_rod(rod)
	equipped_rod = rod
	inventory.add_item(rod)
	
	if start_with_demo_inventory:
		inventory.add_item(preload("res://src/gameplay/fishing/fish/bluegill.tres"), 5)
		inventory.add_item(preload("res://src/gameplay/fishing/fish/bass.tres"), 3)

func _process(delta: float) -> void:
	wallet_ui.get_child(0).text = "$%d" % wallet.balance

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _physics_process(delta) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	#direction.y = Input.get_axis("move_up", "move_down")
	
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

### Get distance from player
func get_distance(pos: Vector2) -> float:
	return global_position.distance_to(pos)
