class_name PlayerInventory
extends RefCounted

signal changed

const MAX_STACK: int = 64
const HOTBAR_SIZE: int = 3
const BACKPACK_SIZE: int = 6
const BACKPACK_PRICE: int = 200

var has_backpack: bool = false

# Each slot stores a resource and its quantity
# Empty dictionary is an empty slot
var slots: Array[Dictionary] = [{}, {}, {}]

# Returns the number added, so that the caller can handle a full inventory
func add_item(item: Resource, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return 0
	
	var remaining: int = amount
	var limit: int = MAX_STACK if item is Fish else 1
	
	# Add to matching statcks first
	for slot in slots:
		if slot.get("item") == item and slot.get("quantity", 0) < limit:
			var added: int = mini(remaining, limit - int(slot["quantity"]))
			
			slot["quantity"] += added
			remaining -= added
			
			if remaining == 0:
				break
	
	# Put leftover items into empty slots
	for i in range(slots.size()):
		if remaining == 0:
			break
		
		if slots[i].is_empty():
			var added: int = mini(remaining, limit)
			
			slots[i] = {"item": item, "quantity": added}
			
			remaining -= added
	
	if remaining < amount:
		changed.emit()
	
	return amount - remaining
	
	
func remove_item(index: int, amount: int = 1) -> int:
	if index < 0 or index >= slots.size() or amount <= 0 or slots[index].is_empty():
		return 0
	
	var removed: int = mini(amount, int(slots[index]["quantity"]))
	
	slots[index]["quantity"] -= removed
	
	if slots[index]["quantity"] == 0:
		slots[index] = {}
	
	changed.emit()
	
	return removed
	
func buy_backpack(wallet: PlayerWallet) -> bool:
	if has_backpack or wallet == null:
		return false

	if not wallet.spend_money(BACKPACK_PRICE):
		return false

	has_backpack = true

	for i in range(BACKPACK_SIZE):
		slots.append({})

	changed.emit()
	return true


# Swapping with an empty slot moves the item.
func swap_slots(first: int, second: int) -> bool:
	if first < 0 or second < 0:
		return false

	if first >= slots.size() or second >= slots.size():
		return false

	if first == second:
		return false

	var temporary: Dictionary = slots[first]
	slots[first] = slots[second]
	slots[second] = temporary

	changed.emit()
	return true
