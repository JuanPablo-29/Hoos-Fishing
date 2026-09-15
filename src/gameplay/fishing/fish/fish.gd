class_name Fish
extends Resource

enum Rarity {
	ONE_STAR,
	TWO_STAR,
	THREE_STAR
}

@export var fish_name: String = ""
@export var rarity: Rarity = Rarity.ONE_STAR
@export var sell_value: int = 10
@export var catch_difficulty: float = 1.0
