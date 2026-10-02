class_name Manager
extends Node
# Reference to player, set from main_game.gd
var player: Player
@export var timer: Timer
# If true, a fish can only be fished for when the equipped rod is strong enough
# (uses FishingRod.can_catch). Off by default so every fish can be clicked.
@export var enforce_rod_rarity: bool = false
 
# Sets name for fish scene paths
var fishes: Dictionary = {
	"bass": "res://src/gameplay/fishing/fish/bass_swimming.tscn",
	"blue_gill": "res://src/gameplay/fishing/fish/blue_gill_swimming.tscn",
	"trout": "res://src/gameplay/fishing/fish/golden_trout_swimming_fish.tscn"
}
var fish_keys = fishes.keys()
# Array where fish are added to
var fish_spawned: Array[SwimmingFish] = []
 
const SPAWN_DISTANCE = 250
 
const MINIGAME_SCENE: PackedScene = preload("res://scenes/FishingMinigame.tscn")
 
# The minigame currently on screen (null when not fishing) and the fish it's for
var minigame: Node2D = null
var hooked_fish: SwimmingFish = null
 
# Called when the node enters the scene tree for the first time.
func spawn_initial_fish() -> void:
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
	fish.player = player
	fish.clicked.connect(_on_fish_clicked)
	# Appends newest fish to array, access with fish_spawned.back()
	fish_spawned.append(fish)
	return fish
 
# Timer runs and spawns random fish on left or right every 5 seconds
func _on_timer_timeout() -> void:
	var sides = [-1, 1]
	var side = sides.pick_random()
	var fish_to_spawn = fish_keys.pick_random()
	spawn_fish(fish_to_spawn, player.position.x+(SPAWN_DISTANCE*side) , 150)
 
 
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
	minigame = MINIGAME_SCENE.instantiate()
	minigame.auto_start = false
	hud.add_child(minigame)
 
	# Park it on the right side of the screen (the HUD doesn't move with the camera)
	var screen: Vector2 = get_viewport().get_visible_rect().size
	minigame.position = Vector2(screen.x - 40.0, screen.y * 0.5)
 
	# A better rod fills the catch meter faster
	if rod != null:
		minigame.catch_gain *= rod.catch_speed_multiplier
 
	# Fish.catch_difficulty runs 1.0 (bluegill) to 3.0 (golden trout);
	# map that to the minigame's 0..1 difficulty scale.
	var difficulty: float = remap(fish.fish_data.catch_difficulty, 1.0, 3.0, 0.2, 0.8)
 
	minigame.finished.connect(_on_minigame_finished)
	minigame.start(clampf(difficulty, 0.0, 1.0))
 
 
func _on_minigame_finished(success: bool) -> void:
	var fish: SwimmingFish = hooked_fish
 
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
		fish.flee()
 
 
func _catch_fish(fish: SwimmingFish) -> void:
	var added: int = player.inventory.add_item(fish.fish_data)
	if added == 0:
		# All hotbar slots are taken by other items
		print("Inventory full! The %s got away." % fish.fish_data.fish_name)
		fish.flee()
		return
 
	print("Caught a %s!" % fish.fish_data.fish_name)
	fish.queue_free()
