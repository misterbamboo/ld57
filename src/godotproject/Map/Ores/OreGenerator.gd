extends Node

@export var oreScene: PackedScene

var map_generator: MapGenerator
var cell_size: float
var chunk_size: float

var poolNextIndex := 0
var orePool: Array[Ore] = []

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
				createPoolOf(200)
				_refresh_initial_chunks()
				
				break
		
		if not map_generator:
			push_warning("MapDebugVisualizer couldn't find a MapGenerator sibling!")
	
func _refresh_initial_chunks():
	var chunks = map_generator.get_chunks_in_render_distance(0, 0)
	for key in chunks.keys():
		var pos = chunks[key]
		map_generator.load_chunk(pos.x, pos.y)
	
func createPoolOf(instanceCount: int):
	for i in range(0, instanceCount):
		var instance = oreScene.instantiate()
		add_child(instance)
		orePool.append(instance)
			
func _on_chunk_loaded(chunk_x, chunk_y, bounds_rect: Rect2, from_cache):
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
			
func _getOre(x: int, y: int, color: Color) -> Ore:
	if poolNextIndex >= orePool.size():
		createPoolOf(10)
	
	var ore := orePool[poolNextIndex]
	ore.global_position = Vector2(x * cell_size, y * cell_size)
	ore.setColor(color)
	poolNextIndex += 1
	return ore
