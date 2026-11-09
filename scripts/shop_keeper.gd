
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
var backpack_buy_button: Button
var buoy
const BOAT_PRICES := [200, 500]

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta: float) -> void:
	var distance = global_position.distance_to(player.global_position)
	if distance <= 70:
		sprite.color = Color.BEIGE
		close_enough = true
	else:
		sprite.color = Color.BROWN
		close_enough = false

	# Disable the shop button when the player is too far away or fishing
	button.disabled = !close_enough or player.is_fishing

	# Refresh the countdown while the Tasks tab is visible
	if is_instance_valid(shop_ui) and shop_ui.get_node("ColorRect/Tabs/Tasks").visible:
		_refresh_task_page()

	# Close the shop if the player starts fishing or moves away
	if is_instance_valid(shop_ui) and (player.is_fishing or player.velocity.x != 0):
		shop_ui.queue_free()
		shop_ui = null
		player.is_shopping = false


# Opens shop ui and sets variables and connects buttons
func _on_button_pressed() -> void:
	if not is_instance_valid(shop_ui):
		player.is_shopping = true
		shop_ui = SceneLoader.spawn(shop_ui_path, "Hud")

		shop_ui.get_node("ColorRect/Tabs/Shop/Buy").pressed.connect(_on_buy_pressed)
		shop_ui.get_node("ColorRect/Tabs/Shop/Sell").pressed.connect(_on_sell_pressed)
		shop_ui.get_node("Close").pressed.connect(_on_close_pressed)

		sell_result = shop_ui.get_node("ColorRect/Tabs/Shop/Result")
		upgrade_result = shop_ui.get_node("ColorRect/Tabs/Shop/Result")

		# The backpack button is part of the Shop tab. Show whether it is owned
		backpack_buy_button = shop_ui.get_node("ColorRect/Tabs/Shop/Backpack")
		backpack_buy_button.text = "Backpack owned" if player.inventory.has_backpack else "Buy Backpack - $200"
		backpack_buy_button.disabled = player.inventory.has_backpack
		backpack_buy_button.pressed.connect(_on_backpack_buy_pressed)

		# Connect the task controls each time a new shop window opens.
		shop_ui.get_node("ColorRect/Tabs/Tasks/Action").pressed.connect(_on_task_action)
		shop_ui.get_node("ColorRect/Tabs/Tasks/Reroll").pressed.connect(_on_reroll)
		_refresh_task_page()
		
		# Connect boat button
		shop_ui.get_node("ColorRect/Tabs/Boat/Upgrade").pressed.connect(_on_boat_upgrade_pressed)
		_refresh_boat_page()
	if !shop_ui:
		shop_ui = SceneLoader.spawn(shop_ui_path, "Hud")
		shop_ui.get_node("Tabs/Shop/Buy").pressed.connect(_on_buy_pressed)
		shop_ui.get_node("Tabs/Shop/Sell").pressed.connect(_on_sell_pressed)
		shop_ui.get_node("Close").pressed.connect(_on_close_pressed)
		sell_result = shop_ui.get_node("Tabs/Shop/Result")
		upgrade_result = shop_ui.get_node("Tabs/Shop/Result")

		# The backpack button is part of the Shop tab. Show whether it is owned
		backpack_buy_button = shop_ui.get_node("Tabs/Shop/Backpack")
		backpack_buy_button.text = "Backpack owned" if player.inventory.has_backpack else "Buy Backpack - $200"
		backpack_buy_button.disabled = player.inventory.has_backpack
		backpack_buy_button.pressed.connect(_on_backpack_buy_pressed)

		# Connect the task controls each time a new shop window opens.
		shop_ui.get_node("Tabs/Tasks/Action").pressed.connect(_on_task_action)
		shop_ui.get_node("Tabs/Tasks/Reroll").pressed.connect(_on_reroll)
		_refresh_task_page()


# Buy the backpack once, then mark the button as owned
func _on_backpack_buy_pressed() -> void:
	if player.inventory.has_backpack:
		show_upgrade_result("You already own a backpack.", false)
		return

	if not player.inventory.buy_backpack(player.wallet):
		show_upgrade_result("Need $200 for a backpack.", false)
		return

	backpack_buy_button.text = "Backpack owned"
	backpack_buy_button.disabled = true

	show_upgrade_result("Backpack equipped! Press B to open.", true)


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


