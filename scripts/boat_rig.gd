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
@export_group("Reflection")
@export var reflection_enabled: bool = true
## Where the boat meets the water, in rig-local pixels (the bottom of the solid hull).
@export var waterline_y: float = 16.0
## Rig-local y of the hull's top rim; the owl below this line is hidden behind the hull.
@export var owl_visible_above_y: float = 7.0
@export var reflection_alpha: float = 0.42
## How far below the waterline (screen pixels) the reflection takes to fade out.
@export var reflection_fade_depth: float = 34.0
 
@onready var _lantern_pivot: Node2D = $LanternPivot
@onready var _light: PointLight2D = $LanternPivot/Light
@onready var _body := get_parent() as CharacterBody2D
 
const REFLECTION_SHADER := preload("res://shaders/water_reflection.gdshader")
 
var _t: float = 0.0
var _lag: float = 0.0
var _base_y: float = 0.0
var _passenger_base_y: float = 0.0
var _day_night: CanvasModulate
var _search_cooldown: float = 0.0
var _reflection: Node2D
var _reflection_mat: ShaderMaterial
var _reflection_pivot: Node2D
var _reflection_owl: AnimatedSprite2D
var _reflection_owl_mat: ShaderMaterial
 
 
func _ready() -> void:
	_base_y = position.y
	if passenger:
		_passenger_base_y = passenger.position.y
	# The shimmer shader looks the lantern up by group to draw its glint column.
	_light.add_to_group(&"lantern_light")
	if reflection_enabled:
		_build_reflection()
 
 
## Mirrors the whole rig (boat, pole and lantern) to match the owl's facing.
func set_facing_left(left: bool) -> void:
	scale.x = -absf(scale.x) if left else absf(scale.x)
 
 
func _process(delta: float) -> void:
	_t += delta
	_update_bobbing()
	_update_lantern_swing(delta)
	_update_light(delta)
	_update_reflection()
 
 
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
 
 
## Builds a mirrored copy of the boat, lantern and owl that hangs below the waterline.
## It is a child of the rig, so it follows the boat sideways and flips with its facing; the
## water_reflection shader wobbles it, fades it out and hides anything above the waterline.
func _build_reflection() -> void:
	_reflection_mat = ShaderMaterial.new()
	_reflection_mat.shader = REFLECTION_SHADER
	_reflection_mat.set_shader_parameter("use_world_depth", true)
	_reflection_mat.set_shader_parameter("pixel_size", 2.0)  # the rig is drawn at 2x
	_reflection_mat.set_shader_parameter("max_alpha", reflection_alpha)
	_reflection_mat.set_shader_parameter("fade_depth", reflection_fade_depth)
	_reflection_mat.set_shader_parameter("tint_amount", 0.45)
	_reflection_mat.set_shader_parameter("ripple_px", 2.0)
 
	# Everything inside is mirrored (scale.y = -1) about the waterline. A child that sits at
	# rig-local y appears at 2 * waterline_y - y, so its position is shifted by waterline_y.
	_reflection = Node2D.new()
	_reflection.name = "WaterReflection"
	_reflection.position = Vector2(0.0, waterline_y)
	_reflection.scale = Vector2(1.0, -1.0)
	_reflection.z_index = -1          # above the water, below the real boat
	_reflection.material = _reflection_mat
	add_child(_reflection)
 
	var shift := Vector2(0.0, waterline_y)
	for node_name in ["Hull", "LanternPost"]:
		var src := get_node_or_null(node_name) as Sprite2D
		if src == null:
			continue
		var copy := src.duplicate() as Sprite2D
		copy.position = src.position - shift
		copy.z_index = 1 if node_name == "Hull" else 0
		copy.use_parent_material = true
		_reflection.add_child(copy)
 
	_reflection_pivot = Node2D.new()
	_reflection_pivot.position = _lantern_pivot.position - shift
	_reflection_pivot.use_parent_material = true
	_reflection.add_child(_reflection_pivot)
	var lantern_src := _lantern_pivot.get_node_or_null("Lantern") as Sprite2D
	if lantern_src:
		var lantern_copy := lantern_src.duplicate() as Sprite2D
		lantern_copy.use_parent_material = true
		_reflection_pivot.add_child(lantern_copy)
 
	var owl_src := passenger as AnimatedSprite2D
	if owl_src:
		_reflection_owl = owl_src.duplicate() as AnimatedSprite2D
		# The owl is a sibling of the rig at 2x, the rig is also 2x, so it is 1x in rig space.
		_reflection_owl.position = (owl_src.position - position) / scale.abs() - shift
		_reflection_owl.scale = Vector2(1.0, 1.0)
		# The hull hides the owl's lower body, so hide that part of its reflection too
		# (otherwise it shows through the translucent hull reflection). Own material copy for that.
		_reflection_owl_mat = _reflection_mat.duplicate() as ShaderMaterial
		_reflection_owl_mat.set_shader_parameter("min_depth", (waterline_y - owl_visible_above_y) * absf(scale.y))
		_reflection_owl.material = _reflection_owl_mat
		_reflection.add_child(_reflection_owl)
 
 
func _update_reflection() -> void:
	if _reflection == null:
		return
	# The rig bobs but the water line does not: counter the bob so the reflection stays put.
	var bob := position.y - _base_y
	_reflection.position.y = waterline_y - bob / absf(scale.y)
	var axis_y := _reflection.global_position.y
	_reflection_mat.set_shader_parameter("axis_y", axis_y)
	if _reflection_owl_mat:
		_reflection_owl_mat.set_shader_parameter("axis_y", axis_y)
 
	_reflection_pivot.rotation = _lantern_pivot.rotation
 
	if _reflection_owl:
		var owl := passenger as AnimatedSprite2D
		if _reflection_owl.animation != owl.animation:
			_reflection_owl.animation = owl.animation
		_reflection_owl.frame = owl.frame
		_reflection_owl.flip_h = owl.flip_h
		# The rig mirrors when the owl faces left; cancel that so the owl copy isn't flipped twice.
		_reflection_owl.scale.x = signf(scale.x)
