@tool
class_name MapGenerator extends Node2D

# Signals for debug visualization
signal chunk_loaded(chunk_x, chunk_y, bounds_rect, from_cache)
signal explosion_occurred(center_position, radius, bounds_rect)

# Configuration
@export var map_layer: int = 0
@export var width: int = 50
@export var cell_size: int = 50
@export var source_id: int = 0
@export var render_distance: int = 1  # Number of chunks to render around player (1 = 3x3 grid, 2 = 5x5, etc.)
@export var max_cached_chunks: int = 50  # Maximum number of chunks to keep in cache

# Debug visualization options - kept for backwards compatibility
@export var debug_cached_chunk_color: Color = Color(0, 1, 0, 0.2)  # Green tint for cached chunks
@export var debug_new_chunk_color: Color = Color(1, 0.5, 0, 0.2)  # Orange tint for newly generated chunks

# Chunk configuration
const CHUNK_SIZE := 16

# Tracking
var current_center_chunk_x: int = 0
var current_center_chunk_y: int = 0
var active_chunks: Dictionary = {}  # Track which chunks are currently loaded

# Chunk cache
var chunk_cache: ChunkCache

# Core components
var noise_generator: NoiseGenerator
var marching_squares: MarchingSquaresGenerator
var renderer: MapRenderer = null

func _ready():
	if Engine.is_editor_hint():
		return
		
	# Initialize all components
	initialize_components()
	connect_signals()
	build_initial_map()
	
func initialize_components():
	# Initialize noise generation system
	noise_generator = NoiseGenerator.new()
	marching_squares = MarchingSquaresGenerator.new(noise_generator)
	
	# Initialize chunk cache with max size from export variable
	chunk_cache = ChunkCache.new(max_cached_chunks)
	
	# Find the renderer and setup noise parameters
	_find_renderer_node()
	_setup_default_noise_params()

func connect_signals():
	# Connect to event bus for chunk loading events
	EventBus.register(LoadMapChunkEvent.event_name, self._on_load_map_chunk_event)
	
	# Restore explosion connection if it was previously used
	if ExplosionMap.has_method("on_explosion"):
		ExplosionMap.on_explosion.connect(addExplosionAt)

func build_initial_map():
	# Only build initial map if not in editor
	if not Engine.is_editor_hint() and renderer != null:
		# Build the initial chunk around origin
		var initial_chunks = get_chunks_in_render_distance(0, 0)
		update_active_chunks(initial_chunks)

func _process(_delta):
	# No need to reference the debug visualizer directly anymore
	pass

func addExplosionAt(pos: Vector2, radius: float) -> void:
	if renderer == null:
		return
	
	# Get affected chunks from the explosion
	var affected_chunks = get_chunks_in_radius(pos, radius)
	
	# Invalidate all chunks in the explosion radius
	for chunk_pos in affected_chunks:
		# Invalidate the chunk in the cache
		chunk_cache.invalidate_chunk(chunk_pos.x, chunk_pos.y)
		
		# Check if we need to reload this chunk (if it's in the active chunks)
		var chunk_key = "%d,%d" % [chunk_pos.x, chunk_pos.y]
		if active_chunks.has(chunk_key):
			# Reload the chunk since it's active and needs updating
			load_chunk(chunk_pos.x, chunk_pos.y)
	
	# Calculate visualization data for the explosion - always emit the signal
	# Calculate world coordinates of explosion (convert from pixels to tile positions)
	var explosion_center_tile_x = int(pos.x / cell_size)
	var explosion_center_tile_y = int(pos.y / cell_size)
	
	# Calculate tile radius (convert from pixels to tiles)
	var tile_radius = ceil(radius / cell_size)
	
	# Calculate affected area boundaries
	var x_from = explosion_center_tile_x - tile_radius
	var x_to = explosion_center_tile_x + tile_radius
	var y_from = explosion_center_tile_y - tile_radius
	var y_to = explosion_center_tile_y + tile_radius
	
	# Emit signal with explosion data
	var bounds_rect = Rect2(x_from, y_from, x_to - x_from, y_to - y_from)
	explosion_occurred.emit(pos, radius, bounds_rect)

func get_chunk_coordinates_at_world_position(world_pos: Vector2) -> Vector2:
	var tile_x = int(world_pos.x / cell_size)
	var tile_y = int(world_pos.y / cell_size)
	
	var chunk_x = floor(float(tile_x) / CHUNK_SIZE)
	var chunk_y = floor(float(tile_y) / CHUNK_SIZE)
	
	return Vector2(chunk_x, chunk_y)

func _find_renderer_node():
	renderer = null
	var renderer_count = 0
	
	for child in get_children():
		if child is MapRenderer:
			renderer_count += 1
			if renderer == null:
				renderer = child
	
	if renderer == null:
		push_error("MapGenerator requires a MapRenderer child node")
		printerr("MapGenerator requires a MapRenderer child node")
	
	if renderer_count > 1:
		push_warning("MapGenerator found multiple renderer nodes. Only the first one will be used.")

func _setup_default_noise_params():
	pass

func _input(event):
	if Engine.is_editor_hint():
		return
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		build(0, 16, 0, 16)

func _get_configuration_warnings():
	var warnings = []
	
	var has_renderer = false
	var renderer_count = 0
	
	for child in get_children():
		if child is MapRenderer:
			has_renderer = true
			renderer_count += 1
	
	if not has_renderer:
		warnings.append("MapGenerator requires a MapRenderer child node")
	
	if renderer_count > 1:
		warnings.append("MapGenerator has multiple renderer nodes. Only the first one will be used.")
	
	return warnings

