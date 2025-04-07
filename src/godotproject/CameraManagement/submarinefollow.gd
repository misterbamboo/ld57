# Manages the camera following the submarine and handles map chunk loading
extends Node2D

# External references
@export var target: Node2D
@export var follow_speed: float = 10.0

# Chunk configuration
const CHUNK_SIZE := 16

# Tile size configuration 
@export var cell_size: int = 20
@export var background_cell_size: int = 128

# Current chunk tracking
var current_x_chunk := 0
var current_y_chunk := 0
var current_background_x_chunk := 0
var current_background_y_chunk := 0

func get_chunk_coordinates(world_pos: Vector2, cell_size_value: int) -> Vector2:
	var tile_x = int(world_pos.x / cell_size_value)
	var tile_y = int(world_pos.y / cell_size_value)
	var chunk_x = floor(float(tile_x) / CHUNK_SIZE)
	var chunk_y = floor(float(tile_y) / CHUNK_SIZE)
	return Vector2(chunk_x, chunk_y)

func _process(delta: float) -> void:
	if target != null:
		var target_position = target.position
		position = position.lerp(target_position, follow_speed * delta)
	update_main_layer_chunks()
	update_background_layer_chunks()

func update_main_layer_chunks():
	var submarine_position = target.position
	var chunk_coords = get_chunk_coordinates(submarine_position, cell_size)
	var x_chunk = int(chunk_coords.x)
	var y_chunk = max(0, int(chunk_coords.y))  
	
	if current_x_chunk != x_chunk or current_y_chunk != y_chunk:
		var chunks_to_load = calculate_chunks_to_load(x_chunk, y_chunk)
		for coord in chunks_to_load:
			load_chunk(coord.x, coord.y, MapLayers.LEVEL)
		
		current_x_chunk = x_chunk
		current_y_chunk = y_chunk

func update_background_layer_chunks():
	var submarine_position = target.position
	var chunk_coords = get_chunk_coordinates(submarine_position, background_cell_size)
	var x_chunk = int(chunk_coords.x)
	var y_chunk = max(0, int(chunk_coords.y))  
	
	if current_background_x_chunk != x_chunk or current_background_y_chunk != y_chunk:
		var chunks_to_load = calculate_chunks_to_load(x_chunk, y_chunk)
		for coord in chunks_to_load:
			load_chunk(coord.x, coord.y, MapLayers.BACKGROUND)
		
		current_background_x_chunk = x_chunk
		current_background_y_chunk = y_chunk

func calculate_chunks_to_load(center_x: int, center_y: int) -> Array[Vector2i]:
	var chunks_to_load: Array[Vector2i] = []
	var x_min = center_x - 1
	var x_max = center_x + 1
	var y_min = max(0, center_y - 1)  
	var y_max = center_y + 1
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			chunks_to_load.append(Vector2i(x, y))
	return chunks_to_load

func load_chunk(chunk_x: int, chunk_y: int, map_layer: int):
	chunk_y = max(0, chunk_y)  
	EventBus.raise(LoadMapChunkEvent.new(map_layer, chunk_x, chunk_y))
