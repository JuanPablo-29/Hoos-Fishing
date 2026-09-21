extends Control

var selected_slot = 0

@onready var slots = $HotbarPanel/Slots.get_children()


func _ready():
	update_hotbar()


func _process(delta):
	if Input.is_action_just_pressed("hotbar_0"):
		select_slot(0)
	elif Input.is_action_just_pressed("hotbar_1"):
		select_slot(1)
	elif Input.is_action_just_pressed("hotbar_2"):
		select_slot(2)
	elif Input.is_action_just_pressed("hotbar_3"):
		select_slot(3)
	elif Input.is_action_just_pressed("hotbar_4"):
		select_slot(4)
	elif Input.is_action_just_pressed("hotbar_5"):
		select_slot(5)
	elif Input.is_action_just_pressed("hotbar_6"):
		select_slot(6)
	elif Input.is_action_just_pressed("hotbar_7"):
		select_slot(7)
	elif Input.is_action_just_pressed("hotbar_8"):
		select_slot(8)
	elif Input.is_action_just_pressed("hotbar_9"):
		select_slot(9)


func select_slot(slot_number):
	selected_slot = slot_number
	update_hotbar()


func update_hotbar():
	for i in range(slots.size()):
		slots[i].button_pressed = (i == selected_slot)
