@tool
class_name MapGenerator extends Node2D

# Map configuration
@export var map_layer: int = 0
@export var width: int = 50
@export var cell_size: int = 50
@export var source_id: int = 0
@export var debug_show_chunk_seams: bool = false  # Toggle for showing chunk seam debug lines
@export var debug_show_updated_areas: bool = true  # Toggle for showing fading rectangles over updated areas

# Constants for chunk size
const CHUNK_SIZE := 16  # Each chunk is 16x16 tiles for all layer types

# Components
var noise_generator: NoiseGenerator
var marching_squares: MarchingSquaresGenerator

# Child node references
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
		# Random vibrant color with alpha
		self.color = Color(
			randf_range(0.5, 1.0),  # Red
			randf_range(0.5, 1.0),  # Green
			randf_range(0.5, 1.0),  # Blue
			0.6                     # Alpha
		)

# List of recently updated areas to visualize
var updated_areas: Array[UpdatedArea] = []

func _ready():
	randomize()
	if Engine.is_editor_hint():
		return
	ExplosionMap.on_explosion.connect(addExplosionAt)
	EventBus.register(LoadMapChunkEvent.event_name, _on_load_map_chunk_event)
	# Initialize noise components
	noise_generator = NoiseGenerator.new(5)
	_setup_default_noise_params()
	marching_squares = MarchingSquaresGenerator.new(noise_generator)
	
	# Find required renderer node
	_find_renderer_node()
	
	# Build initial map
	randomize()
	build(0, 16, 0, 16)

func _process(delta):
	if debug_show_chunk_seams:
		queue_redraw()  # Request redraw for debug lines
	
	if debug_show_updated_areas and updated_areas.size() > 0:
		var areas_to_remove = []
		
		# Update time left for each area
		for i in range(updated_areas.size()):
			updated_areas[i].time_left -= delta
			
			# Decrease alpha based on time left
			var alpha_multiplier = updated_areas[i].time_left / 1.5  # 1.5 seconds is the total duration
			updated_areas[i].color.a = 0.6 * alpha_multiplier
			
			# Mark for removal if faded out
			if updated_areas[i].time_left <= 0:
				areas_to_remove.append(i)
		
		# Remove faded out areas (in reverse order to avoid index issues)
		for i in range(areas_to_remove.size() - 1, -1, -1):
			updated_areas.remove_at(areas_to_remove[i])
		
		# Only redraw if there are still areas to show or we just removed some
		if updated_areas.size() > 0 or areas_to_remove.size() > 0:
			queue_redraw()

func _draw():
	if not debug_show_chunk_seams:
		return
		
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
	
	# Draw updated areas if enabled
	if debug_show_updated_areas:
		for area in updated_areas:
			# Convert tile coordinates to world coordinates
			var rect_pos = Vector2(area.x_from * cell_size, area.y_from * cell_size)
			var rect_size = Vector2((area.x_to - area.x_from) * cell_size, (area.y_to - area.y_from) * cell_size)
			
			# Draw the rectangle with the area's current color
			draw_rect(Rect2(rect_pos, rect_size), area.color, true)
			
			# Draw a border around the rectangle (slightly darker than the fill color)
			var border_color = area.color
			border_color.r *= 0.8
			border_color.g *= 0.8
			border_color.b *= 0.8
			border_color.a = min(1.0, area.color.a * 1.5)  # Make border more visible
			draw_rect(Rect2(rect_pos, rect_size), border_color, false, 2.0)

func addExplosionAt(pos: Vector2, radius: float) -> void:
	if renderer == null:
		return
		
	var x_from = int(pos.x - radius)
	var x_to = int(pos.x + radius + 1)
	var y_from = int(pos.y - radius)
	var y_to = int(pos.y + radius + 1)
	
	x_from = max(0, x_from)
	y_from = max(0, y_from)
	x_to = min(width, x_to)
	y_to = max(y_to, 0)
	
	if renderer != null:
		# Fix parameter order to match function signature
		renderer.render_map(marching_squares, x_from, x_to, y_from, y_to)

func _on_load_map_chunk_event(event: LoadMapChunkEvent):
	if event.map_layer != map_layer:
		return
	
	# Store the chunk position for debugging
	var chunk_x = event.chunk_x
	var chunk_y = event.chunk_y
	var event_map_layer = event.map_layer  # Renamed to avoid shadowing the class variable
	
	# Convert chunk coordinates to tile coordinates
	var x_from = chunk_x * CHUNK_SIZE
	var x_to = x_from + CHUNK_SIZE
	var y_from = chunk_y * CHUNK_SIZE
	var y_to = y_from + CHUNK_SIZE
	
	print("Map layer %d: Loading chunk at (%d,%d), tile range: (%d,%d) to (%d,%d)" % [event_map_layer, chunk_x, chunk_y, x_from, y_from, x_to, y_to])
	
	# Build the chunk using the existing build method
	build(x_from, x_to, y_from, y_to)
	
	# Add visual debug for the updated area if enabled
	if debug_show_updated_areas:
		add_updated_area_debug(x_from, x_to, y_from, y_to)

func add_updated_area_debug(area_x_from: int, area_x_to: int, area_y_from: int, area_y_to: int):
	# Create a new updated area and add it to the list
	# Using different parameter names to avoid shadowing warnings
	updated_areas.append(UpdatedArea.new(area_x_from, area_x_to, area_y_from, area_y_to, 1.5))  # Fade out over 1.5 seconds
	queue_redraw()  # Request a redraw to show the new area

