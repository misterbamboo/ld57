extends Node

@export var oreScene: PackedScene

var map_generator: MapGenerator
var cell_size: float
var chunk_size: float

# Node pooler instance
@onready var node_pooler = $NodePooler

func _ready() -> void:
	# Find map generator in siblings
	if get_parent():
		for sibling in get_parent().get_children():
			if sibling is MapGenerator:
				map_generator = sibling
				cell_size = map_generator.cell_size
				chunk_size = map_generator.CHUNK_SIZE
				
				# Connect to map generator signals
				map_generator.chunk_loaded.connect(_on_chunk_loaded)
				_refresh_initial_chunks()
				
				break
		
		if not map_generator:
			push_warning("MapDebugVisualizer couldn't find a MapGenerator sibling!")
	
func _refresh_initial_chunks():
	var chunks = map_generator.get_chunks_in_render_distance(0, 0)
	for key in chunks.keys():
		var pos = chunks[key]
		map_generator.load_chunk(pos.x, pos.y)
			
func _on_chunk_loaded(_chunk_x, _chunk_y, bounds_rect: Rect2, _from_cache):
	var noise_generator := map_generator.noise_generator
	
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
				if color != ground or OreMap.hasMoved(Vector2i(x, y)):
					var ore := _getOre(x, y, color)

func _on_chunk_unloaded(_chunk_x, _chunk_y, bounds_rect: Rect2):
	# Release ore instances in this chunk
	release_ores_in_region(bounds_rect)
			
func _getOre(x: int, y: int, color: Color) -> PoolableOre:
	var ore = node_pooler.get_instance()
	
	if ore:
		ore.global_position = Vector2(x * cell_size, y * cell_size)
		ore.setColor(color)
	
	return ore

# This method should be called when a chunk is unloaded to release ore instances
func release_ores_in_region(bounds_rect: Rect2) -> void:
	# Loop through active instances and release those in the bounds region
	var active_instances = node_pooler._active_instances.duplicate()
	
	for ore in active_instances:
		if ore is Ore:
			var ore_pos = ore.global_position / cell_size
			if bounds_rect.has_point(Vector2(ore_pos.x, ore_pos.y)):
				node_pooler.release_instance(ore)
