class_name Shop
extends Node


func purchase_rod(wallet: PlayerWallet, rod: FishingRod) -> bool:
	if wallet == null or rod == null:
		return false
		
	if wallet.owns_rod(rod):
		print("Player already owns this rod.")
		return false

	if not wallet.can_afford(rod.purchase_price):
		print("\nNot enough money to purchase this rod.")
		return false

	if wallet.spend_money(rod.purchase_price):
		wallet.add_rod(rod)
		print("\nPurchased rod for $", rod.purchase_price)
		return true

	return false
