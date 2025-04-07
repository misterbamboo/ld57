@tool
class_name MapDebugVisualizer extends Node2D

# Configuration
@export var enabled: bool = true
@export var flash_duration: float = 1.5  # How long (in seconds) the color flash should appear
@export var cached_chunk_color: Color = Color(0, 1, 0, 0.2)  # Green tint for cached chunks
@export var new_chunk_color: Color = Color(1, 0.5, 0, 0.2)  # Orange tint for newly generated chunks
@export var explosion_color: Color = Color(1, 0, 0, 0.4)  # Red tint for explosions
@export var chunk_seam_color: Color = Color(1.0, 0.0, 0.0, 0.7)  # Red for level
@export var background_seam_color: Color = Color(0.0, 0.0, 1.0, 0.7)  # Blue for background

# References 
var cell_size: int = 50
var chunk_size: int = 16
var map_generator: MapGenerator = null

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
	# Find map generator in siblings
	if get_parent():
		for sibling in get_parent().get_children():
			if sibling is MapGenerator:
				map_generator = sibling
				cell_size = map_generator.cell_size
				chunk_size = map_generator.CHUNK_SIZE
				
				# Connect to map generator signals
				map_generator.chunk_loaded.connect(_on_chunk_loaded)
				map_generator.explosion_occurred.connect(_on_explosion_occurred)
				break
		
		if not map_generator:
			push_warning("MapDebugVisualizer couldn't find a MapGenerator sibling!")

# Signal handlers
func _on_chunk_loaded(_chunk_x, _chunk_y, bounds_rect, from_cache):
	if not enabled:
		return
		
	# Create updated area visualization
	var x_from = bounds_rect.position.x
	var y_from = bounds_rect.position.y
	var x_to = x_from + bounds_rect.size.x
	var y_to = y_from + bounds_rect.size.y
	
	add_updated_area(x_from, x_to, y_from, y_to, from_cache)

func _on_explosion_occurred(_center_position, _radius, bounds_rect):
	if not enabled:
		return
		
	# Visualize explosion area
	var x_from = bounds_rect.position.x
	var y_from = bounds_rect.position.y
	var x_to = x_from + bounds_rect.size.x
	var y_to = y_from + bounds_rect.size.y
	
	# Use a special color for explosions
	var area = add_updated_area(x_from, x_to, y_from, y_to, false)
	area.color = explosion_color  # Red tint for explosions

func _process(delta):
	if enabled and not updated_areas.is_empty():
		process_updated_areas(delta)

func process_updated_areas(delta):
	var areas_to_remove = []
	
	# Update time left for each area and adjust opacity
	for i in range(updated_areas.size()):
		updated_areas[i].time_left -= delta
		
		var alpha_multiplier = updated_areas[i].time_left / flash_duration
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
	if not enabled or not map_generator:
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
	var color = chunk_seam_color
	if map_generator.map_layer == MapLayers.BACKGROUND:
		color = background_seam_color
	
	# Draw chunk seams
	_draw_chunk_seams(top_left, bottom_right, chunk_size, chunk_size, cell_size, color)

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

func add_updated_area(area_x_from: int, area_x_to: int, area_y_from: int, area_y_to: int, is_cached_chunk: bool = false) -> UpdatedArea:
	var area = UpdatedArea.new(area_x_from, area_x_to, area_y_from, area_y_to, flash_duration)
	
	# Set color based on whether this is a cached chunk or a newly generated one
	if is_cached_chunk:
		area.color = cached_chunk_color
	else:
		area.color = new_chunk_color
		
	updated_areas.append(area)
	queue_redraw()
	return area

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

func get_chunk_coordinates_at_world_position(world_pos: Vector2) -> Vector2:
	var tile_x = int(world_pos.x / cell_size)
	var tile_y = int(world_pos.y / cell_size)
	var chunk_x = floor(float(tile_x) / chunk_size)
	var chunk_y = floor(float(tile_y) / chunk_size)
	return Vector2(chunk_x, chunk_y)
