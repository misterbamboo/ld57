extends Node

@export var oreScene: PackedScene

var map_generator: MapGenerator
var cell_size: float
var chunk_size: float

# Node pooler instance
@onready var node_pooler = $NodePooler
var ore_renderer = null # Will be assigned OreMapRenderer instance

func _ready() -> void:
	# Find map generator in siblings
	if get_parent():
		for sibling in get_parent().get_children():
			if sibling is MapGenerator:
				map_generator = sibling
				cell_size = map_generator.cell_size
				chunk_size = map_generator.CHUNK_SIZE
				
				# Initialize the ore map renderer
				#ore_renderer = OreMapRenderer.new(map_generator, node_pooler, oreScene)
				add_child(ore_renderer)
				
				break
		
		if not map_generator:
			push_warning("OreGenerator couldn't find a MapGenerator sibling!")
	
func _refresh_initial_chunks():
	var chunks = map_generator.get_chunks_in_render_distance(0, 0)
	for key in chunks.keys():
		var pos = chunks[key]
		map_generator.load_chunk(pos.x, pos.y)
		
# This method is kept for backwards compatibility
func _on_chunk_loaded(_chunk_x, _chunk_y, _bounds_rect: Rect2, _from_cache):
	pass # Handled by OreMapRenderer now
			
# This method is kept for backwards compatibility if anything external calls it
func _getOre(x: int, y: int, color: Color) -> PoolableNode2D:
	if ore_renderer:
		return ore_renderer.spawn_ore(x, y, color)
	return null

# This method is kept for backwards compatibility if anything external calls it
func release_ores_in_region(_bounds_rect: Rect2) -> void:
	pass # Handled by OreMapRenderer now
