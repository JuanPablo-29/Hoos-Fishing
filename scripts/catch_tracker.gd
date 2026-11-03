class_name CatchTracker
extends RefCounted

# Other features can listen for successful catches.
signal fish_caught(fish: Fish)

var total_caught: int = 0

# Each fish resource path maps to its catch count.
var catches_by_species: Dictionary = {}


func record_catch(fish: Fish) -> void:
	if fish == null:
		return

	var species: String = fish.resource_path

	# Fish definitions should be saved .tres resources.
	if species.is_empty():
		push_error("Cannot track a fish without a saved resource.")
		return

	total_caught += 1
	catches_by_species[species] = get_catch_count(fish) + 1

	# Notify listeners after the counts have been updated.
	fish_caught.emit(fish)


func get_catch_count(fish: Fish) -> int:
	if fish == null:
		return 0

	return int(catches_by_species.get(fish.resource_path, 0))


func has_caught(fish: Fish) -> bool:
	return get_catch_count(fish) > 0
