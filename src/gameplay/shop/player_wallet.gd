class_name PlayerWallet
extends Resource

@export var balance: int = 0

var owned_rods: Array[FishingRod] = []


func can_afford(price: int) -> bool:
	return balance >= price


func add_money(amount: int) -> void:
	if amount > 0:
		balance += amount


func spend_money(amount: int) -> bool:
	if amount <= 0:
		return false

	if not can_afford(amount):
		return false

	balance -= amount
	return true


func owns_rod(rod: FishingRod) -> bool:
	return rod in owned_rods


func add_rod(rod: FishingRod) -> void:
	if not owns_rod(rod):
		owned_rods.append(rod)
