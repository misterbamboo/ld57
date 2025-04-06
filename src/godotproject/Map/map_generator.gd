@tool
class_name MapGenerator extends Node2D

# Map configuration
@export var width: int = 50
@export var cell_size: int = 50
@export var source_id: int = 0
@export var debug_show_mesh: bool = false

# Components
var noise_generator: NoiseGenerator
var marching_squares: MarchingSquaresGenerator

# Child node references
var renderers: Array[MapRenderer] = []
var tile_renderer: TileMapRenderer = null  
var polygon_renderer: PolygonRenderer = null

func _ready():
	if Engine.is_editor_hint():
		return
	
	EventBus.register(LoadMapPageEvent.event_name, _on_load_map_page_event)
	# Initialize noise components
	noise_generator = NoiseGenerator.new(5)
	_setup_default_noise_params()
	marching_squares = MarchingSquaresGenerator.new(noise_generator)
	
	# Find required child renderers
	_find_renderer_nodes()
	
	# Build initial map
	randomize()
	build(0, 20)

func _on_load_map_page_event(event: LoadMapPageEvent):
	print("_on_load_map_page_event %s %s" % [event.y_from, event.y_to])
	build(event.y_from, event.y_to)

func _find_renderer_nodes():
	renderers.clear()
	tile_renderer = null
	polygon_renderer = null
	
	# Find all renderer nodes
	for child in get_children():
		if child is MapRenderer:
			renderers.append(child)
			
			# Store specific renderer types for easy access
			if child is TileMapRenderer:
				tile_renderer = child
			elif child is PolygonRenderer:
				polygon_renderer = child
	
	# Display error if required nodes are missing
	if renderers.is_empty():
		push_error("MapGenerator requires at least one MapRenderer child node (TileMapRenderer or PolygonRenderer)!")
		printerr("MapGenerator requires at least one MapRenderer child node!")

func _setup_default_noise_params():
	# First layer
	noise_generator.set_noise_params(0, 1.00, 6.50, 21.0, 0.18, 7.40, 0.87, 0.58)
	# Second layer
	noise_generator.set_noise_params(1, 0.50, 37.5, 21.0, 0.11, 7.00, 0.65, 0.01)
	# Third layer
	noise_generator.set_noise_params(2, 1.00, 0.00, 0.00, 0.12, 0.00, 0.00, 0.00)
	# Fourth and fifth layers (unused by default)
	noise_generator.set_noise_params(3, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00)
	noise_generator.set_noise_params(4, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00)
	
func _input(event):
	if Engine.is_editor_hint():
		return
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		build(0, 20)
		
func build(from: int, to: int):
	if Engine.is_editor_hint() or renderers.is_empty():
		return
		
	from = clamp(from, 0, INF)
	
	# Generate map with each renderer
	for renderer in renderers:
		# Only show polygon renderer if debug is enabled
		if renderer is PolygonRenderer and not debug_show_mesh:
			continue
			
		renderer.render_map(marching_squares, from, to, width)

func _get_configuration_warnings():
	var warnings = []
	
	# Look for renderer child nodes
	var has_renderer = false
	
	for child in get_children():
		if child is MapRenderer:
			has_renderer = true
			break
	
	if not has_renderer:
		warnings.append("MapGenerator requires at least one MapRenderer child node (TileMapRenderer or PolygonRenderer)!")
	
	return warnings
