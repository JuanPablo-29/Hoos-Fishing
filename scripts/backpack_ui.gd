extends Control

const BLUEGILL_ICON = preload("res://assets/Fish/bluegill.png")
const BASS_ICON = preload("res://assets/Fish/bass.png")
const TROUT_ICON = preload("res://assets/Fish/golden_trout.png")

const CREAM := Color("#f3e4c5")
const GOLD := Color("#e8bc65")

var player: Player
var panel: Panel
var equipped_button: Button
var status_label: Label

var slot_buttons: Array[Button] = []
var slot_icons: Array[TextureRect] = []
var slot_counts: Array[Label] = []

var first_slot: int = -1


func bind_player(value: Player) -> void:
	player = value
	_build_ui()
	player.inventory.changed.connect(_refresh)
	_refresh()


# Shared colors and borders for the panel and buttons.
func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(2)
	return style


func _style_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)

	button.add_theme_stylebox_override(
		"normal", _style(Color("#34271f"), Color("#806044"))
	)
	button.add_theme_stylebox_override(
		"hover", _style(Color("#55402c"), GOLD)
	)
	button.add_theme_stylebox_override(
		"pressed", _style(Color("#654c30"), GOLD)
	)


func _label(
	text: String,
	location: Vector2,
	dimensions: Vector2,
	font_size: int = 9
) -> Label:
	var label := Label.new()
	label.text = text
	label.position = location
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	panel.add_child(label)
	return label


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	equipped_button = Button.new()
	equipped_button.text = "BAG [B]"
	equipped_button.position = Vector2(306, 26)
	equipped_button.size = Vector2(69, 20)
	equipped_button.tooltip_text = "Backpack equipped"
	_style_button(equipped_button)
	equipped_button.pressed.connect(_toggle)
	add_child(equipped_button)

	panel = Panel.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -112
	panel.offset_top = -92
	panel.offset_right = 112
	panel.offset_bottom = 92
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := _style(
		Color("#281f1b"), Color("#bc9463")
	)
	panel_style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", panel_style)

	_label("BACKPACK", Vector2(12, 8), Vector2(160, 18), 12)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.position = Vector2(195, 8)
	close_button.size = Vector2(18, 18)
	_style_button(close_button)
	close_button.pressed.connect(_close)
	panel.add_child(close_button)

	_label("STORAGE", Vector2(12, 30), Vector2(180, 14))

	# Create buttons in inventory-index order:
	# hotbar indices 0–2, backpack indices 3–8.
	for i in range(PlayerInventory.HOTBAR_SIZE):
		_add_slot_button(i, Vector2(58 + i * 38, 126))

	for i in range(PlayerInventory.BACKPACK_SIZE):
		var column: int = i % 3
		var row: int = int(i / 3)

		_add_slot_button(
			PlayerInventory.HOTBAR_SIZE + i,
			Vector2(58 + column * 38, 46 + row * 32)
		)

	_label("HOTBAR", Vector2(12, 108), Vector2(180, 14))

	status_label = _label(
		"Click an item, then its destination.",
		Vector2(8, 162),
		Vector2(208, 14),
		8
	)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	panel.hide()


func _add_slot_button(index: int, location: Vector2) -> void:
	var button := Button.new()
	button.position = location
	button.size = Vector2(32, 28)
	button.toggle_mode = true
	_style_button(button)
	button.pressed.connect(_on_slot_pressed.bind(index))
	panel.add_child(button)
	slot_buttons.append(button)

	var icon := TextureRect.new()
	icon.position = Vector2(3, 3)
	icon.size = Vector2(26, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	slot_icons.append(icon)

	var count := Label.new()
	count.position = Vector2(2, 14)
	count.size = Vector2(27, 12)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.add_theme_font_size_override("font_size", 8)
	count.add_theme_color_override("font_color", Color.WHITE)
	count.add_theme_color_override("font_outline_color", Color("#201810"))
	count.add_theme_constant_override("outline_size", 2)
	button.add_child(count)
	slot_counts.append(count)


func _input(event: InputEvent) -> void:
	if player == null:
		return

	if event is InputEventKey and !player.is_fishing and !player.is_shopping:
		if event.pressed and not event.echo:
			if event.physical_keycode == KEY_B:
				_toggle()
				get_viewport().set_input_as_handled()


func _toggle() -> void:
	if not player.inventory.has_backpack:
		return

	if panel.visible:
		_close()
	else:
		first_slot = -1
		panel.show()
		_refresh()


func _close() -> void:
	first_slot = -1
	panel.hide()


func _on_slot_pressed(index: int) -> void:
	if first_slot == -1:
		# Choose an occupied slot first.
		if player.inventory.slots[index].is_empty():
			return

		first_slot = index
	else:
		var source: int = first_slot
		first_slot = -1
		player.inventory.swap_slots(source, index)

	_refresh()


func _item_name(item: Resource) -> String:
	if item is Fish:
		return item.fish_name
	if item is FishingRod:
		return item.rod_name
	return "Item"


func _fish_icon(item: Fish) -> Texture2D:
	match item.resource_path.get_file():
		"bluegill.tres":
			return BLUEGILL_ICON
		"bass.tres":
			return BASS_ICON
		"golden_trout.tres":
			return TROUT_ICON

	return null


func _refresh() -> void:
	equipped_button.visible = player.inventory.has_backpack

	# Keep the selected hotbar item current after moving items.
	if player.current_item != null:
		var selected: int = player.current_item.slot

		if selected >= 0 and selected < player.inventory.slots.size():
			player.current_item.item = player.inventory.slots[selected].get("item")

			if player.current_item.item is FishingRod:
				player.equipped_rod = player.current_item.item

	for i in range(slot_buttons.size()):
		var button: Button = slot_buttons[i]
		var icon: TextureRect = slot_icons[i]
		var count: Label = slot_counts[i]

		button.text = ""
		icon.texture = null
		count.text = ""
		button.set_pressed_no_signal(i == first_slot)

		if i >= player.inventory.slots.size():
			button.disabled = true
			button.tooltip_text = "Locked"
			continue

		button.disabled = false
		var entry: Dictionary = player.inventory.slots[i]

		if entry.is_empty():
			button.tooltip_text = "Empty slot"
			continue

		var item: Resource = entry["item"]
		button.tooltip_text = _item_name(item)

		if item is Fish:
			icon.texture = _fish_icon(item)
			if icon.texture == null:
				button.text = "Fish"
		elif item is FishingRod:
			# Replace with rod artwork when it is available.
			button.text = "Rod"

		var quantity: int = int(entry["quantity"])
		if quantity > 1:
			count.text = str(quantity)

	status_label.text = "Click an item, then its destination."

	if first_slot >= 0 and first_slot < player.inventory.slots.size():
		var selected_entry: Dictionary = player.inventory.slots[first_slot]
		if not selected_entry.is_empty():
			status_label.text = "Move: " + _item_name(selected_entry["item"])
