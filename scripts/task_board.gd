class_name TaskBoard
extends RefCounted

enum State { OFFERED, ACTIVE, READY }

const REROLL_COST: int = 25
const SECONDS_PER_FISH: int = 45
const FISH_DIR: String = "res://src/gameplay/fishing/fish/"

# Each row generates several Tasks
# Empty target means any fish
# Reward is requested number times rate
const POOL: Array[Dictionary] = [
	{"rule": "catch", "target": "", "min": 3, "max": 8, "rate": 15},
	{"rule": "catch", "target": "bass", "min": 2, "max": 6, "rate": 30},
	{"rule": "catch", "target": "bluegill", "min": 3, "max": 7, "rate": 20},
	{"rule": "catch", "target": "golden_trout", "min": 1, "max": 3, "rate": 60},
	{"rule": "streak", "target": "", "min": 2, "max": 5, "rate": 40},
	{"rule": "timed", "target": "", "min": 2, "max": 5, "rate": 35},
	{"rule": "timed", "target": "bass", "min": 2, "max": 4, "rate": 45},
	{"rule": "timed", "target": "bluegill", "min": 2, "max": 4, "rate": 35},
	{"rule": "variety", "target": "", "min": 2, "max": 3, "rate": 50}
]

var state := State.OFFERED
var family: int = -1
var goal: int = 0
var progress: int = 0
var seconds_left: float = 0.0
var message: String = ""

# Used by tasks
var seen_species: Dictionary = {}

func _init() -> void:
	_roll_offer()

func _roll_offer() -> void:
	# Exclude the current row so a paid reroll gives a different offer
	var choices := range(POOL.size())
	choices.erase(family)
	family = choices.pick_random()

	var offer: Dictionary = POOL[family]
	goal = randi_range(int(offer["min"]), int(offer["max"]))

	state = State.OFFERED
	progress = 0
	seconds_left = 0.0
	seen_species.clear()

func reward() -> int:
	return goal * int(POOL[family]["rate"])

func description() -> String:
	var offer: Dictionary = POOL[family]
	var target: String = offer["target"]
	var species: String = "fish"

	if not target.is_empty():
		species = target.capitalize()

	match offer["rule"]:
		"streak":
			return "Catch %d fish in a row" % goal
		"timed":
			return "Catch %d %s in %ds" % [goal, species, goal * SECONDS_PER_FISH]
		"variety":
			return "Catch %d different species" % goal
		_:
			return "Catch %d %s" % [goal, species]

func accept() -> void:
	if state != State.OFFERED:
		return

	state = State.ACTIVE
	progress = 0
	message = ""
	seen_species.clear()

	if POOL[family]["rule"] == "timed":
		seconds_left = goal * SECONDS_PER_FISH

func reroll(wallet: PlayerWallet) -> void:
	if state != State.OFFERED:
		return

	if not wallet.spend_money(REROLL_COST):
		message = "Need $%d to reroll." % REROLL_COST
		return

	_roll_offer()
	message = ""

func claim(wallet: PlayerWallet) -> void:
	if state != State.READY:
		return

	# Remember this reward before generating the next offer
	var payout: int = reward()
	_roll_offer()
	wallet.add_money(payout)
	message = "Received $%d!" % payout

func record_catch(fish: Fish) -> void:
	if state != State.ACTIVE:
		return

	var offer: Dictionary = POOL[family]
	var target: String = offer["target"]

	# Species tasks count only fish matching their resource file
	if not target.is_empty():
		var target_path: String = FISH_DIR + target + ".tres"
		if fish.resource_path != target_path:
			return

	if offer["rule"] == "variety":
		# Catching another same specices keeps the same dictionary entry
		seen_species[fish.resource_path] = true
		progress = seen_species.size()
	else:
		progress += 1

	if progress >= goal:
		state = State.READY


func record_failure() -> void:
	# Once a streak is complete, the player can safely claim it later
	if state == State.ACTIVE and POOL[family]["rule"] == "streak":
		progress = 0

func advance_time(delta: float) -> void:
	if state != State.ACTIVE or POOL[family]["rule"] != "timed":
		return

	seconds_left = maxf(0.0, seconds_left - delta)

	if seconds_left <= 0.0:
		state = State.OFFERED
		progress = 0
		message = "Time up. Retry for free."
