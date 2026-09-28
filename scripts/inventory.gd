class_name PlayerInventory
extends RefCounted

signal changed

const MAX_STACK: int = 64

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
