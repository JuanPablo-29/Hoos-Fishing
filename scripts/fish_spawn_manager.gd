class_name Manager
extends Node
# Reference to player, set from main_game.gd
var player: Node2D
@export var timer: Timer
# Sets name for fish scene paths
var fishes: Dictionary = {
	"bass": "res://src/gameplay/fishing/fish/bass_swimming.tscn",
	"blue_gill": "res://src/gameplay/fishing/fish/blue_gill_swimming.tscn",
	"trout": "res://src/gameplay/fishing/fish/golden_trout_swimming_fish.tscn"
}
var fish_keys = fishes.keys()
# Array where fish are added to
var fish_spawned: Array[SwimmingFish] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	### Spawns fishes
	## Blue gill
	spawn_fish("blue_gill", 300, 200)
	fish_spawned.back().swim_speed = 50
	## Bass
	spawn_fish("bass",300,200)
	## Trout
	spawn_fish("trout", 300, 200)
	fish_spawned.back().swim_speed = 80
	fish_spawned.back().min_turn_time = 1.5
	fish_spawned.back().max_turn_time = 3.5

func spawn_fish(fish_type: String, x = 0, y = 0) -> SwimmingFish:
	var fish = SceneLoader.spawn(fishes.get(fish_type), "Entity") as SwimmingFish
	fish.position = Vector2(x, y)
	# Appends newest fish to array, access with fish_spawned.back()
	fish_spawned.append(fish)
	return fish

# Timer runs and spawns random fish on left or right every 5 seconds
func _on_timer_timeout() -> void:
	var sides = [-1, 1]
	var side = sides.pick_random()
	var fish_to_spawn = fish_keys.pick_random()
	spawn_fish(fish_to_spawn, player.position.x+(250*side) , 150)