func get_chunks_in_render_distance(center_x: int, center_y: int) -> Dictionary:
	var chunks_dict = {}
	
	# Calculate range
	var min_x = center_x - render_distance
	var max_x = center_x + render_distance
	var min_y = max(0, center_y - render_distance)  # Don't go above water
	var max_y = center_y + render_distance
	
	# Add all chunks in range to dictionary
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var key = "%d,%d" % [x, y]
			chunks_dict[key] = Vector2i(x, y)
	
	return chunks_dict
	
func update_active_chunks(new_chunks: Dictionary):
	# Track which chunks are newly loaded for debug visualization
	var newly_loaded_chunks = []
	
	# Load new chunks that aren't already active
	for key in new_chunks.keys():
		if not active_chunks.has(key):
			var chunk_pos = new_chunks[key]
			
			# Load this chunk
			load_chunk(chunk_pos.x, chunk_pos.y)
			
			# Track for debug visualization
			newly_loaded_chunks.append(chunk_pos)
			
			# Add to active chunks
			active_chunks[key] = chunk_pos
	
	# Unload chunks that are no longer needed
	var chunks_to_remove = []
	for key in active_chunks.keys():
		if not new_chunks.has(key):
			chunks_to_remove.append(key)
	
	for key in chunks_to_remove:
		active_chunks.erase(key)

func load_chunk(chunk_x: int, chunk_y: int):
	# Convert chunk coordinates to tile coordinates
	var x_from = chunk_x * CHUNK_SIZE
	var x_to = x_from + CHUNK_SIZE
	var y_from = chunk_y * CHUNK_SIZE
	var y_to = y_from + CHUNK_SIZE
	
	# Check if this chunk is already in the cache
	if chunk_cache.has_chunk(chunk_x, chunk_y):
		var cached_data = chunk_cache.get_chunk(chunk_x, chunk_y)
		
		# Apply cached data directly to renderer
		if renderer != null:
			renderer.apply_cached_chunk(cached_data, x_from, y_from)
			
		# Emit signal for debug visualization - always emit, let listeners decide what to do
		var bounds_rect = Rect2(x_from, y_from, CHUNK_SIZE, CHUNK_SIZE)
		chunk_loaded.emit(chunk_x, chunk_y, bounds_rect, true)  # true = from cache
	else:
		# Generate the chunk
		var chunk_data = generate_chunk_data(x_from, x_to, y_from, y_to)
		
		# Store in cache
		chunk_cache.store_chunk(chunk_x, chunk_y, chunk_data)
		
		# Apply data to renderer
		if renderer != null and chunk_data != null:
			renderer.apply_cached_chunk(chunk_data, x_from, y_from)
			
		# Emit signal for debug visualization - always emit, let listeners decide what to do
		var bounds_rect = Rect2(x_from, y_from, CHUNK_SIZE, CHUNK_SIZE)
		chunk_loaded.emit(chunk_x, chunk_y, bounds_rect, false)  # false = newly generated

func generate_chunk_data(x_from: int, x_to: int, y_from: int, y_to: int):
	if Engine.is_editor_hint() or renderer == null:
		return null
		
	# Create chunk data (this could be tile indices, or whatever data your renderer needs)
	var chunk_data = []
	
	# Generate tile data for each position in the chunk
	for y in range(y_from, y_to):
		var row = []
		for x in range(x_from, x_to):
			var square_value = marching_squares.get_square_value(x, y)
			row.append(square_value)
		chunk_data.append(row)
		
	return chunk_data

func build(x_from: int, x_to: int, y_from: int, y_to: int):
	if Engine.is_editor_hint() or renderer == null:
		return
		
	# Generate tile data for chunk
	var chunk_data = generate_chunk_data(x_from, x_to, y_from, y_to)
	
	# Apply to renderer
	if chunk_data != null:
		renderer.render_map(marching_squares, x_from, x_to, y_from, y_to)

func get_chunks_in_radius(pos: Vector2, radius: float) -> Array:
	var chunks = []
	var chunk_pos = get_chunk_coordinates_at_world_position(pos)
	var chunk_radius = ceil(radius / (cell_size * CHUNK_SIZE))
	
	for y in range(chunk_pos.y - chunk_radius, chunk_pos.y + chunk_radius + 1):
		for x in range(chunk_pos.x - chunk_radius, chunk_pos.x + chunk_radius + 1):
			chunks.append(Vector2i(x, y))
	
	return chunks

func _on_load_map_chunk_event(event: LoadMapChunkEvent):
	if event.map_layer != map_layer:
		return
	
	# Extract the center chunk coordinates (where the submarine is)
	var center_chunk_x = event.chunk_x
	var center_chunk_y = event.chunk_y
	
	# Only proceed if the submarine has moved to a new chunk
	if center_chunk_x == current_center_chunk_x and center_chunk_y == current_center_chunk_y:
		return
		
	# Update current center chunk
	current_center_chunk_x = center_chunk_x
	current_center_chunk_y = center_chunk_y
	
	# Update the player position in the cache for distance-based pruning
	chunk_cache.set_player_position(center_chunk_x, center_chunk_y)
	
	# Calculate which chunks should be active based on render distance
	var chunks_to_load = get_chunks_in_render_distance(center_chunk_x, center_chunk_y)
	
	# Determine which chunks to load and which to unload
	update_active_chunks(chunks_to_load)
