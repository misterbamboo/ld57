@tool
class_name MapGenerator extends Node2D

# Dependencies
const ChunkCacheScript = preload("res://Map/chunk_cache.gd")

# Configuration
@export var map_layer: int = 0
@export var width: int = 50
@export var cell_size: int = 50
@export var source_id: int = 0
@export var render_distance: int = 1  # Number of chunks to render around player (1 = 3x3 grid, 2 = 5x5, etc.)
@export var max_cached_chunks: int = 50  # Maximum number of chunks to keep in cache

# Debug visualization option
@export var debug_visualization: bool = true

# Chunk configuration
const CHUNK_SIZE := 16

# Tracking
var current_center_chunk_x: int = 0
var current_center_chunk_y: int = 0
var active_chunks: Dictionary = {}  # Track which chunks are currently loaded

# Chunk cache
var chunk_cache: ChunkCacheScript

# Core components
var noise_generator: NoiseGenerator
var marching_squares: MarchingSquaresGenerator
var renderer: MapRenderer = null

# Debug visualization for updated areas
class UpdatedArea:
	var x_from: int
	var x_to: int
	var y_from: int
	var y_to: int
	var time_left: float
	var color: Color
	
	func _init(area_x_from: int, area_x_to: int, area_y_from: int, area_y_to: int, duration: float):
		self.x_from = area_x_from
		self.x_to = area_x_to
		self.y_from = area_y_from
		self.y_to = area_y_to
		self.time_left = duration
		self.color = Color(
			randf_range(0.5, 1.0),
			randf_range(0.5, 1.0),
			randf_range(0.5, 1.0),
			0.6
		)

# Active debug visualizations
var updated_areas: Array[UpdatedArea] = []

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
	chunk_cache = null  # Clear any previous instance
	chunk_cache = ChunkCacheScript.new(max_cached_chunks)
	
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

func _process(delta):
	# Handle debug visualization updates
	update_debug_visualizations(delta)

func update_debug_visualizations(delta):
	if debug_visualization:
		queue_redraw()
	
	if debug_visualization and not updated_areas.is_empty():
		process_updated_areas(delta)

func process_updated_areas(delta):
	var areas_to_remove = []
	
	# Update time left for each area and adjust opacity
	for i in range(updated_areas.size()):
		updated_areas[i].time_left -= delta
		
		var alpha_multiplier = updated_areas[i].time_left / 1.5
		updated_areas[i].color.a = 0.6 * alpha_multiplier
		
		# Mark for removal if faded out
		if updated_areas[i].time_left <= 0:
			areas_to_remove.append(i)
	
	# Remove faded out areas (in reverse order to avoid index issues)
	for i in range(areas_to_remove.size() - 1, -1, -1):
		updated_areas.remove_at(areas_to_remove[i])
	
	# Redraw if there are any changes
	if not updated_areas.is_empty() or not areas_to_remove.is_empty():
		queue_redraw()

func _draw():
	if not debug_visualization:
		return
		
	# Draw debug visualizations if enabled
	draw_chunk_boundaries()
	draw_updated_areas()

func draw_chunk_boundaries():
	# Calculate view bounds based on viewport
	var viewport = get_viewport()
	var canvas_transform = get_canvas_transform()
	var view_size = viewport.get_visible_rect().size
	
	# Convert view extents to world space
	var top_left = -canvas_transform.origin / canvas_transform.get_scale()
	var bottom_right = top_left + view_size / canvas_transform.get_scale()
	
	# Choose color based on layer type
	var color = Color(1.0, 0.0, 0.0, 0.7)  # Red for level
	if map_layer == MapLayers.BACKGROUND:
		color = Color(0.0, 0.0, 1.0, 0.7)  # Blue for background
	
	# Draw chunk seams
	_draw_chunk_seams(top_left, bottom_right, CHUNK_SIZE, CHUNK_SIZE, cell_size, color)

func draw_updated_areas():
	for area in updated_areas:
		# Convert tile coordinates to world coordinates
		var rect_pos = Vector2(area.x_from * cell_size, area.y_from * cell_size)
		var rect_size = Vector2((area.x_to - area.x_from) * cell_size, (area.y_to - area.y_from) * cell_size)
		
		# Draw filled rectangle with current opacity
		draw_rect(Rect2(rect_pos, rect_size), area.color, true)
		
		# Draw border (slightly darker than the fill color)
		var border_color = area.color
		border_color.r *= 0.8
		border_color.g *= 0.8
		border_color.b *= 0.8
		border_color.a = min(1.0, area.color.a * 1.5)  # Make border more visible
		draw_rect(Rect2(rect_pos, rect_size), border_color, false, 2.0)

func add_updated_area_debug(area_x_from: int, area_x_to: int, area_y_from: int, area_y_to: int) -> UpdatedArea:
	var area = UpdatedArea.new(area_x_from, area_x_to, area_y_from, area_y_to, 1.5)
	area.color = Color(1, 0.5, 0, 0.2)  # Default color (orange)
	updated_areas.append(area)
	queue_redraw()
	return area

func addExplosionAt(pos: Vector2, radius: float) -> void:
	if renderer == null:
		return
		
	# Calculate boundaries for the affected area
	var x_from = int(pos.x - radius)
	var x_to = int(pos.x + radius + 1)
	var y_from = int(pos.y - radius)
	var y_to = int(pos.y + radius + 1)
	
	# Ensure coordinates are within valid range
	x_from = max(0, x_from)
	y_from = max(0, y_from)
	x_to = min(width, x_to)
	y_to = max(y_to, 0)
	
	# Regenerate the affected area
	renderer.render_map(marching_squares, x_from, x_to, y_from, y_to)

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
	# The API is now: set_player_position(chunk_x, chunk_y)
	chunk_cache.set_player_position(center_chunk_x, center_chunk_y)
	
	# Calculate which chunks should be active based on render distance
	var chunks_to_load = get_chunks_in_render_distance(center_chunk_x, center_chunk_y)
	
	# Determine which chunks to load and which to unload
	update_active_chunks(chunks_to_load)

