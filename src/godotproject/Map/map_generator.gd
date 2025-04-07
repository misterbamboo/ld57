@tool
class_name MapGenerator extends Node2D

# Configuration
@export var map_layer: int = 0
@export var width: int = 50
@export var cell_size: int = 50
@export var source_id: int = 0
@export var render_distance: int = 1  # Number of chunks to render around player (1 = 3x3 grid, 2 = 5x5, etc.)

# Debug visualization option
@export var debug_visualization: bool = true

# Chunk configuration
const CHUNK_SIZE := 16

# Tracking
var current_center_chunk_x: int = 0
var current_center_chunk_y: int = 0
var active_chunks: Dictionary = {}  # Track which chunks are currently loaded

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
	randomize()
	if Engine.is_editor_hint():
		return
		
	initialize_components()
	connect_signals()
	build_initial_map()

func initialize_components():
	# Initialize noise generation system
	noise_generator = NoiseGenerator.new(5)
	_setup_default_noise_params()
	marching_squares = MarchingSquaresGenerator.new(noise_generator)
	
	# Find the required renderer node
	_find_renderer_node()

func connect_signals():
	ExplosionMap.on_explosion.connect(addExplosionAt)
	EventBus.register(LoadMapChunkEvent.event_name, _on_load_map_chunk_event)

func build_initial_map():
	build(0, 16, 0, 16)

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

func add_updated_area_debug(area_x_from: int, area_x_to: int, area_y_from: int, area_y_to: int):
	updated_areas.append(UpdatedArea.new(area_x_from, area_x_to, area_y_from, area_y_to, 1.5))
	queue_redraw()

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
	
	# Calculate which chunks should be active based on render distance
	var chunks_to_load = get_chunks_in_render_distance(center_chunk_x, center_chunk_y)
	
	# Determine which chunks to load and which to unload
	update_active_chunks(chunks_to_load)
	
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
			
func load_chunk(chunk_x: int, chunk_y: int):
	# Convert chunk coordinates to tile coordinates
	var x_from = chunk_x * CHUNK_SIZE
	var x_to = x_from + CHUNK_SIZE
	var y_from = chunk_y * CHUNK_SIZE
	var y_to = y_from + CHUNK_SIZE
	
	# Generate the chunk
	build(x_from, x_to, y_from, y_to)

func build(x_from: int, x_to: int, y_from: int, y_to: int):
	if Engine.is_editor_hint() or renderer == null:
		return
	
	# Generate map with the renderer
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
	# First layer - main terrain structure
	var seed_1 = randf() * 100000
	noise_generator.set_noise_params(0, 1.00, 6.50, seed_1, 0.18, 7.40, 0.87, 0.58)
	
	# Second layer - detail and variation
	var seed_2 = randf() * 100000
	noise_generator.set_noise_params(1, 0.50, 37.5, seed_2, 0.11, 7.00, 0.65, 0.01)
	
	# Third layer - subtle noise
	var seed_3 = randf() * 100000
	noise_generator.set_noise_params(2, 1.00, 0.00, seed_3, 0.12, 0.00, 0.00, 0.00)
	
	# Fourth and fifth layers (unused by default)
	noise_generator.set_noise_params(3, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00)
	noise_generator.set_noise_params(4, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00)

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
