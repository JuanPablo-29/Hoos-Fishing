extends Node

var bluegill: Fish = preload("res://src/gameplay/fishing/fish/bluegill.tres")
var bass: Fish = preload("res://src/gameplay/fishing/fish/bass.tres")
var golden_trout: Fish = preload("res://src/gameplay/fishing/fish/golden_trout.tres")

var basic_rod: FishingRod = preload("res://src/gameplay/fishing/rods/basic_rod.tres")
var improved_rod: FishingRod = preload("res://src/gameplay/fishing/rods/improved_rod.tres")
var advanced_rod: FishingRod = preload("res://src/gameplay/fishing/rods/advanced_rod.tres")


func _ready() -> void:
	
	print("\nShop Purchase Test:")

	var wallet := PlayerWallet.new()
	wallet.balance = 300

	var shop := Shop.new()

	print("Starting balance: $", wallet.balance)
	print("Improved Rod price: $", improved_rod.purchase_price)
	print("Advanced Rod price: $", advanced_rod.purchase_price)

	var purchased_improved := shop.purchase_rod(wallet, improved_rod)
	print("Improved Rod purchased: ", purchased_improved)
	print("Balance after purchase: $", wallet.balance)
	
	print("\nDuplicate Purchase Test:")

	var balance_before_duplicate := wallet.balance

	var purchased_again := shop.purchase_rod(wallet, improved_rod)

	print("Purchased Improved Rod again: ", purchased_again)
	print("Balance before duplicate attempt: $", balance_before_duplicate)
	print("Balance after duplicate attempt: $", wallet.balance)
	print("Owns Improved Rod: ", wallet.owns_rod(improved_rod))

	var purchased_advanced := shop.purchase_rod(wallet, advanced_rod)
	print("Advanced Rod purchased: ", purchased_advanced)
	print("Final balance: $", wallet.balance)
	
	print("\nBasic Rod:")
	print("Bluegill: ", basic_rod.can_catch(bluegill))
	print("Bass: ", basic_rod.can_catch(bass))
	print("Golden Trout: ", basic_rod.can_catch(golden_trout))

	print("\nImproved Rod:")
	print("Bluegill: ", improved_rod.can_catch(bluegill))
	print("Bass: ", improved_rod.can_catch(bass))
	print("Golden Trout: ", improved_rod.can_catch(golden_trout))

	print("\nAdvanced Rod:")
	print("Bluegill: ", advanced_rod.can_catch(bluegill))
	print("Bass: ", advanced_rod.can_catch(bass))
	print("Golden Trout: ", advanced_rod.can_catch(golden_trout))
	
	
	print("\nCatch Speed Test:")
	var base_time: float = 10.0

	print("Base Catch Time: ", base_time, " seconds")
	print("Basic Rod: ", basic_rod.get_adjusted_catch_time(base_time), " seconds")
	print("Improved Rod: ", improved_rod.get_adjusted_catch_time(base_time), " seconds")
	print("Advanced Rod: ", advanced_rod.get_adjusted_catch_time(base_time), " seconds")
