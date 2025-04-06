class_name MapGenerator extends Node2D

static var instance: MapGenerator = null

@export var width = 50
@export var cell_size = 50
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@export var source_id: int = 0  # TileSet source ID
@export var debug_show_mesh: bool = false  # Toggle to show/hide the polygon mesh for debugging

var pool_size = 200 
var polygon_pool: Array[Polygon2D] = []
var polygon_index := 0

# START: noiseLayers
var _noisesLayers : Array[FastNoiseLite] = [
	FastNoiseLite.new(),
	FastNoiseLite.new(),
	FastNoiseLite.new(),
	FastNoiseLite.new(),
	FastNoiseLite.new(),
]
var noise_weight: Array[float] 				= [1.00, 0.50, 1.00, 0, 0]
var noise_y_gradient: Array[float] 			= [06.5, 37.5, 0.00, 0, 0]
var noise_seed: Array[float] 				= [21.0, 21.0, 0.00, 0, 0]
var noise_frequency: Array[float] 			= [0.18, 0.11, 0.12, 0, 0]
var noise_fractal_octaves: Array[float] 	= [7.40, 7.00, 0.00, 0, 0]
var noise_fractal_lacunarity: Array[float] 	= [0.87, 0.65, 0.00, 0, 0]
var noise_fractal_gain: Array[float] 		= [0.58, 0.01, 0.00, 0, 0]
# End: noiseLayers

func setNoise(layerIndex: int, weight: float, yGradient: float, seed: float, frequency: float, fractal_octaves: float, fractal_lacunarity: float, fractal_gain: float):
	self.noise_weight[layerIndex] = weight
	self.noise_y_gradient[layerIndex] = yGradient
	self.noise_seed[layerIndex] = seed
	self.noise_frequency[layerIndex]  = frequency
	self.noise_fractal_octaves[layerIndex]  = fractal_octaves
	self.noise_fractal_lacunarity[layerIndex]  = fractal_lacunarity
	self.noise_fractal_gain[layerIndex]  = fractal_gain

func _ready():
	instance = self
	# We'll keep the polygon pool for backward compatibility or future use
	_init_pool()
	randomize()
	build(0, 20)

func _init_pool():
	for i in pool_size:
		createPolygon()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		build(0, 20)
	
func build(from: int, to: int):
	from = clamp(from, 0, INF)
	
	# Clear existing tiles
	clear_tiles(from, to)
	
	# Generate new tilemap
	generate_tilemap(from, to)
	
	# Also generate polygon mesh for backward compatibility or debugging
	if debug_show_mesh:
		generate_polygon_mesh(from, to)
	else:
		# Hide all polygons when debug mesh is disabled
		for poly in polygon_pool:
			poly.visible = false

func clear_tiles(from_y: int, to_y: int):
	# Clear the tiles in the specified range
	for x in range(width):
		for y in range(from_y, to_y):
			tile_map_layer.erase_cell(Vector2i(x, y))

func generate_tilemap(from_y: int, to_y: int):
	for x in range(width):
		for y in range(from_y, to_y):
			var square_type = get_square_val(x, y)
			
			# Skip empty tiles
			if square_type == 0:
				continue
				
			# Calculate the tile coordinates in the 2D grid (8 tiles per row)
			var tile_x = square_type % 8  # Remainder when divided by 8
			var tile_y = square_type / 8  # Integer division by 8
			
			# Place tile on the tilemap using 2D coordinates
			tile_map_layer.set_cell(
				Vector2i(x, y),          # Cell coordinates
				source_id,               # TileSet source ID
				Vector2i(tile_x, tile_y) # Atlas coordinates for 2D grid
			)

# Keep the polygon generation for backward compatibility or debugging
func generate_polygon_mesh(from: int, to: int):
	polygon_index = 0
	var all_polygons = generate_cave_mesh(from, to)
	for poly_points in all_polygons:
		var poly = _get_next_polygon()
		poly.visible = true
		poly.polygon = PackedVector2Array(poly_points)
		
	# Hide unused polygons
	for i in range(polygon_index, polygon_pool.size()):
		polygon_pool[i].visible = false

func _get_next_polygon() -> Polygon2D:
	if polygon_index < polygon_pool.size():
		var poly = polygon_pool[polygon_index]
		polygon_index += 1
		return poly
	else:
		# en cas de dépassement du pool
		polygon_index += 1
		return createPolygon()

func createPolygon() -> Polygon2D:
	var poly = Polygon2D.new()
	poly.color = Color(0.8, 0.7, 0.5) # Sandstone-like
	poly.visible = false
	polygon_pool.append(poly)
	add_child(poly)
	return poly

func get_square_val(x, y):
	var val = 0
	if get_square_filled(x + 0, y + 0): val |= 1	# top-left
	if get_square_filled(x + 1, y + 0): val |= 2	# top-right
	if get_square_filled(x + 1, y + 1): val |= 4	# bottom-right
	if get_square_filled(x + 0, y + 1): val |= 8	# bottom-left
	return val

func get_square_filled(x: float, y: float) -> bool:
	var value = getNoiseValueAt(x, y)
	return true if value >= 0.1 else false

var polygons := []
func generate_cave_mesh(topViewport: int, bottomViewport: int) -> Array:
	polygons = []	
	for x in range(width):
		# Draw the polygons for each square in x but only if the square is not empty
		# and only if square are between the top and bottom viewport
		#if x < topViewport or x > bottomViewport:
		# create a range between the top and bottom viewport
		for y in range(topViewport, bottomViewport):
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

func getNoiseValueAt(x: float, y: float) -> float:
	var blended_value: float = 0
	for i in range(_noisesLayers.size()):
		var val = _getNoiseValueAtLayer(i, x, y)
		var weight = noise_weight[i]
		var weighted_value = val * weight
		if(blended_value == 0):
			blended_value = weighted_value
		elif(weighted_value > 0):
			blended_value *= weighted_value
	return blended_value

func _getNoiseValueAtLayer(layerIndex: int, x: float, y: float) -> float:
	var noise = _getNoise(layerIndex)
	var raw_value = noise.get_noise_2d(x, y)
	var yGradient = noise_y_gradient[layerIndex]
	if(yGradient <= 0):
		return raw_value
	else:
		var percent = y / yGradient
		return raw_value * percent

func _getNoise(layerIndex: int):
	_noisesLayers[layerIndex].seed = self.noise_seed[layerIndex]
	_noisesLayers[layerIndex].noise_type = FastNoiseLite.TYPE_PERLIN  # or PERLIN, CELLULAR, etc.
	_noisesLayers[layerIndex].frequency = self.noise_frequency[layerIndex]
	_noisesLayers[layerIndex].fractal_octaves = self.noise_fractal_octaves[layerIndex]
	_noisesLayers[layerIndex].fractal_lacunarity = self.noise_fractal_lacunarity[layerIndex]
	_noisesLayers[layerIndex].fractal_gain = self.noise_fractal_gain[layerIndex]
	return _noisesLayers[layerIndex]
