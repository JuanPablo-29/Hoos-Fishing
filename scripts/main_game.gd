extends Node
@export var player: Player
# Sets name for fish scene paths
var fishes: Dictionary = {
	"bass": "res://src/gameplay/fishing/fish/bass_swimming.tscn",
	"blue_gill": "res://src/gameplay/fishing/fish/blue_gill_swimming.tscn",
	"trout": "res://src/gameplay/fishing/fish/golden_trout_swimming_fish.tscn"
}

# Array where fish are added to
var fish_spawned: Array[SwimmingFish] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Registers containers
	SceneLoader.register("Level", %World/LevelRoot)
	SceneLoader.register("Entity", %World/EntityRoot)
	SceneLoader.register("Hud", %HudLayer/HudRoot)
	
	### Spawns shop keeper
	var shop_keeper = SceneLoader.spawn("res://scenes/ShopKeeper.tscn", "Level") as Node2D
	shop_keeper.position = Vector2(100,100)
	shop_keeper.player = player
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
	
	
# Takes in string from dictionary for fish scene paths
func spawn_fish(fish_type: String, x = 0, y = 0) -> SwimmingFish:
	var fish = SceneLoader.spawn(fishes.get(fish_type), "Entity") as SwimmingFish
	fish.position = Vector2(x, y)
	# Appends newest fish to array, access with fish_spawned.back()
	fish_spawned.append(fish)
	return fish
