extends Node

var bluegill: Fish = preload("res://src/gameplay/fishing/fish/bluegill.tres")
var bass: Fish = preload("res://src/gameplay/fishing/fish/bass.tres")
var golden_trout: Fish = preload("res://src/gameplay/fishing/fish/golden_trout.tres")

var basic_rod: FishingRod = preload("res://src/gameplay/fishing/rods/basic_rod.tres")
var improved_rod: FishingRod = preload("res://src/gameplay/fishing/rods/improved_rod.tres")
var advanced_rod: FishingRod = preload("res://src/gameplay/fishing/rods/advanced_rod.tres")


func _ready() -> void:
	print("Basic Rod:")
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
