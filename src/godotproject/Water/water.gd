class_name Water extends Polygon2D

static var instance: Water = null

@export var followCam: Camera2D

@export var water_surface_color: Color = Color(0.406, 0.592, 1.0, 0.33)
@export var water_depth_color: Color = Color(0, 0, 0.423, 0.806)

@export var width: float = 1400.0
@export var height: float = 1000.0
@export var surface_resolution: float = 1.0

@export var depthMax := 5000.0

var points: PackedVector2Array
var time: float = 0

func _ready() -> void:
	instance = self
	points = PackedVector2Array()
	
	var steps = width / surface_resolution

	for s in range(0, steps):
		var x = s * surface_resolution
		var y = 0
		points.append(Vector2(x, y))
		
	points.append(Vector2(width, 0))
	points.append(Vector2(width, height))
	points.append(Vector2(0, height))

	color = water_surface_color
	polygon = points
	uv = points

func _process(delta: float):
	time += delta
	follow_cam()
	draw_surface()
	change_depth_color()

func follow_cam():
	var centerHeight = height/2
	var waterY = 0
	if(followCam.position.y > centerHeight):
		waterY = followCam.position.y - centerHeight
	position = Vector2(followCam.position.x - width/2,waterY)

func draw_surface():
	if(points == null || points.size() < 1):
		return
	for i in range(0, points.size() - 3):
		var render_x = position.x + i
		points[i].y = surface_variation(render_x)
	polygon = points
	
func change_depth_color():
	var depthRatio = position.y / depthMax
	color = lerp(water_surface_color, water_depth_color, depthRatio)
	
func surface_variation(x: float) -> float:
	var t1 = time * 10 + x
	var wave1 = sin(t1 * 0.1) * 3
	var t2 = time * 2 - x
	var wave2 = cos(t2 * 0.5) * .4
	var t3 = time * 0.5 + x
	var wave3 = sin(t1 * 0.01) * 15
	return wave1 + wave2 + wave3
