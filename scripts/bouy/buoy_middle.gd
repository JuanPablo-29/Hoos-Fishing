extends Node2D

@export var distance:=300
@export var amount := 2
var offset := Vector2(0,0)
var buoys:= {}

func set_offset(pos: Vector2):
	offset.x = pos.x
	offset.y = pos.y
	print(offset)

# Called when the node enters the scene tree for the first time.
func set_bounds() -> void:
	for i in range(1, amount+1):
		var pos_left = Vector2(-distance * i, 0) + offset
		var pos_right = Vector2(distance * i, 0) + offset
		print(offset)
		var b_left = SceneLoader.spawn("res://scenes/buoy/boundary.tscn", "Level")
		var b_right = SceneLoader.spawn("res://scenes/buoy/boundary.tscn", "Level")
		
		b_left.rotation_degrees = 90
		b_left.position = pos_left
		
		b_right.rotation_degrees = -90
		b_right.position = pos_right
		buoys[i] = {"left":b_left,
					"right": b_right}

func remove_buoy(b: int):
	buoys[b]['left'].remove()
	buoys[b]['right'].remove()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
