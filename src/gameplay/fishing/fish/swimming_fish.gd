class_name SwimmingFish
extends CharacterBody2D
 
# Emitted when the player left-clicks on this fish
signal clicked(fish: SwimmingFish)
 
@export var fish_data: Fish
 
@export var swim_speed: float = 50.0
@export var left_boundary: float = 50.0
@export var right_boundary: float = 500.0
@export var top_boundary: float = 200.0
@export var bottom_boundary: float = 600.0
 
@onready var sprite: Sprite2D = $Sprite2D
 
var swim_direction: Vector2 = Vector2.RIGHT
var vertical_offset: float = 0.0
var swim_time: float = 0.0
 
@export var min_turn_time: float = 2.0
@export var max_turn_time: float = 5.0
 
var turn_timer: float = 0.0
 
var player: Player
const DESPAWN_DISTANCE = 400
 
# Fish states for the fishing minigame
var hooked: bool = false    # frozen in place while the minigame is running
var fleeing: bool = false   # swimming away after the player loses
const FLEE_SPEED: float = 250.0
const FLEE_TIME: float = 1.5
 
 
func _physics_process(delta: float) -> void:
	# Hold still while the player is reeling this fish in
	if hooked:
		return
 
	# Dash away from the player, then get removed (see flee())
	if fleeing:
		velocity = Vector2(swim_direction.x * FLEE_SPEED, 0.0)
		move_and_slide()
		_update_facing_direction()
		return
 
	swim_time += delta
	turn_timer -= delta
 
	if turn_timer <= 0.0:
		swim_direction.x *= -1
		_reset_turn_timer()
 
	# Gentle up-and-down swimming motion
	vertical_offset = sin(swim_time * 2.0) * 10.0
 
	velocity.x = swim_direction.x * swim_speed
	velocity.y = vertical_offset
 
	move_and_slide()
	
	if global_position.y <= top_boundary:
		global_position.y = top_boundary
		swim_time = 0.0
 
	elif global_position.y >= bottom_boundary:
		global_position.y = bottom_boundary
		swim_time = 0.0
 
	if global_position.x >= right_boundary:
		swim_direction = Vector2.LEFT
		
	elif global_position.x <= left_boundary:
		swim_direction = Vector2.RIGHT
 
	_update_facing_direction()
 
 
func _update_facing_direction() -> void:
	if swim_direction.x > 0:
		sprite.flip_h = false
	elif swim_direction.x < 0:
		sprite.flip_h = true
		
func _reset_turn_timer() -> void:
	turn_timer = randf_range(min_turn_time, max_turn_time)
	
func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	_reset_turn_timer()
	
func _process(delta: float) -> void:
	# Don't despawn a fish that's being fished for or already escaping
	if hooked or fleeing:
		$Timer.stop()
		return
 
	var dist = player.get_distance(self.position)
	if dist > DESPAWN_DISTANCE:
		if $Timer.is_stopped():
			$Timer.start()
	else:
		$Timer.stop()
 
 
func _on_timer_timeout() -> void:
	queue_free()
 
 
# --- Click detection ---
# Fish have collision_layer = 0, so Godot's built-in click picking can't see them.
# Instead we check whether the click landed inside the fish's sprite.
func _unhandled_input(event: InputEvent) -> void:
	if hooked or fleeing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_over_sprite(event):
			get_viewport().set_input_as_handled()
			clicked.emit(self)
 
 
# make_input_local converts the click position into the sprite's own coordinates,
# which accounts for the camera, the fish's position, and the sprite's scale.
func _is_over_sprite(event: InputEventMouse) -> bool:
	var local_event := sprite.make_input_local(event) as InputEventMouse
	return sprite.get_rect().has_point(local_event.position)
 
 
# --- Called by the fish spawn manager ---
 
# Player clicked the fish: stop swimming while the minigame runs
func hook() -> void:
	hooked = true
	velocity = Vector2.ZERO
 
 
# Player lost the minigame: dash away from the player, then disappear
func flee() -> void:
	hooked = false
	fleeing = true
	if player:
		var away: float = signf(global_position.x - player.global_position.x)
		swim_direction = Vector2.LEFT if away < 0.0 else Vector2.RIGHT
	get_tree().create_timer(FLEE_TIME).timeout.connect(queue_free)
