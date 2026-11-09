class_name Manager
extends Node

# Reference to player, set from main_game.gd
var player: Player
@export var timer: Timer
# If true, a fish can only be fished for when the equipped rod is strong enough
# (uses FishingRod.can_catch). Off by default so every fish can be clicked.
@export var enforce_rod_rarity: bool = false
var buoy: Node2D 

# Sets name for fish scene paths
var fishes: Dictionary = {
	"bass": {"scene": "res://src/gameplay/fishing/fish/bass_swimming.tscn",
		"data": preload("res://src/gameplay/fishing/fish/bass.tres")},
	"blue_gill": {"scene": "res://src/gameplay/fishing/fish/blue_gill_swimming.tscn",
		"data": preload("res://src/gameplay/fishing/fish/bluegill.tres"),},
	"trout": { "scene": "res://src/gameplay/fishing/fish/golden_trout_swimming_fish.tscn",
		"data": preload("res://src/gameplay/fishing/fish/golden_trout.tres")},
	"flappy": { "scene": "res://scenes/fish/FlappyFish/flappy_fish_swimming.tscn",
		"data": preload("res://scenes/fish/FlappyFish/flappy_fish.tres")},
}
var fish_keys = fishes.keys()
# Array where fish are added to
var fish_spawned: Array[SwimmingFish] = []
 
const SPAWN_DISTANCE = 250
const MINIGAME_SCENE: PackedScene = preload("res://scenes/FishingMinigame.tscn")
 
# The minigame currently on screen (null when not fishing) and the fish it's for
var minigame: Node2D = null
var hooked_fish: SwimmingFish = null
 
# Random Number Generator
var rng := RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func spawn_initial_fish() -> void:
	### Spawns fishes
	## Blue gill
	spawn_fish("flappy", 300, 200)
	fish_spawned.back().swim_speed = 50
	## Bass
	spawn_fish("flappy",300,200)
	## Trout
	spawn_fish("flappy", 300, 200)
	fish_spawned.back().swim_speed = 80
	fish_spawned.back().min_turn_time = 1.5
	fish_spawned.back().max_turn_time = 3.5
 
func spawn_fish(fish_type: String, x = 0, y = 0) -> SwimmingFish:
	var fish = SceneLoader.spawn(fishes[fish_type]["scene"], "Entity") as SwimmingFish
	fish.position = Vector2(x, y)
	fish.player = player
	fish.clicked.connect(_on_fish_clicked)
	# Appends newest fish to array, access with fish_spawned.back()
	fish_spawned.append(fish)
	return fish
 
func pick_weighted_fish(zone: int) -> String:
	var weights := PackedFloat32Array()
	for key in fish_keys:
		var data = fishes[key]["data"]
		weights.append(data.spawn_weight if data.min_zone <= zone else 0)
	return fish_keys[rng.rand_weighted(weights)]

# Timer runs and spawns random fish on left or right every 5 seconds
func _on_timer_timeout() -> void:
	var sides = [-1, 1]
	var side = sides.pick_random()
	var fish_to_spawn = pick_weighted_fish(get_zone())
	spawn_fish(fish_to_spawn, player.position.x+(SPAWN_DISTANCE*side) , 150)
 
func get_zone() -> int:
	var b_dict = buoy.buoys
	var zone = 0
	var player_x = player.position.x
	for b in b_dict:
		if player_x > b_dict[b]['left'].position.x and player_x < b_dict[b]['right'].position.x:
			return b
	return b_dict.amount
 
# --- Fishing minigame ---
 
# The player clicked a swimming fish: freeze it and start the minigame
func _on_fish_clicked(fish: SwimmingFish) -> void:
	if minigame != null:
		return # already fishing, ignore other clicks
 
	var rod: FishingRod = player.equipped_rod
	if enforce_rod_rarity and rod != null and not rod.can_catch(fish.fish_data):
		print("Your rod isn't strong enough for a %s." % fish.fish_data.fish_name)
		return
 
	var hud: Node = SceneLoader.containers.get("Hud")
	if hud == null:
		print("Invalid Container")
		return
 
	fish.hook()
	hooked_fish = fish
 
	# Instantiate manually (instead of SceneLoader.spawn) so auto_start can be turned off
	# before the minigame's _ready() runs.
	var scene: PackedScene = fish.fish_data.minigame_scene if fish.fish_data.minigame_scene else MINIGAME_SCENE
	minigame = scene.instantiate()
	minigame.auto_start = false
	hud.add_child(minigame)
 
	# Park it on the right side of the screen (the HUD doesn't move with the camera)
	var screen: Vector2 = get_viewport().get_visible_rect().size
	if scene == MINIGAME_SCENE:
		minigame.position = Vector2(screen.x - 40.0, screen.y * 0.5)
	else:
		minigame.scale = Vector2(2.2, 2.2)
		minigame.position = Vector2(80, 30)
 
	# Better rods increase catch speed and make the catch zone larger
	if rod != null:
		if "catch_gain" in minigame:
			minigame.catch_gain *= rod.catch_speed_multiplier
			minigame.catch_zone_multiplier = rod.catch_zone_multiplier
 
	# Fish.catch_difficulty runs 1.0 (bluegill) to 3.0 (golden trout);
	# map that to the minigame's 0..1 difficulty scale.
	var difficulty: float = remap(fish.fish_data.catch_difficulty, 1.0, 3.0, 0.2, 0.8)
 
	minigame.finished.connect(_on_minigame_finished)
	minigame.start(clampf(difficulty, 0.0, 1.0))
	player.is_fishing = true
 
 
func _on_minigame_finished(success: bool) -> void:
	var fish: SwimmingFish = hooked_fish
	player.is_fishing = false
 
	minigame.queue_free()
	minigame = null
	hooked_fish = null
 
	# The fish may have been removed while the minigame was running
	if not is_instance_valid(fish):
		return
 
	fish_spawned.erase(fish)
 
	if success:
		_catch_fish(fish)
	else:
		print("The %s swam away..." % fish.fish_data.fish_name)
		player.task_board.record_failure()
		fish.flee()
 
 
func _catch_fish(fish: SwimmingFish) -> void:
	var added: int = player.inventory.add_item(fish.fish_data)
	if added == 0:
		# All hotbar slots are taken by other items
		print("Inventory full! The %s got away." % fish.fish_data.fish_name)
		player.task_board.record_failure()
		fish.flee()
		return
	
	# Count the fish only after it successfully enters inventory.
	player.catch_tracker.record_catch(fish.fish_data)

	print("Caught a %s!" % fish.fish_data.fish_name)
	fish.queue_free()
