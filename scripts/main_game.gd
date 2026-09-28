extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Registers containers
	SceneLoader.register("Level", %World/LevelRoot)
	SceneLoader.register("Entity", %World/EntityRoot)
	SceneLoader.register("Hud", %HudLayer/HudRoot)
	SceneLoader.register("Systems", %Systems)
	
	var fish_manager = SceneLoader.spawn("res://scenes/FishSpawnManager.tscn","Systems") as Manager
	fish_manager.player = $World/LevelRoot/Hoo