func get_chunk_coordinates_at_world_position(world_pos: Vector2) -> Vector2:
	# Calculate chunk coordinates from world position
	var tile_x = int(world_pos.x / cell_size)
	var tile_y = int(world_pos.y / cell_size)
	
	# Convert tile coordinates to chunk coordinates
	var chunk_x = floor(float(tile_x) / CHUNK_SIZE)
	var chunk_y = floor(float(tile_y) / CHUNK_SIZE)
	
	return Vector2(chunk_x, chunk_y)

func _find_renderer_node():
	renderer = null
	
	var renderer_count = 0
	# Find the first renderer node
	for child in get_children():
		if child is MapRenderer:
			renderer_count += 1
			if renderer == null:  # Take the first one found
				renderer = child
	
	# Display error if required node is missing
	if renderer == null:
		push_error("MapGenerator requires a MapRenderer child node (TileMapRenderer or PolygonRenderer)!")
		printerr("MapGenerator requires a MapRenderer child node!")
	
	# Display warning if multiple renderers found
	if renderer_count > 1:
		push_warning("MapGenerator found multiple renderer nodes. Only the first one will be used.")
		printerr("MapGenerator found multiple renderer nodes. Only the first one will be used.")

func _setup_default_noise_params():
	# First layer
	var seed_1 = randf() * 100000 # save seed to have same result later
	noise_generator.set_noise_params(0, 1.00, 6.50, seed_1, 0.18, 7.40, 0.87, 0.58)
	# Second layer
	var seed_2 = randf() * 100000 # save seed to have same result later
	noise_generator.set_noise_params(1, 0.50, 37.5, seed_2, 0.11, 7.00, 0.65, 0.01)
	# Third layer
	var seed_3 = randf() * 100000 # save seed to have same result later
	noise_generator.set_noise_params(2, 1.00, 0.00, seed_3, 0.12, 0.00, 0.00, 0.00)
	# Fourth and fifth layers (unused by default)
	noise_generator.set_noise_params(3, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00)
	noise_generator.set_noise_params(4, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00)
	
func _input(event):
	if Engine.is_editor_hint():
		return
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		build(0, 16, 0, 16)
		
func build(x_from: int, x_to: int, y_from: int, y_to: int):
	if Engine.is_editor_hint() or renderer == null:
		return
	
	# Generate map with the renderer
	if renderer != null:
		renderer.render_map(marching_squares, x_from, x_to, y_from, y_to)

func _get_configuration_warnings():
	var warnings = []
	
	# Look for renderer child nodes
	var has_renderer = false
	var renderer_count = 0
	
	for child in get_children():
		if child is MapRenderer:
			has_renderer = true
			renderer_count += 1
	
	if not has_renderer:
		warnings.append("MapGenerator requires a MapRenderer child node (TileMapRenderer or PolygonRenderer)!")
	
	if renderer_count > 1:
		warnings.append("MapGenerator has multiple renderer nodes. Only the first one will be used.")
	
	return warnings

func _draw_chunk_seams(top_left: Vector2, bottom_right: Vector2, rows_in_chunk: float, cols_in_chunk: float, cell_size_px: float, color: Color):
	# Calculate chunk dimensions in world units (number of tiles × cell size)
	var chunk_height = rows_in_chunk * cell_size_px
	var chunk_width = cols_in_chunk * cell_size_px
	
	# Find chunk coordinates for corners of the view
	var top_left_chunk = get_chunk_coordinates_at_world_position(top_left)
	var bottom_right_chunk = get_chunk_coordinates_at_world_position(bottom_right)
	
	# Expand the range by 1 in each direction to ensure all visible chunks are shown
	var min_chunk_x = int(top_left_chunk.x) - 1
	var max_chunk_x = int(bottom_right_chunk.x) + 1
	var min_chunk_y = int(top_left_chunk.y) - 1
	var max_chunk_y = int(bottom_right_chunk.y) + 1
	
	# Convert chunk coordinates back to world coordinates for drawing
	for chunk_y in range(min_chunk_y, max_chunk_y + 1):
		var y_world = chunk_y * chunk_height
		# Draw horizontal grid line
		draw_line(Vector2(min_chunk_x * chunk_width - 1000, y_world), 
				  Vector2(max_chunk_x * chunk_width + 1000, y_world), 
				  color, 2.0)
	
	for chunk_x in range(min_chunk_x, max_chunk_x + 1):
		var x_world = chunk_x * chunk_width
		# Draw vertical grid line
		draw_line(Vector2(x_world, min_chunk_y * chunk_height - 1000),
				  Vector2(x_world, max_chunk_y * chunk_height + 1000),
				  color, 2.0)
	
	# Add chunk number labels at each chunk corner
	for chunk_y in range(min_chunk_y, max_chunk_y + 1):
		for chunk_x in range(min_chunk_x, max_chunk_x + 1):
			var x_world = chunk_x * chunk_width
			var y_world = chunk_y * chunk_height
			var label_position = Vector2(x_world + 5, y_world + 20)
			
			# Draw a background for the text to make it more visible
			var text = "Chunk: %d,%d" % [chunk_x, chunk_y]
			var font = ThemeDB.fallback_font
			var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			draw_rect(Rect2(label_position.x - 2, label_position.y - 14, text_size.x + 4, text_size.y + 4), Color(0, 0, 0, 0.5))
			
			# Draw the text
			draw_string(font, label_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.9))
