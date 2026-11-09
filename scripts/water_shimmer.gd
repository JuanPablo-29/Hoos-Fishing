extends ColorRect
## Drives the water shimmer shader: tells it where the lantern is and how dark it is, so a warm
## column of glints appears under the lantern at night. Put this on the shimmer ColorRect.
 
## Scales the lantern's glitter column (0 turns it off).
@export var lantern_glint_strength: float = 1.0
 
var _light: Node2D
var _day_night: CanvasModulate
var _search_cooldown: float = 0.0
 
 
func _process(delta: float) -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
 
	# Both nodes live elsewhere in the scene tree, so look them up lazily (same trick as boat_rig).
	if _light == null or _day_night == null:
		_search_cooldown -= delta
		if _search_cooldown <= 0.0:
			_search_cooldown = 1.0
			if _light == null:
				_light = get_tree().get_first_node_in_group(&"lantern_light") as Node2D
			if _day_night == null:
				_day_night = get_tree().root.find_child("DayNightCycle", true, false) as CanvasModulate
 
	var darkness := 0.0
	if _day_night:
		darkness = clampf(inverse_lerp(0.95, 0.35, _day_night.color.get_luminance()), 0.0, 1.0)
	mat.set_shader_parameter("light_strength", darkness * lantern_glint_strength)
 
	if _light and is_instance_valid(_light):
		mat.set_shader_parameter("light_screen_x", _light.get_global_transform_with_canvas().origin.x)
