extends Node2D

@export var width = 25
@export var height = 25
@export var cell_size = 25
@export var fill_percent = 60

var map = []

func _ready():
	randomize()
	build()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		build()
	
func build():
	print("regenerate_map")
	generate_map()

	# clean old Polygon2DNode
	for child in get_children():
		child.queue_free()

	# create new Polygon2DNode
	var all_polygons = generate_cave_mesh()
	for poly_points in all_polygons:
		var poly = Polygon2D.new()
		poly.color = Color(0.8, 0.9, 1.0)  # Light blue
		poly.polygon = PackedVector2Array(poly_points)
		add_child(poly)

func generate_map():
	var noise := FastNoiseLite.new()
	noise.seed = 0
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # or PERLIN, CELLULAR, etc.
	noise.frequency = 1
	noise.fractal_octaves = 10
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	
	map.resize(width + 1)
	for x in range(width + 1):
		map[x] = []
		#var row = ""
		for y in range(height + 1):
			var nx = float(x) / width
			var ny = float(y) / height
			var value = noise.get_noise_2d(nx, ny)
			var shouldFillInt = 1 if value < 0.05 else 0
			map[x].append(shouldFillInt)
			#row += str(shouldFillInt)
		#print(row)

func get_square_val(x, y):
	var val = 0
	if map[x][y] == 1: val |= 1			# top-left
	if map[x + 1][y] == 1: val |= 2		# top-right
	if map[x + 1][y + 1] == 1: val |= 4	# bottom-right
	if map[x][y + 1] == 1: val |= 8		# bottom-left
	return val

var polygons := []
func generate_cave_mesh() -> Array:
	polygons = []	
	for x in range(width):
		for y in range(height):
			var square_type = get_square_val(x, y)
			if square_type == 0:
				continue

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
				0: pass
				1: add_poly([top_left, center_top, center_left])
				2: add_poly([center_top, top_right, center_right])
				3: add_poly([top_left, top_right, center_right, center_left])
				4: add_poly([center_right, bottom_right, center_bottom])
				5: add_poly([top_left, center_top, center_right, bottom_right, center_bottom, center_left])
				6: add_poly([center_top, top_right, bottom_right, center_bottom])
				7: add_poly([top_left, top_right, bottom_right, center_bottom, center_left])
				8: add_poly([center_left, center_bottom, bottom_left])
				9: add_poly([top_left, center_top, center_bottom, bottom_left])
				10: add_poly([center_top, top_right, center_right, center_bottom, bottom_left, center_left])
				11: add_poly([top_left, top_right, center_right, center_bottom, bottom_left])
				12: add_poly([center_left, center_right, bottom_right, bottom_left])
				13: add_poly([top_left, center_top, center_right, bottom_right, bottom_left])
				14: add_poly([center_top, top_right, bottom_right, bottom_left, center_left])
				15: add_poly([top_left, top_right, bottom_right, bottom_left])
	return polygons

func add_poly(points_array: Array):
	if points_array.size() >= 3:
		polygons.append(points_array)
