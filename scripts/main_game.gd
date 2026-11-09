extends Node
@export var player: Player
# Sets name for fish scene paths
var fishes: Dictionary = {
	"bass": "res://src/gameplay/fishing/fish/bass_swimming.tscn",
	"blue_gill": "res://src/gameplay/fishing/fish/blue_gill_swimming.tscn",
	"trout": "res://src/gameplay/fishing/fish/golden_trout_swimming_fish.tscn"
}

const BACKPACK_UI = preload("res://scripts/backpack_ui.gd")

# Array where fish are added to
var fish_spawned: Array[SwimmingFish] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Show player inventory in hotbar
	$HudLayer/HudRoot/Hotbar.bind_player(player)
	
	# Backpack 
	var backpack_ui = BACKPACK_UI.new()
	$HudLayer/HudRoot.add_child(backpack_ui)
	backpack_ui.bind_player(player)
	
	# Registers containers
	SceneLoader.register("Level", %World/LevelRoot)
	SceneLoader.register("Entity", %World/EntityRoot)
	SceneLoader.register("Hud", %HudLayer/HudRoot)
	SceneLoader.register("Systems", %Systems)
	
	var fish_manager = SceneLoader.spawn("res://scenes/FishSpawnManager.tscn","Systems") as Manager
	fish_manager.player = $World/LevelRoot/Hoo
	
	var shop = SceneLoader.spawn("res://scenes/ShopKeeper.tscn", "Level")
	shop.player = player
	shop.position = Vector2(200,115)
	
	var buoy_middle = SceneLoader.spawn("res://scenes/buoy/BuoyMiddle.tscn", "Level")
	buoy_middle.set_offset(shop.position)
	buoy_middle.set_bounds()
	
