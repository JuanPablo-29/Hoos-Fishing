extends Node

var failures := 0


func _ready() -> void:
	await _run()


func _run() -> void:
	var hud := Control.new()
	add_child(hud)
	SceneLoader.register("Hud", hud)

	var shop = preload("res://scenes/ShopKeeper.tscn").instantiate()
	add_child(shop)
	shop.set_process(false)
	var minigame = preload("res://scenes/FishingMinigame.tscn").instantiate()
	hud.add_child(minigame)

	shop._on_button_pressed()
	_check(shop.shop_ui == null, "shop must stay closed while the fishing minigame is active")

	minigame.free()
	shop._on_button_pressed()
	_check(shop.shop_ui != null, "shop must open again after the fishing minigame closes")

	if failures == 0:
		print("PASS: shop and fishing input isolation")
	SceneLoader.containers.erase("Hud")
	shop.free()
	hud.free()
	await get_tree().process_frame
	get_tree().quit(failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
