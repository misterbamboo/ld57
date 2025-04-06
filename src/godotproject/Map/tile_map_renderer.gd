@tool
class_name TileMapRenderer extends MapRenderer

@export var source_id: int = 0
@export var cell_size: int = 50

# Child node reference
var tile_map_layer: TileMapLayer = null

func _ready():
	if Engine.is_editor_hint():
		return
		
	_find_tile_map_layer()
	
func _find_tile_map_layer():
	for child in get_children():
		if child is TileMapLayer:
			tile_map_layer = child
			return
			
	if tile_map_layer == null:
		push_error("TileMapRenderer requires a TileMapLayer child node!")
		printerr("TileMapRenderer requires a TileMapLayer child node!")
            
func render_map(square_generator: MarchingSquaresGenerator, from_y: int, to_y: int, width: int):
	print("rendering tilemap from %s to %s" % [from_y, to_y])
	if Engine.is_editor_hint() or tile_map_layer == null:
		return
		
	clear_tiles(from_y, to_y, width)
	
	for x in range(width):
		for y in range(from_y, to_y):
			var square_type = square_generator.get_square_value(x, y)
			if square_type == 0:
				continue
				
			var tile_x = square_type % 8
			var tile_y = square_type / 8
			
			tile_map_layer.set_cell(
				Vector2i(x, y),
				source_id,
				Vector2i(tile_x, tile_y)
			)

func clear_tiles(from_y: int, to_y: int, width: int):
	if Engine.is_editor_hint() or tile_map_layer == null:
		return
		
	for x in range(width):
		for y in range(from_y, to_y):
			tile_map_layer.erase_cell(Vector2i(x, y))

func _get_configuration_warnings():
	var warnings = []
	
	# Check if we have a TileMapLayer child
	var has_tile_map = false
	
	for child in get_children():
		if child is TileMapLayer:
			has_tile_map = true
			break
	
	if not has_tile_map:
		warnings.append("TileMapRenderer requires a TileMapLayer child node!")
	
	return warnings
