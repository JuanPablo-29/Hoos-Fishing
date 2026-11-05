
class_name Player
extends CharacterBody2D

@export var speed : float = 500
@export var start_with_demo_inventory: bool = false
@export var wallet_ui: Control

var direction : Vector2
var wallet := PlayerWallet.new()

var is_fishing := false

# Testing for hootbar visual
var inventory := PlayerInventory.new()
var catch_tracker := CatchTracker.new()
var task_board := TaskBoard.new()
var equipped_rod: FishingRod

class ItemData:
	var item: Resource
	var slot: int
var current_item: ItemData

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	# Each stored catch is reported to the task board once
	catch_tracker.fish_caught.connect(task_board.record_catch)

	wallet.balance = 0

	# Fake Data Test
	var rod: FishingRod = preload("res://src/gameplay/fishing/rods/basic_rod.tres")
	wallet.add_rod(rod)
	equipped_rod = rod
	inventory.add_item(rod)

	if start_with_demo_inventory:
		inventory.add_item(preload("res://src/gameplay/fishing/fish/bluegill.tres"), 5)
		inventory.add_item(preload("res://src/gameplay/fishing/fish/bass.tres"), 3)

func _process(delta: float) -> void:
	# Timed tasks continue while player is away from shop
	task_board.advance_time(delta)
	wallet_ui.get_child(0).text = "$%d" % wallet.balance

func _physics_process(delta) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	#direction.y = Input.get_axis("move_up", "move_down")

	if direction:
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	if !is_fishing:
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
