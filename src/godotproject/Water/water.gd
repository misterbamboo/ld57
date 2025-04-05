extends Polygon2D

@export var water_color: Color = Color(0.0, 0.0, 1.0, 0.5)

func _ready() -> void:
	color = water_color
	uv = polygon

func _process(delta):
	pass
