class_name MarchingSquaresGenerator

var noise_generator: NoiseGenerator
var threshold: float = 0.1

func _init(noise_gen: NoiseGenerator, threshold_value: float = 0.1):
	noise_generator = noise_gen
	threshold = threshold_value
	
func get_square_value(x: int, y: int) -> int:
	var val = 0
	if get_square_filled(x + 0, y + 0): val |= 1  # top-left
	if get_square_filled(x + 1, y + 0): val |= 2  # top-right
	if get_square_filled(x + 1, y + 1): val |= 4  # bottom-right
	if get_square_filled(x + 0, y + 1): val |= 8  # bottom-left
	return val
	
func get_square_filled(x: float, y: float) -> bool:
	var value = noise_generator.get_noise_value_at(x, y)
	return true if value >= threshold else false
	
func generate_polygon_points(x: int, y: int, cell_size: int) -> Array:
	var square_type = get_square_value(x, y)
	if square_type == 0:
		return []
		
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
		0: return []
		1: return [top_left, center_top, center_left]
		2: return [center_top, top_right, center_right]
		3: return [top_left, top_right, center_right, center_left]
		4: return [center_right, bottom_right, center_bottom]
		5: return [top_left, center_top, center_right, bottom_right, center_bottom, center_left]
		6: return [center_top, top_right, bottom_right, center_bottom]
		7: return [top_left, top_right, bottom_right, center_bottom, center_left]
		8: return [center_left, center_bottom, bottom_left]
		9: return [top_left, center_top, center_bottom, bottom_left]
		10: return [center_top, top_right, center_right, center_bottom, bottom_left, center_left]
		11: return [top_left, top_right, center_right, center_bottom, bottom_left]
		12: return [center_left, center_right, bottom_right, bottom_left]
		13: return [top_left, center_top, center_right, bottom_right, bottom_left]
		14: return [center_top, top_right, bottom_right, bottom_left, center_left]
		15: return [top_left, top_right, bottom_right, bottom_left]
	
	return []
