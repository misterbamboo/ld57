class_name ExplosionEvent
extends GameEvent

var position: Vector2
var radius: float
var bounds_rect: Rect2

func _init(pos: Vector2, rad: float, bounds: Rect2):
	position = pos
	radius = rad
	bounds_rect = bounds

func get_name() -> String:
	return "ExplosionEvent"
