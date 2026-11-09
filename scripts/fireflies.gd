extends Node2D
## Fireflies that slowly fade in as night falls, drift around, and blink softly.
## Add as a child of World/EffectRoot. It reads the DayNightCycle node's time of day.
## They stay around the camera as you move, so there are always some nearby.

@export var count: int = 14

@export_group("Area")
@export var min_y: float = 55.0                      ## top of the area they hover in
@export var max_y: float = 135.0                     ## bottom of the area
@export var wander_radius: Vector2 = Vector2(14.0, 6.0)
@export var drift_speed: float = 3.0                 ## max horizontal drift, px/s
@export var margin: float = 40.0                     ## extra room past the screen edges

@export_group("Look")
@export var color: Color = Color(0.85, 1.0, 0.45)
@export var max_light_energy: float = 0.9
@export var light_scale: float = 0.32                ## glow size
@export var blink_speed_range: Vector2 = Vector2(0.8, 1.6)

@export_group("Night timing (in-game hours)")
@export var appear_start_hour: float = 18.5          ## first firefly appears
@export var appear_end_hour: float = 22.5            ## all fireflies are out
@export var vanish_start_hour: float = 4.5           ## they start fading away
@export var vanish_end_hour: float = 6.5             ## all gone
@export var fade_speed: float = 0.4                  ## higher = each fades in/out faster
@export var force_night: bool = false               ## tick to test without waiting

class Fly:
	var root: Node2D
	var sprite: Sprite2D
	var light: PointLight2D
	var home: Vector2
	var drift: float
	var wander_speed: Vector2
	var wander_phase: Vector2
	var blink_speed: float
	var blink_phase: float
	var threshold: float      # how "deep" into the night before this one appears
	var presence: float = 0.0

var _flies: Array[Fly] = []
var _t: float = 0.0
var _night_amount: float = 0.0
var _day_night: CanvasModulate
var _search_cooldown: float = 0.0


func _ready() -> void:
	_day_night = get_tree().root.find_child("DayNightCycle", true, false) as CanvasModulate
	var core := _make_core_texture()
	var glow := _make_glow_texture()
	var half := _half_width()
	var cx := _camera_x()

	for i in count:
		var f := Fly.new()
		f.root = Node2D.new()
		f.root.z_index = 3 if randf() < 0.3 else 0   # a few drift in front of the owl
		f.root.visible = false

		f.sprite = Sprite2D.new()
		f.sprite.texture = core
		f.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		f.sprite.modulate = Color(color, 0.0)

		f.light = PointLight2D.new()
		f.light.texture = glow
		f.light.texture_scale = light_scale
		f.light.color = color
		f.light.energy = 0.0

		f.root.add_child(f.sprite)
		f.root.add_child(f.light)
		add_child(f.root)

		f.home = Vector2(cx + randf_range(-half, half), randf_range(min_y, max_y))
		f.drift = randf_range(-1.0, 1.0) * drift_speed
		f.wander_speed = Vector2(randf_range(0.2, 0.5), randf_range(0.3, 0.7))
		f.wander_phase = Vector2(randf() * TAU, randf() * TAU)
		f.blink_speed = randf_range(blink_speed_range.x, blink_speed_range.y)
		f.blink_phase = randf() * TAU
		f.threshold = randf() * 0.95
		_flies.append(f)


func _process(delta: float) -> void:
	_t += delta
	_update_night_amount(delta)

	var cx := _camera_x()
	var half := _half_width()
	var span := half * 2.0

	for f in _flies:
		# Slow drift, wrapped around the camera so they never all leave the screen.
		f.home.x += f.drift * delta
		f.home.x = (cx - half) + fposmod(f.home.x - (cx - half), span)

		var offset := Vector2(
			sin(_t * f.wander_speed.x + f.wander_phase.x) * wander_radius.x,
			sin(_t * f.wander_speed.y + f.wander_phase.y) * wander_radius.y)
		f.root.position = (f.home + offset).round()   # whole pixels keeps it crisp

		# Fade this one in/out depending on how far into the night we are.
		var target := 1.0 if _night_amount >= f.threshold else 0.0
		f.presence = move_toward(f.presence, target, fade_speed * delta)

		# Soft blink with brief dark gaps.
		var pulse := 0.5 + 0.5 * sin(_t * f.blink_speed + f.blink_phase)
		var glow := smoothstep(0.2, 1.0, pulse) * f.presence

		f.root.visible = f.presence > 0.001
		f.sprite.modulate = Color(color, glow)
		f.light.energy = glow * max_light_energy


## 0 = daytime (no fireflies), 1 = full night (all fireflies).
func _update_night_amount(delta: float) -> void:
	if force_night:
		_night_amount = 1.0
		return

	if _day_night == null:
		_search_cooldown -= delta
		if _search_cooldown <= 0.0:
			_search_cooldown = 1.0
			_day_night = get_tree().root.find_child("DayNightCycle", true, false) as CanvasModulate
		_night_amount = 0.0
		return

	var h: float = _day_night.get("time_of_day")
	if h >= appear_start_hour:
		_night_amount = clampf(inverse_lerp(appear_start_hour, appear_end_hour, h), 0.0, 1.0)
	elif h < vanish_end_hour:
		_night_amount = 1.0 - clampf(inverse_lerp(vanish_start_hour, vanish_end_hour, h), 0.0, 1.0)
	else:
		_night_amount = 0.0


func _half_width() -> float:
	return get_viewport_rect().size.x * 0.5 + margin


func _camera_x() -> float:
	var cam := get_viewport().get_camera_2d()
	if cam:
		return to_local(cam.get_screen_center_position()).x
	var center := get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
	return to_local(center).x


## 3x3 pixel plus-shape: bright centre, dim arms.
func _make_core_texture() -> ImageTexture:
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(1, 1, 1, 1))
	for p in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		img.set_pixel(p.x, p.y, Color(1, 1, 1, 0.35))
	return ImageTexture.create_from_image(img)


## Soft round falloff used by each firefly's light.
func _make_glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 64
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
