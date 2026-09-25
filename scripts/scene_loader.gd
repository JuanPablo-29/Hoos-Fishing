extends Node

var containers = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#Use to register containers as a name and be able to add
# scenes to those paths
func register(name_root: String, root: Node):
	containers[name_root] = root
	
# Spawns a presaved scene to the container,
# container has to be registered with register
func spawn(path: String, container_name: String) -> Node:
	var container = containers.get(container_name)
	if !container:
		print("Invalid Container")
		return null
	var instance = load(path).instantiate()
	container.add_child(instance)
	return instance
	