# Load a single chunk at the given coordinates, using cache when available
func load_chunk(chunk_x: int, chunk_y: int):
	# Convert chunk coordinates to tile coordinates
	var x_from = chunk_x * CHUNK_SIZE
	var x_to = x_from + CHUNK_SIZE
	var y_from = chunk_y * CHUNK_SIZE
	var y_to = y_from + CHUNK_SIZE
	
	# Check if this chunk is already in the cache
	# The API is now: has_chunk(chunk_x, chunk_y)
	if chunk_cache.has_chunk(chunk_x, chunk_y):
		# The API is now: get_chunk(chunk_x, chunk_y)
		var cached_data = chunk_cache.get_chunk(chunk_x, chunk_y)
		
		# Apply cached data directly to renderer
		if renderer != null:
			renderer.apply_cached_chunk(cached_data, x_from, y_from)
			
		# Debug visualization can still be shown for cached chunks
		if debug_visualization:
			var area = add_updated_area_debug(x_from, x_to, y_from, y_to)
			area.color = Color(0, 1, 0, 0.2)  # Green tint to indicate cached chunk
	else:
		# Generate the chunk
		var chunk_data = generate_chunk_data(x_from, x_to, y_from, y_to)
		
		# Store in cache
		# The API is now: store_chunk(chunk_x, chunk_y, chunk_data)
		chunk_cache.store_chunk(chunk_x, chunk_y, chunk_data)
		
		# Apply data to renderer
		if renderer != null and chunk_data != null:
			renderer.apply_cached_chunk(chunk_data, x_from, y_from)
			
		# Debug visualization for newly generated chunks
		if debug_visualization:
			var area = add_updated_area_debug(x_from, x_to, y_from, y_to)
			area.color = Color(1, 0.5, 0, 0.2)  # Orange tint to indicate newly generated chunk

# Generate chunk data without rendering
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

# The build method now just applies already generated data to the renderer
func build(x_from: int, x_to: int, y_from: int, y_to: int):
	if Engine.is_editor_hint() or renderer == null:
		return
		
	# Generate tile data for chunk
	var chunk_data = generate_chunk_data(x_from, x_to, y_from, y_to)
	
	# Apply to renderer
	if chunk_data != null:
		renderer.render_map(marching_squares, x_from, x_to, y_from, y_to)

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

func _draw_chunk_seams(top_left: Vector2, bottom_right: Vector2, rows_in_chunk: float, cols_in_chunk: float, cell_size_px: float, color: Color):
	var chunk_height = rows_in_chunk * cell_size_px
	var chunk_width = cols_in_chunk * cell_size_px
	
	# Calculate visible chunk range
	var top_left_chunk = get_chunk_coordinates_at_world_position(top_left)
	var bottom_right_chunk = get_chunk_coordinates_at_world_position(bottom_right)
	
	# Expand range to ensure all visible chunks are shown
	var min_chunk_x = int(top_left_chunk.x) - 1
	var max_chunk_x = int(bottom_right_chunk.x) + 1
	var min_chunk_y = int(top_left_chunk.y) - 1
	var max_chunk_y = int(bottom_right_chunk.y) + 1
	
	# Draw horizontal grid lines
	for chunk_y in range(min_chunk_y, max_chunk_y + 1):
		var y_world = chunk_y * chunk_height
		draw_line(
			Vector2(min_chunk_x * chunk_width - 1000, y_world), 
			Vector2(max_chunk_x * chunk_width + 1000, y_world),
			color, 2.0
		)
	
	# Draw vertical grid lines
	for chunk_x in range(min_chunk_x, max_chunk_x + 1):
		var x_world = chunk_x * chunk_width
		draw_line(
			Vector2(x_world, min_chunk_y * chunk_height - 1000),
			Vector2(x_world, max_chunk_y * chunk_height + 1000),
			color, 2.0
		)
	
	# Draw chunk coordinate labels
	draw_chunk_labels(min_chunk_x, max_chunk_x, min_chunk_y, max_chunk_y, chunk_width, chunk_height)

func draw_chunk_labels(min_x: int, max_x: int, min_y: int, max_y: int, chunk_width: float, chunk_height: float):
	for chunk_y in range(min_y, max_y + 1):
		for chunk_x in range(min_x, max_x + 1):
			var x_world = chunk_x * chunk_width
			var y_world = chunk_y * chunk_height
			var label_position = Vector2(x_world + 5, y_world + 20)
			
			# Draw text background for better visibility
			var text = "Chunk: %d,%d" % [chunk_x, chunk_y]
			var font = ThemeDB.fallback_font
			var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			draw_rect(
				Rect2(label_position.x - 2, label_position.y - 14, text_size.x + 4, text_size.y + 4), 
				Color(0, 0, 0, 0.5)
			)
			
			# Draw the coordinate text
			draw_string(font, label_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.9))

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
		
	# Debug visualization of newly loaded chunks
	if debug_visualization and newly_loaded_chunks.size() > 0:
		for chunk_pos in newly_loaded_chunks:
			var x_from = chunk_pos.x * CHUNK_SIZE
			var x_to = x_from + CHUNK_SIZE
			var y_from = chunk_pos.y * CHUNK_SIZE
			var y_to = y_from + CHUNK_SIZE
			add_updated_area_debug(x_from, x_to, y_from, y_to)
