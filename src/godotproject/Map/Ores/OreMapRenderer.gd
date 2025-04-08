extends Node2D
class_name OreMapRenderer

# Implements a renderer for ore objects that integrates with MapGenerator

# Reference to MapGenerator
var map_generator: MapGenerator

# Configuration for ore generation
var noise_generator: NoiseGenerator
var cell_size: float = 50
var chunk_size: int = 16

# The node pooler - will be found in the scene tree
@onready var node_pooler = $NodePooler

func _ready():
	# We can't initialize map generator stuff in _ready since we need map_generator
	pass

# Call this after setting map_generator
func initialize():
	if not map_generator:
		push_error("OreMapRenderer: No map generator reference set")
		return
		
	cell_size = map_generator.cell_size
	chunk_size = map_generator.CHUNK_SIZE
	noise_generator = map_generator.noise_generator
	
	# Automatically connect to MapGenerator signals
	map_generator.chunk_loaded.connect(_on_chunk_loaded)
	map_generator.chunk_unloaded.connect(_on_chunk_unloaded)
	
	# Handle any chunks that were already loaded
	var active_chunks = map_generator.active_chunks
	for key in active_chunks:
		var chunk_pos = active_chunks[key]
		# Calculate bounds exactly as MapGenerator does
		var x_from = chunk_pos.x * chunk_size
		var y_from = chunk_pos.y * chunk_size
		var bounds_rect = Rect2(x_from, y_from, chunk_size, chunk_size)
		render_ore_chunk(bounds_rect)

# Handles a chunk being loaded
func _on_chunk_loaded(_chunk_x, _chunk_y, bounds_rect: Rect2, _from_cache):
	render_ore_chunk(bounds_rect)

# Handles a chunk being unloaded
func _on_chunk_unloaded(_chunk_x, _chunk_y, bounds_rect: Rect2):
	unload_ore_chunk(bounds_rect)

# Renders ores in a specific chunk bounds
func render_ore_chunk(bounds_rect: Rect2):
	var x_from = bounds_rect.position.x
	var x_to = bounds_rect.end.x
	var y_from = bounds_rect.position.y
	var y_to = bounds_rect.end.y
	
	var ground = noise_generator.generator.getGroundColor()
	
	for x in range(x_from, x_to):
		for y in range(y_from, y_to):
			var value := noise_generator.get_noise_value_at(x, y)
			if value > 0:
				var color := noise_generator.get_noise_color_at(x, y)
				
				# Only spawn ore if it's not ground color and hasn't been collected
				if color != ground and not OreMap.hasBeenCollected(Vector2i(x, y)):
					spawn_ore(x, y, color)

# Unloads ores in a specific chunk bounds
func unload_ore_chunk(bounds_rect: Rect2):
	var active_instances = node_pooler._active_instances.duplicate()
	
	for ore in active_instances:
		if ore is PoolableNode2D:
			var ore_pos = Vector2i(ore.global_position.x / cell_size, ore.global_position.y / cell_size)
			if bounds_rect.has_point(Vector2(ore_pos.x, ore_pos.y)):
				ore.release()

# Spawns a single ore at the specified location
func spawn_ore(x: int, y: int, color: Color) -> PoolableNode2D:
	var ore = node_pooler.get_instance()
	
	if ore:
		ore.global_position = Vector2(x * cell_size, y * cell_size)
		ore.setColor(color)
	
	return ore
