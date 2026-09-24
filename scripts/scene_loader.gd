extends Node

var containers = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func register(name: String, root: Node):
	containers[name] = root
	
func spawn(path: String, container_name: String) -> Node:
	var container = containers.get(container_name)
	if !container:
		print("Invalid Container")
		return null
	var instance = load(path).instantiate()
	container.add_child(instance)
	return instance
	
