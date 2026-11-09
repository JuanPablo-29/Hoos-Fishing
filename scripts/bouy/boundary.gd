extends StaticBody2D


func remove():
	$ColorRect.color = Color.BLUE
	collision_layer = 0
