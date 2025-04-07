extends Node2D

@export var target: Node2D
@export var follow_speed: float = 10.0

# Submarine depth tracking
var current_x_chunk := 0
var current_y_chunk := 0

# Background tracking
var current_background_x_chunk := 0
var current_background_y_chunk := 0

# Cell size in pixels - determines the grid for tile placement
@export var cell_size: int = 20
@export var background_cell_size: int = 128

# We want each chunk to be 16x16 tiles
const CHUNK_SIZE := 16

# Calculate tiles needed per chunk
var tiles_per_chunk_x: int: 
	get: return CHUNK_SIZE
var tiles_per_chunk_y: int:
	get: return CHUNK_SIZE

# Background tiles per chunk (may be different size)
var background_tiles_per_chunk_x: int:
	get: return CHUNK_SIZE
var background_tiles_per_chunk_y: int:
	get: return CHUNK_SIZE

# Helper method to calculate chunk coordinates in a consistent way
func get_chunk_coordinates(world_pos: Vector2, cell_size_value: int) -> Vector2:
	# Convert world position to tile coordinates
	var tile_x = int(world_pos.x / cell_size_value)
	var tile_y = int(world_pos.y / cell_size_value)
	
	# Convert tile coordinates to chunk coordinates
	var chunk_x = floor(float(tile_x) / CHUNK_SIZE)
	var chunk_y = floor(float(tile_y) / CHUNK_SIZE)
	
	return Vector2(chunk_x, chunk_y)

func _process(delta: float) -> void:
	if target != null:
		var target_position = target.position
		position = position.lerp(target_position, follow_speed * delta)
		
	_check_if_should_reload_map_viewport_chunk()
	_check_if_should_reload_map_background()

func _check_if_should_reload_map_viewport_chunk():
	# Get submarine position and calculate chunk coordinates using the helper
	var submarine_position = target.position
	var chunk_coords = get_chunk_coordinates(submarine_position, cell_size)
	var x_chunk = int(chunk_coords.x)
	var y_chunk = max(0, int(chunk_coords.y))  # Keep y non-negative (no chunks above water)
	
	# Only load if we've changed chunk in either dimension
	if current_x_chunk != x_chunk or current_y_chunk != y_chunk:
		# Debug statement for chunk boundary crossing
		print("==== CROSSING CHUNK BOUNDARY ====")
		print("Moving from chunk (%d,%d) to chunk (%d,%d)" % [current_x_chunk, current_y_chunk, x_chunk, y_chunk])
		
		# Calculate how many chunks we need to load around the player
		# Typically we want to load a 3×3 grid centered on the submarine
		var x_min = x_chunk - 1
		var x_max = x_chunk + 1
		var y_min = max(0, y_chunk - 1)  # Don't go above water
		var y_max = y_chunk + 1
		
		# Print the grid of chunks that will be loaded
		print("Chunks that will be loaded (grid):")
		
		# Print top row
		var top_row = ""
		for x in range(x_min, x_max + 1):
			if y_min == y_chunk:
				# If y_chunk is 0, then submarine is in the top row
				if x == x_chunk:
					top_row += " SUB |"
				else:
					top_row += "(%d,%d)|" % [x, y_min]
			else:
				top_row += "(%d,%d)|" % [x, y_min]
		print(top_row.substr(0, top_row.length() - 1))  # Remove trailing |
		
		# Print middle row - only if submarine isn't in the top row
		if y_min != y_chunk:
			var middle_row = ""
			for x in range(x_min, x_max + 1):
				if x == x_chunk and y_chunk == y_min + 1:
					middle_row += " SUB |"
				else:
					middle_row += "(%d,%d)|" % [x, y_min + 1]
			print(middle_row.substr(0, middle_row.length() - 1))  # Remove trailing |
		
		# Print bottom row - always show this row
		var bottom_row = ""
		for x in range(x_min, x_max + 1):
			if y_chunk == y_max:
				# If submarine is in the bottom row
				if x == x_chunk:
					bottom_row += " SUB |"
				else:
					bottom_row += "(%d,%d)|" % [x, y_max]
			else:
				bottom_row += "(%d,%d)|" % [x, y_max]
		print(bottom_row.substr(0, bottom_row.length() - 1))  # Remove trailing |
		
		# Load each chunk individually - this improves performance by generating only what's needed
		for load_x in range(x_min, x_max + 1):
			for load_y in range(y_min, y_max + 1):
				load_chunk(load_x, load_y, MapLayers.LEVEL)
		
		# Update current position
		current_x_chunk = x_chunk
		current_y_chunk = y_chunk

