class_name ShopBoatMovement extends Sprite2D

@export var playerSub: Node2D

@export var boat_length := 512
@export var sample_count := 10  # More = smoother
@export var offsety := -80

func _process(delta: float) -> void:
	var water = Water.instance
	
	var center_x = position.x
	var half_length = boat_length / 2.0
	var spacing = boat_length / (sample_count - 1)
	var start_x = center_x - boat_length / 2
	
	var sample_points: Array[Vector2] = []
	var sum_y = 0.0
	
	for i in range(sample_count):
		var x = start_x + i * spacing
		var y = water.surface_variation(x)
		sample_points.append(Vector2(x, y))
		sum_y += y
		
	var average_y = sum_y / sample_count
	position.y = lerp(position.y, average_y + offsety, delta * 5)
	
	var front = sample_points[sample_count - 1]
	var back = sample_points[0]
	var angle = atan2(front.y - back.y, front.x - back.x)
	rotation = lerp_angle(rotation, angle, delta * 5)
