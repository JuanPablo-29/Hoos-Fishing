extends StaticBody2D


func remove():
	$Sprite2D.modulate.a = 0.5
	collision_layer = 0
	

func change_rotation(degree: int):
	$CollisionShape2D.rotation_degrees = degree
