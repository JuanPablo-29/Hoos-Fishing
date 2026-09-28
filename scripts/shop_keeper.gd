extends Node2D
var player: Player
@export var sprite: ColorRect
@export var button: Button
var close_enough: bool = false
var shop_ui: Control
@onready var shop_ui_path: String = "res://scenes/ShopUI.tscn"
var shop:= Shop.new()

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
	if player.velocity.x != 0 && shop_ui:
		shop_ui.queue_free()
		
	

func _on_button_pressed() -> void:
	if !shop_ui:
		shop_ui = SceneLoader.spawn(shop_ui_path, "Hud")
		shop_ui.get_node("ColorRect/CenterContainer/Container/Buy").pressed.connect(_on_buy_pressed)
		shop_ui.get_node("ColorRect/CenterContainer/Container/Sell").pressed.connect(_on_sell_pressed)

# Needs to take in type Fish and use fish.sell_value, place holder 10
func sell_fish(wallet: PlayerWallet):
	wallet.add_money(10)


func _on_buy_pressed() -> void:
	player.wallet.spend_money(10)
	print(player.wallet.balance)

func _on_sell_pressed() -> void:
	sell_fish(player.wallet)
	print(player.wallet.balance)
