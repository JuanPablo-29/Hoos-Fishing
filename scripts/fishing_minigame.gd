extends Node2D
## Attach to the root "FishingMinigame" node.
## Expected children (Sprite2D): FishingFrame, CatchZone, ProgressMeter, MovingFish
##
## Hold left mouse / Space / Enter (or a "reel" action if you add one) to lift the catch zone.
 
signal finished(success: bool)
 
@export var auto_start := true            # handy for testing with F6; turn off when called from your game
@export_range(0.0, 1.0) var difficulty := 0.5
 
# --- Where the playable track is inside Fishing Bar.png (24x120 image) ---
@export var track_inset_top := 3.0        # navy area starts 3px below the top of the sprite
@export var track_height := 114.0         # navy area is 114px tall
 
# --- Where the empty slot is inside Progress Bar.png (6x120 image) ---
@export var meter_inset := Vector2(1, 2)
@export var meter_size := Vector2(4, 116)
@export var meter_color := Color(0.49, 0.76, 0.25)
 
# --- Catch zone physics (tuned for a ~114px track) ---
@export var gravity := 200.0
@export var lift := 400.0
@export var max_speed := 130.0
@export var bounce_factor := 0.3
 
# --- Catch progress ---
@export var catch_gain := 0.25            # per second while the fish is in the zone
@export var catch_loss := 0.12            # per second while it isn't
@export var start_progress := 0.3
 
@onready var frame: Sprite2D = $FishingFrame
@onready var catch_zone: Sprite2D = $CatchZone
@onready var meter: Sprite2D = $ProgressMeter
@onready var fish: Sprite2D = $MovingFish
 
var active := false
var progress := 0.0
 
# All of these are measured from the top of the track (0 = top, track_height = bottom)
var zone_y := 0.0      # top edge of the catch zone
var zone_vel := 0.0    # positive = moving down
var fish_y := 0.0      # center of the fish
var fish_target := 0.0
var retarget_timer := 0.0
 
var track_top := 0.0   # y position of the track top, in this node's local space
var zone_h := 15.0
var fish_h := 8.0
var fish_speed := 60.0
var fish_jump := 50.0
var retarget_min := 0.4
var retarget_max := 1.2
 
 
func _ready() -> void:
	if auto_start:
		start(difficulty)
 
 
## Call this when the player hooks a fish. difficulty: 0.0 (easy) to 1.0 (hard)
func start(diff: float = 0.5) -> void:
	fish_speed = lerpf(35.0, 90.0, diff)
	fish_jump = lerpf(35.0, 75.0, diff)
	retarget_max = lerpf(1.6, 0.7, diff)
 
	zone_h = catch_zone.texture.get_height() * catch_zone.scale.y
	fish_h = fish.texture.get_height() * fish.scale.y
	track_top = _top_left(frame).y + track_inset_top
 
	progress = start_progress
	zone_y = track_height - zone_h
	zone_vel = 0.0
	fish_y = track_height * 0.5
	fish_target = fish_y
	retarget_timer = 0.0
	active = true
	_apply_positions()
 
 
func _process(delta: float) -> void:
	if not active:
		return
	_update_zone(delta)
	_update_fish(delta)
	_update_progress(delta)
	_apply_positions()
 
 
func _is_reeling() -> bool:
	if InputMap.has_action("reel") and Input.is_action_pressed("reel"):
		return true
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept")
 
 
func _update_zone(delta: float) -> void:
	if _is_reeling():
		zone_vel -= lift * delta
	else:
		zone_vel += gravity * delta
	zone_vel = clampf(zone_vel, -max_speed, max_speed)
	zone_y += zone_vel * delta
 
	if zone_y < 0.0:                       # ceiling: stop
		zone_y = 0.0
		zone_vel = 0.0
	var max_y := track_height - zone_h
	if zone_y > max_y:                     # floor: small bounce
		zone_y = max_y
		zone_vel = -zone_vel * bounce_factor if absf(zone_vel) > 30.0 else 0.0
 
 
func _update_fish(delta: float) -> void:
	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = randf_range(retarget_min, retarget_max)
		fish_target = clampf(
			fish_y + randf_range(-fish_jump, fish_jump),
			fish_h * 0.5,
			track_height - fish_h * 0.5
		)
	fish_y = move_toward(fish_y, fish_target, fish_speed * delta)
 
 
func _update_progress(delta: float) -> void:
	# Count it as "in the zone" if the fish overlaps the zone at all
	var fish_in_zone := (fish_y + fish_h * 0.5 >= zone_y) and (fish_y - fish_h * 0.5 <= zone_y + zone_h)
	progress += (catch_gain if fish_in_zone else -catch_loss) * delta
	progress = clampf(progress, 0.0, 1.0)
 
	if progress >= 1.0:
		_finish(true)
	elif progress <= 0.0:
		_finish(false)
 
 
func _finish(success: bool) -> void:
	active = false
	print("Caught it!" if success else "It got away...")
	finished.emit(success)
 
 
func _apply_positions() -> void:
	_set_center_y(catch_zone, track_top + zone_y + zone_h * 0.5)
	_set_center_y(fish, track_top + fish_y)
	queue_redraw()
 
 
# Draws the progress fill. This node draws BEFORE its children, so the fill
# shows through the transparent slot of the ProgressMeter sprite on top of it.
func _draw() -> void:
	if meter == null:
		return
	var slot := Rect2(_top_left(meter) + meter_inset, meter_size)
	var fill_h := slot.size.y * progress
	draw_rect(Rect2(slot.position.x, slot.end.y - fill_h, slot.size.x, fill_h), meter_color)
 
 
# --- Helpers so this works whether or not the sprites have "Centered" on ---
func _top_left(s: Sprite2D) -> Vector2:
	var size := s.texture.get_size() * s.scale
	var tl := s.position + s.offset * s.scale
	if s.centered:
		tl -= size * 0.5
	return tl
 
 
func _set_center_y(s: Sprite2D, center_y: float) -> void:
	var half := s.texture.get_height() * s.scale.y * 0.5
	var origin_to_center := s.offset.y * s.scale.y
	if not s.centered:
		origin_to_center += half
	s.position.y = center_y - origin_to_center
