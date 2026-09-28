extends Control

var selected_slot: int = 0
var player: Player
var inventory: PlayerInventory
@onready var slots: Array[Node] = $HotbarPanel/Slots.get_children()

const BLUEGILL_ICON = preload("res://assets/Fish/bluegill.png")
const BASS_ICON = preload("res://assets/Fish/bass.png")
const TROUT_ICON = preload("res://assets/Fish/golden_trout.png")

# Connect display to players inventory
func bind_player(value: Player) -> void:
	player = value
	inventory = player.inventory
	
	inventory.changed.connect(update_hotbar)
	update_hotbar()



func _ready():
	update_hotbar()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("hotbar_0"):
		select_slot(0)
	elif Input.is_action_just_pressed("hotbar_1"):
		select_slot(1)
	elif Input.is_action_just_pressed("hotbar_2"):
		select_slot(2)


func select_slot(index: int) -> void:
	if inventory == null:
		return
	if index < 0 or index >= inventory.slots.size():
		return
	selected_slot = index
	
	var entry: Dictionary = inventory.slots[index]
	# Makes the selected item the current slot
	var item_info = player.ItemData.new()
	item_info.item = entry["item"]
	item_info.slot = index
	player.current_item = item_info
	
	# Selecting a rod equips it
	if not entry.is_empty():
		var item: Resource = entry["item"]
		
		if item is FishingRod:
			player.equipped_rod = item
	update_hotbar()

# Refresh  pictures, numbers, and selected border.
func update_hotbar() -> void:
	if inventory == null:
		return

	for i in range(slots.size()):
		var button: Button = slots[i] as Button
		var icon: TextureRect = button.get_node("Icon")
		var count: Label = button.get_node("Count")
		var entry: Dictionary = inventory.slots[i]

		# Highlight the selected slot.
		button.button_pressed = i == selected_slot

		# Clear whatever was previously displayed.
		button.text = ""
		icon.texture = null
		count.text = ""

		if entry.is_empty():
			continue

		var item: Resource = entry["item"]

		if item is FishingRod:
			# Temporary display until you have a rod picture.
			button.text = "Rod"

		elif item is Fish:
			# Choose the picture for the fish.
			match item.resource_path.get_file():
				"bluegill.tres":
					icon.texture = BLUEGILL_ICON

				"bass.tres":
					icon.texture = BASS_ICON

				"golden_trout.tres":
					icon.texture = TROUT_ICON

			# Show a number only when there is more than one.
			var quantity: int = int(entry["quantity"])

			if quantity > 1:
				count.text = str(quantity)
