extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneLoader.register("Level", %World/LevelRoot)
	SceneLoader.register("Entity", %World/EntityRoot)
	SceneLoader.register("Hud", %HudLayer/HudRoot)
	SceneLoader.spawn("res://src/gameplay/fishing/fish/golden_trout_swimming_fish.tscn", "Entity")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
