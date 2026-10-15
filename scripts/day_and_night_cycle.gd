class_name DayNightCycle
extends CanvasModulate
## Tints the world based on an in-game time of day.
## Add this as a child of World. CanvasLayers (HUD, pause menu) are not tinted.
 
signal hour_changed(hour: int)
signal period_changed(period: String)  # "night", "dawn", "day", "dusk"
 
## Real seconds for one full 24h in-game day.
@export var day_length_seconds: float = 120.0
## In-game hour (0-24) the game starts at.
@export_range(0.0, 24.0) var start_hour: float = 8.0
## Set to false to freeze time (handy for debugging).
@export var running: bool = true
## Multiplier on time speed (handy for debugging).
@export var time_scale: float = 1.0
 
## Current in-game time in hours, 0.0 - 24.0
var time_of_day: float = 8.0
 
var _gradient: Gradient = Gradient.new()
var _last_hour: int = -1
var _last_period: String = ""
 
 
func _ready() -> void:
	time_of_day = start_hour
	_build_gradient()
	_apply()
 
 
func _process(delta: float) -> void:
	if not running:
		return
	time_of_day = fposmod(time_of_day + delta * time_scale * 24.0 / day_length_seconds, 24.0)
	_apply()
 
 
func get_period() -> String:
	if time_of_day >= 6.5 and time_of_day < 17.0:
		return "day"
	if time_of_day >= 17.0 and time_of_day < 20.0:
		return "dusk"
	if time_of_day >= 5.0 and time_of_day < 6.5:
		return "dawn"
	return "night"
 
 
func is_night() -> bool:
	return get_period() == "night"
 
 
func _apply() -> void:
	color = _gradient.sample(time_of_day / 24.0)
 
	var hour := int(time_of_day)
	if hour != _last_hour:
		_last_hour = hour
		hour_changed.emit(hour)
	var period := get_period()
	if period != _last_period:
		_last_period = period
		period_changed.emit(period)
 
 
# Colours are keyed by hour of day; tweak these to change the look.
func _build_gradient() -> void:
	var stops := [
		[0.0,  Color(0.20, 0.22, 0.42)],  # midnight
		[5.0,  Color(0.25, 0.28, 0.50)],  # pre-dawn
		[6.5,  Color(1.00, 0.78, 0.65)],  # sunrise
		[8.5,  Color(1.00, 1.00, 1.00)],  # full day
		[16.5, Color(1.00, 1.00, 1.00)],  # still full day
		[18.5, Color(1.00, 0.62, 0.45)],  # sunset
		[20.0, Color(0.42, 0.36, 0.62)],  # dusk
		[22.0, Color(0.20, 0.22, 0.42)],  # night
		[24.0, Color(0.20, 0.22, 0.42)],  # wraps to midnight
	]
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for s in stops:
		offsets.append(s[0] / 24.0)
		colors.append(s[1])
	_gradient.offsets = offsets
	_gradient.colors = colors