func _check_if_should_reload_map_background():
	# Get submarine position and calculate chunk coordinates using the helper
	var submarine_position = target.position
	var chunk_coords = get_chunk_coordinates(submarine_position, background_cell_size)
	var x_chunk = int(chunk_coords.x)
	var y_chunk = max(0, int(chunk_coords.y))  # Keep y non-negative (no chunks above water)
	
	# Only load if we've changed chunk in either dimension
	if current_background_x_chunk != x_chunk or current_background_y_chunk != y_chunk:
		# Debug statement for background chunk boundary crossing
		print("==== CROSSING BACKGROUND CHUNK BOUNDARY ====")
		print("Moving from BG chunk (%d,%d) to BG chunk (%d,%d)" % [current_background_x_chunk, current_background_y_chunk, x_chunk, y_chunk])

		# Calculate how many chunks we need to load around the player
		var x_min = x_chunk - 1
		var x_max = x_chunk + 1
		var y_min = max(0, y_chunk - 1)  # Don't go above water
		var y_max = y_chunk + 1
		
		# Print the grid of chunks that will be loaded
		print("Background chunks that will be loaded (grid):")
		
		# Print top row
		var top_row = ""
		for x in range(x_min, x_max + 1):
			if y_min == y_chunk:
				# If y_chunk is 0, then submarine is in the top row
				if x == x_chunk:
					top_row += " SUB |"
				else:
					top_row += "(%d,%d)|" % [x, y_min]
			else:
				top_row += "(%d,%d)|" % [x, y_min]
		print(top_row.substr(0, top_row.length() - 1))  # Remove trailing |
		
		# Print middle row - only if submarine isn't in the top row
		if y_min != y_chunk:
			var middle_row = ""
			for x in range(x_min, x_max + 1):
				if x == x_chunk and y_chunk == y_min + 1:
					middle_row += " SUB |"
				else:
					middle_row += "(%d,%d)|" % [x, y_min + 1]
			print(middle_row.substr(0, middle_row.length() - 1))  # Remove trailing |
		
		# Print bottom row - always show this row
		var bottom_row = ""
		for x in range(x_min, x_max + 1):
			if y_chunk == y_max:
				# If submarine is in the bottom row
				if x == x_chunk:
					bottom_row += " SUB |"
				else:
					bottom_row += "(%d,%d)|" % [x, y_max]
			else:
				bottom_row += "(%d,%d)|" % [x, y_max]
		print(bottom_row.substr(0, bottom_row.length() - 1))  # Remove trailing |
		
		# Load each chunk individually
		for load_x in range(x_min, x_max + 1):
			for load_y in range(y_min, y_max + 1):
				load_chunk(load_x, load_y, MapLayers.BACKGROUND)
		
		# Update current position
		current_background_x_chunk = x_chunk
		current_background_y_chunk = y_chunk

# New chunk-based loading method
func load_chunk(chunk_x: int, chunk_y: int, map_layer: int):
	# Make sure y is non-negative (can't go above water)
	chunk_y = max(0, chunk_y)
	
	# Debug information to help troubleshoot chunk loading
	print("Loading chunk (%d,%d) layer %d" % [chunk_x, chunk_y, map_layer])
	
	# Simply send the chunk coordinates to the map generator
	EventBus.raise(LoadMapChunkEvent.new(map_layer, chunk_x, chunk_y))

# Legacy method for backward compatibility
func load_page_2d(x_page: int, y_page: int, map_layer: int):
	# Convert page coordinates to chunk coordinates and use the new system
	# Note: This assumes a 1:1 mapping between pages and chunks for compatibility
	load_chunk(x_page, y_page, map_layer)

# Legacy method for backward compatibility
func load_page(page: int, map_layer: int, _rows_per_page: float):
	# Convert to chunk coordinates
	load_chunk(0, page, map_layer)
