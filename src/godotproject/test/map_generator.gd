extends Node2D

@export var width = 1
@export var height = 2
@export var cell_size = 25
@export var fill_percent = 75

var map = []

@onready var poly = $Polygon2D

func _ready():
	randomize()
	regenerate_map()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		regenerate_map()
	
func regenerate_map():
	generate_map()
	var mesh_points = generate_mesh()
	poly.polygon = PackedVector2Array(mesh_points)
	#poly.polygon = PackedVector2Array([
		#mesh_points[0],
		#mesh_points[1],
		#mesh_points[2],
		#mesh_points[3],
		#mesh_points[4],
		#mesh_points[5],
		#mesh_points[6],
		#mesh_points[7],
		#mesh_points[8],
	#])
	poly.color = Color(0.8, 0.9, 1.0)  # Light blue
	#poly.texture = preload("res://cave_texture.png")

func generate_map():
	map.resize(width + 1)
	for x in range(width + 1):
		map[x] = []
		for y in range(height + 1):
			var rand = randi() % 100
			var shouldFill = rand < fill_percent
			var shouldFillInt = 1 if shouldFill else 0
			map[x].append(shouldFillInt)

# Get value from the 2x2 cell
func get_square_val(x, y):
	var val = 0
	if map[x][y] == 1: val |= 1
	if map[x + 1][y] == 1: val |= 2
	if map[x + 1][y + 1] == 1: val |= 4
	if map[x][y + 1] == 1: val |= 8
	return val

func generate_mesh():
	var points = []
	for x in range(width):
		for y in range(height):
			var square_type = get_square_val(x, y)
			var pos = Vector2(x, y) * cell_size

			var top_left     = pos
			var top_right    = pos + Vector2(cell_size, 0)
			var bottom_right = pos + Vector2(cell_size, cell_size)
			var bottom_left  = pos + Vector2(0, cell_size)

			var center_top    = pos + Vector2(cell_size * 0.5, 0)
			var center_right  = pos + Vector2(cell_size, cell_size * 0.5)
			var center_bottom = pos + Vector2(cell_size * 0.5, cell_size)
			var center_left   = pos + Vector2(0, cell_size * 0.5)

			match square_type:
				0: pass # Empty
				1: points.append_array([bottom_left, center_left, center_bottom])
				2: points.append_array([center_bottom, center_right, bottom_right])
				3: points.append_array([bottom_left, center_left, center_right, bottom_right])
				4: points.append_array([top_right, center_top, center_right])
				5: points.append_array([bottom_left, center_left, center_top, top_right, center_right, center_bottom])
				6: points.append_array([center_top, top_right, bottom_right, center_bottom])
				7: points.append_array([bottom_left, center_left, center_top, top_right, bottom_right])
				8: points.append_array([top_left, center_top, center_left])
				9: points.append_array([top_left, center_top, center_bottom, bottom_left])
				10: points.append_array([top_left, center_top, center_right, bottom_right, center_bottom, center_left])
				11: points.append_array([top_left, center_top, center_right, bottom_right, bottom_left])
				12: points.append_array([top_left, top_right, center_right, center_left])
				13: points.append_array([top_left, top_right, bottom_right, center_bottom, center_left])
				14: points.append_array([top_left, top_right, bottom_right, bottom_left, center_left])
				15: points.append_array([top_left, top_right, bottom_right, bottom_left])
				
	return points

# Find regions
var region_id_map = []
var region_counter = 1

func label_regions():
	region_id_map.resize(width)
	for x in range(width):
		region_id_map[x] = []
		for y in range(height):
			region_id_map[x].append(0)

	for x in range(width):
		for y in range(height):
			if map[x][y] == 1 and region_id_map[x][y] == 0:
				flood_fill_region(x, y, region_counter)
				region_counter += 1

func flood_fill_region(x, y, id):
	var stack = [Vector2i(x, y)]
	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = current.x
		var cy = current.y
		if cx < 0 or cy < 0 or cx >= width or cy >= height:
			continue
		if map[cx][cy] == 0 or region_id_map[cx][cy] != 0:
			continue

		region_id_map[cx][cy] = id

		stack.append(Vector2i(cx + 1, cy))
		stack.append(Vector2i(cx - 1, cy))
		stack.append(Vector2i(cx, cy + 1))
		stack.append(Vector2i(cx, cy - 1))
