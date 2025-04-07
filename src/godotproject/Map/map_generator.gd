@tool
class_name MapGenerator extends Node2D

# Map configuration
@export var map_layer: int = 0
@export var width: int = 50
@export var cell_size: int = 50
@export var source_id: int = 0
@export var debug_show_page_seams: bool = false  # Toggle for showing page seam debug lines

# Constants for page calculations
const ROWS_PER_PAGE := 20.0  # Level uses 20 rows per page
const BACKGROUND_ROWS_PER_PAGE := 10.0  # Background uses 10 rows per page

# Components
var noise_generator: NoiseGenerator
var marching_squares: MarchingSquaresGenerator

# Child node references
var renderer: MapRenderer = null

func _ready():
	randomize()
	if Engine.is_editor_hint():
		return
	ExplosionMap.on_explosion.connect(addExplosionAt)
	EventBus.register(LoadMapPageEvent.event_name, _on_load_map_page_event)
	# Initialize noise components
	noise_generator = NoiseGenerator.new(5)
	_setup_default_noise_params()
	marching_squares = MarchingSquaresGenerator.new(noise_generator)
	
	# Find required renderer node
	_find_renderer_node()
	
	# Build initial map
	randomize()
	build(0, 20)

func _process(_delta):
	if debug_show_page_seams:
		queue_redraw()  # Request redraw for debug lines

func _draw():
	if not debug_show_page_seams:
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
	
	# Get appropriate rows per page based on layer type
	var rows_in_page = ROWS_PER_PAGE
	if map_layer == MapLayers.BACKGROUND:
		rows_in_page = BACKGROUND_ROWS_PER_PAGE
	
	# Draw page seams
	_draw_page_seams(top_left, bottom_right, rows_in_page, cell_size, color)

func _draw_page_seams(top_left: Vector2, bottom_right: Vector2, rows_in_page: float, cell_size_px: float, color: Color):
	# Calculate page height in world units
	var page_height = rows_in_page * cell_size_px
	
	# Find start and end Y positions based on view
	var start_y = floor(top_left.y / page_height) * page_height
	var end_y = ceil(bottom_right.y / page_height) * page_height
	
	# Draw horizontal lines at each page boundary
	for y in range(start_y, end_y + page_height, page_height):
		# Draw line across visible width
		draw_line(Vector2(top_left.x, y), Vector2(bottom_right.x, y), color, 2.0)
		
		# Add page number label
		var page_number = int(y / page_height)
		var label_position = Vector2(top_left.x + 10, y - 5)
		draw_string(ThemeDB.fallback_font, label_position, "Page: %d" % page_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

func addExplosionAt(pos: Vector2, radius: float) -> void:
	if renderer == null:
		return
		
	var from = pos.y - radius
	var to = pos.y + radius + 1
	renderer.render_map(marching_squares, from, to, width)

func _on_load_map_page_event(event: LoadMapPageEvent):
	if event.map_layer != map_layer: return
	print("_on_load_map_page_event %s %s" % [event.y_from, event.y_to])
	build(event.y_from, event.y_to)

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
		build(0, 20)
		
func build(from: int, to: int):
	if Engine.is_editor_hint() or renderer == null:
		return
		
	from = clamp(from, 0, INF)
	
	# Generate map with the renderer
	renderer.render_map(marching_squares, from, to, width)

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
