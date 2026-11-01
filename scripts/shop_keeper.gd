extends Node2D
var player: Player
@export var sprite: ColorRect
@export var button: Button
var close_enough: bool = false
var shop_ui: Control
@onready var shop_ui_path: String = "res://scenes/ShopUI.tscn"
var shop:= Shop.new()
var sell_result: Label
var upgrade_result: Label


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
		upgrade_result = shop_ui.get_node("ColorRect/Labels/UpgradeResult")
		

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


# Upgrade the rod in the selected hotbar slot.
func upgrade_rod() -> void:
	if player.current_item == null:
		show_upgrade_result("Select a rod first.", false)
		return

	var index: int = player.current_item.slot
	var inventory: PlayerInventory = player.inventory

	if index < 0 or index >= inventory.slots.size():
		show_upgrade_result("Select a rod first.", false)
		return

	var entry: Dictionary = inventory.slots[index]
	var rod: FishingRod = entry.get("item") as FishingRod

	if rod == null:
		show_upgrade_result("Select a rod first.", false)
		return

	var new_rod: FishingRod = rod.next_upgrade

	if new_rod == null:
		show_upgrade_result("%s is fully upgraded." % rod.rod_name,false)
		return

	# Protect against an accidentally incorrect resource setting.
	if new_rod == rod or new_rod.purchase_price < 0:
		show_upgrade_result("Invalid rod upgrade.", false)
		return

	var price: int = new_rod.purchase_price

	if not player.wallet.can_afford(price):
		show_upgrade_result("Need $%d." % price, false)
		return

	# The existing wallet rejects zero-cost spending.
	# Skip the payment for a free upgrade.
	if price > 0:
		if not player.wallet.spend_money(price):
			show_upgrade_result("Could not complete purchase.", false)
			return

	# Replace this exact slot, other rods and fish stay unchanged.
	inventory.slots[index] = {"item": new_rod,"quantity": 1}

	player.current_item.item = new_rod
	player.equipped_rod = new_rod

	# Preserve compatibility with your existing ownership tracking.
	player.wallet.add_rod(new_rod)

	inventory.changed.emit()

	show_upgrade_result("Upgraded to %s for $%d." % [new_rod.rod_name, price],true)


# Display the outcome in the existing shop label.
func show_upgrade_result(message: String, success: bool) -> void:
	upgrade_result.text = message

	var color: Color = Color.RED
	if success:
		color = Color.GREEN

	upgrade_result.add_theme_color_override("font_color", color)


func _on_buy_pressed() -> void:
	upgrade_rod()



func _on_sell_pressed() -> void:
	sell_fish(player.wallet)
	print(player.wallet.balance)

func _on_close_pressed() -> void:
	shop_ui.queue_free()
