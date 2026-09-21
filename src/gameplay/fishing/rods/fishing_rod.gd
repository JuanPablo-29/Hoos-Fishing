class_name FishingRod
extends Resource

@export var rod_name: String = ""
@export var purchase_price: int = 0
@export var max_fish_rarity: Fish.Rarity = Fish.Rarity.ONE_STAR
@export var catch_speed_multiplier: float = 1.0


func can_catch(fish: Fish) -> bool:
	return fish.rarity <= max_fish_rarity
	
func get_adjusted_catch_time(base_catch_time: float) -> float:
	return base_catch_time / catch_speed_multiplier
