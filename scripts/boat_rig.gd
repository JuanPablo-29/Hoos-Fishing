extends Node2D
## Visual rig for the owl's boat: bobs on the water, swings the hanging lantern,
## and drives the lantern's light so it glows more as the day/night cycle gets darker.
##
## The owl's AnimatedSprite2D (the "passenger") is bobbed and tilted together with the boat
## so the owl stays seated in it.

@export var passenger: Node2D
@export_group("Boat")
@export var bob_height: float = 1.0          ## pixels
@export var bob_speed: float = 0.7           ## radians per second (lower = slower)
@export var sway_degrees: float = 0.0          ## tilt; 0 avoids shimmery rotated pixels
@export var snap_bob_to_pixels: bool = true
@export_group("Lantern")
@export var lantern_idle_swing_degrees: float = 2.5
@export var lantern_motion_swing_degrees: float = 8.0
@export var max_speed_for_swing: float = 500.0
@export var light_day_energy: float = 0.1
@export var light_night_energy: float = 1.3

@onready var _lantern_pivot: Node2D = $LanternPivot
@onready var _light: PointLight2D = $LanternPivot/Light
@onready var _body := get_parent() as CharacterBody2D

var _t: float = 0.0
var _lag: float = 0.0
var _base_y: float = 0.0
var _passenger_base_y: float = 0.0
var _day_night: CanvasModulate
var _search_cooldown: float = 0.0


func _ready() -> void:
	_base_y = position.y
	if passenger:
		_passenger_base_y = passenger.position.y


## Mirrors the whole rig (boat, pole and lantern) to match the owl's facing.
func set_facing_left(left: bool) -> void:
	scale.x = -absf(scale.x) if left else absf(scale.x)


func _process(delta: float) -> void:
	_t += delta
	_update_bobbing()
	_update_lantern_swing(delta)
	_update_light(delta)


func _update_bobbing() -> void:
	var phase := _t * bob_speed
	var bob := sin(phase) * bob_height
	if snap_bob_to_pixels:
		bob = roundf(bob)
	var sway := sin(phase * 0.8 + 1.0) * deg_to_rad(sway_degrees)
	position.y = _base_y + bob
	rotation = sway
	if passenger:
		passenger.position.y = _passenger_base_y + bob
		passenger.rotation = sway


func _update_lantern_swing(delta: float) -> void:
	var facing := signf(scale.x)
	var vx := _body.velocity.x if _body else 0.0
	# The lantern trails behind the direction of travel, then settles back.
	var target := clampf(vx / max_speed_for_swing, -1.0, 1.0) * deg_to_rad(lantern_motion_swing_degrees)
	_lag = lerpf(_lag, target, 1.0 - exp(-6.0 * delta))
	var idle := sin(_t * 0.8 + 0.7) * deg_to_rad(lantern_idle_swing_degrees)
	# Flipping the rig mirrors local rotation, so multiply by facing.
	_lantern_pivot.rotation = facing * (idle + _lag)


func _update_light(delta: float) -> void:
	if _day_night == null:
		_search_cooldown -= delta
		if _search_cooldown <= 0.0:
			_search_cooldown = 1.0
			_day_night = get_tree().root.find_child("DayNightCycle", true, false) as CanvasModulate

	var darkness := 0.6  # sensible default if there is no day/night node
	if _day_night:
		darkness = clampf(inverse_lerp(0.95, 0.35, _day_night.color.get_luminance()), 0.0, 1.0)

	var flicker := 1.0 + sin(_t * 11.0) * 0.05 + sin(_t * 17.3 + 1.3) * 0.03
	_light.energy = lerpf(light_day_energy, light_night_energy, darkness) * flicker
