class_name FishingRod
extends Resource

@export var rod_name: String = ""
@export var max_fish_rarity: Fish.Rarity = Fish.Rarity.ONE_STAR
@export var catch_speed_multiplier: float = 1.0

func can_catch(fish: Fish) -> bool:
	return fish.rarity <= max_fish_rarity
