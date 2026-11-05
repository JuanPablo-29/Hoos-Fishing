extends Node2D
@export var pipe: Area2D
var score = 0
var goal = randi_range(5, 15)

signal finished(success: bool)
var auto_start := true

func _ready() -> void:
	if auto_start: start()

# Called when the node enters the scene tree for the first time.
func start(diff: float = 0.5) -> void:
	$Bird.flying = true
	$Bird.flap()
	$Score.text = str(score)
	$Goal.text = "Goal: %d" %goal
	pipe.position.y = randf_range($PipeTop.position.y, $PipeBottom.position.y)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and $Bird.flying:
		$Bird.flap()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if pipe.position.x > $End.position.x:
		pipe.position.x -= 0.75
	else:
		pipe.position.x = $Start.position.x
		pipe.position.y = randf_range($PipeTop.position.y, $PipeBottom.position.y)

	if $Bird.position.y > $End.position.y or $Bird.position.y < $Start.position.y:
		_finish(false)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Bird":
		_finish(false)


func _on_point_area_body_exited(body: Node2D) -> void:
	if body.name == "Bird":
		score += 1
		$Score.text = str(score)
		if score >= goal:
			_finish(true)

var active:= true
func _finish(success: bool) -> void:
	if not active:
		return
	active = false
	$Bird.flying=false
	print("Caught it!" if success else "It got away...")
	finished.emit(success)
