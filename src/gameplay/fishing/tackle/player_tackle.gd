
class_name PlayerTackle
extends Resource

# Tackle prices
const BAIT_PRICE: int = 100
const CHUM_PRICE: int = 200
const LURE_PRICE: int = 350

# Tackle bonuses
const BAIT_MULTIPLIER: float = 1.15
const CHUM_MULTIPLIER: float = 1.25
const LURE_MULTIPLIER: float = 1.50

# Track purchased tackle upgrades
var has_bait: bool = false
var has_chum: bool = false
var has_lure: bool = false


# Purchase bait
func buy_bait(wallet: PlayerWallet) -> bool:
	if has_bait:
		return false

	if not wallet.spend_money(BAIT_PRICE):
		return false

	has_bait = true
	return true


# Purchase chum
func buy_chum(wallet: PlayerWallet) -> bool:
	if has_chum:
		return false

	if not wallet.spend_money(CHUM_PRICE):
		return false

	has_chum = true
	return true


# Purchase lure
func buy_lure(wallet: PlayerWallet) -> bool:
	if has_lure:
		return false

	if not wallet.spend_money(LURE_PRICE):
		return false

	has_lure = true
	return true


# Return the player's catch speed bonus
func get_catch_speed_multiplier() -> float:
	return BAIT_MULTIPLIER if has_bait else 1.0


# Return the player's fish spawn frequency bonus
func get_spawn_rate_multiplier() -> float:
	return CHUM_MULTIPLIER if has_chum else 1.0


# Return the player's rare fish spawn weight bonus
func get_rare_fish_multiplier() -> float:
	return LURE_MULTIPLIER if has_lure else 1.0
