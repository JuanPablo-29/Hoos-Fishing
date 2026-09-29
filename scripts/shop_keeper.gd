extends Node2D
var player: Player
@export var sprite: ColorRect
@export var button: Button
var close_enough: bool = false
var shop_ui: Control
@onready var shop_ui_path: String = "res://scenes/ShopUI.tscn"
var shop:= Shop.new()
var sell_result: Label

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
		
	

# Opens shop ui and sets variables and connects buttons
func _on_button_pressed() -> void:
	if !shop_ui:
		shop_ui = SceneLoader.spawn(shop_ui_path, "Hud")
		shop_ui.get_node("ColorRect/CenterContainer/Container/Buy").pressed.connect(_on_buy_pressed)
		shop_ui.get_node("ColorRect/CenterContainer/Container/Sell").pressed.connect(_on_sell_pressed)
		shop_ui.get_node("ColorRect/Close").pressed.connect(_on_close_pressed)
		sell_result = shop_ui.get_node("ColorRect/Labels/SellResult")

# Sells selected fish and changes label to communicate to player
func sell_fish(wallet: PlayerWallet):
	if !player.current_item:
		return
	var selected_item = player.current_item
	var slot = player.inventory.slots[selected_item.slot]
	if slot.is_empty():
		sell_result.text = "No fish"
		sell_result.add_theme_color_override("font_color", Color.RED)
		print("No fish")
		return
	var fish = slot["item"]
	if fish is Fish:
		sell_result.text = "%s: Sold for $%d" % [fish.fish_name, fish.sell_value]
		sell_result.add_theme_color_override("font_color", Color.GREEN)
		wallet.add_money(fish.sell_value)
		player.inventory.remove_item(selected_item.slot,1)
	else:
		sell_result.text = "Select Fish"
		sell_result.add_theme_color_override("font_color", Color.RED)
		print("Not Fish")


func _on_buy_pressed() -> void:
	player.wallet.spend_money(10)
	print(player.wallet.balance)

func _on_sell_pressed() -> void:
	sell_fish(player.wallet)
	print(player.wallet.balance)

func _on_close_pressed() -> void:
	shop_ui.queue_free()