# Upgrade the rod in the selected hotbar slot
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

	# Protect against an accidentally incorrect resource setting
	if new_rod == rod or new_rod.purchase_price < 0:
		show_upgrade_result("Invalid rod upgrade.", false)
		return

	var price: int = new_rod.purchase_price

	if not player.wallet.can_afford(price):
		show_upgrade_result("Need $%d." % price, false)
		return

	# The existing wallet rejects zero-cost spending
	# Skip the payment for a free upgrade
	if price > 0:
		if not player.wallet.spend_money(price):
			show_upgrade_result("Could not complete purchase.", false)
			return

	# Replace this exact slot, other rods and fish stay unchanged
	inventory.slots[index] = {"item": new_rod,"quantity": 1}

	player.current_item.item = new_rod
	player.equipped_rod = new_rod

	# Preserve compatibility with your existing ownership tracking
	player.wallet.add_rod(new_rod)

	inventory.changed.emit()

	show_upgrade_result("Upgraded to %s for $%d." % [new_rod.rod_name, price],true)


# Display the outcome in the existing shop label
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
	if is_instance_valid(shop_ui):
		player.is_shopping = false
		shop_ui.queue_free()
		shop_ui = null


# Read the player's task board so reopening the shop shows the same progress
func _refresh_task_page() -> void:
	var page := shop_ui.get_node("ColorRect/Tabs/Tasks")
	var board: TaskBoard = player.task_board

	page.get_node("Objective").text = board.description()
	page.get_node("Message").text = board.message

	var status: String = "Progress %d/%d\nReward $%d" % [board.progress, board.goal, board.reward()]

	# Show the remaining seconds for an active timed task
	if board.state == TaskBoard.State.ACTIVE and board.seconds_left > 0:
		status += "   |   %ds" % ceili(board.seconds_left)

	page.get_node("Progress").text = status

	# The same button accepts an offer and later claims its reward
	var action: Button = page.get_node("Action")
	action.disabled = board.state == TaskBoard.State.ACTIVE

	match board.state:
		TaskBoard.State.OFFERED:
			action.text = "Accept task"
		TaskBoard.State.ACTIVE:
			action.text = "In progress"
		TaskBoard.State.READY:
			action.text = "Claim reward"

	# A player can reroll an offer before accepting it
	var reroll_button: Button = page.get_node("Reroll")
	reroll_button.visible = board.state == TaskBoard.State.OFFERED
	reroll_button.text = "New offer - $%d" % TaskBoard.REROLL_COST


func _on_task_action() -> void:
	var board: TaskBoard = player.task_board

	if board.state == TaskBoard.State.OFFERED:
		board.accept()
	elif board.state == TaskBoard.State.READY:
		board.claim(player.wallet)

	_refresh_task_page()


func _on_reroll() -> void:
	# The board checks the balance before charging for a different offer
	player.task_board.reroll(player.wallet)
	_refresh_task_page()

func _refresh_boat_page() -> void:
	var level_label = shop_ui.get_node("ColorRect/Tabs/Boat/Level")
	var button = shop_ui.get_node("ColorRect/Tabs/Boat/Upgrade")
	level_label.text = "Boat level: %d" % player.boat_level
	if player.boat_level >= BOAT_PRICES.size():
		button.text = "Boat fully upgraded"
		button.disabled = true
	else:
		button.text = "Upgrade Boat - $%d" % BOAT_PRICES[player.boat_level]

func _on_boat_upgrade_pressed() -> void:
	var result = shop_ui.get_node("ColorRect/Tabs/Boat/Result")
	var price = BOAT_PRICES[player.boat_level]
	if not player.wallet.spend_money(price):
		result.text = "Need $%d." % price
		return
	player.boat_level += 1
	buoy.remove_buoy(player.boat_level)   # opens the next pair
	result.text = "Boat upgraded!"
	_refresh_boat_page()
