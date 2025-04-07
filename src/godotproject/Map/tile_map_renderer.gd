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
			
# Implementation of parent class abstract method for 2D map rendering
func render_map(square_generator: MarchingSquaresGenerator, x_from: int, x_to: int, y_from: int, y_to: int):
	if Engine.is_editor_hint() or tile_map_layer == null:
		return
		
	clear_tiles(x_from, x_to, y_from, y_to)
	
	# Loop through every tile
	for x in range(x_from, x_to):
		for y in range(y_from, y_to):
			var square_type = square_generator.get_square_value(x, y)
			if square_type == 0:
				continue
				
			var tile_x = square_type % 8
			# Using floored division to avoid decimal truncation warning
			var tile_y = square_type / 8
			
			# Set the cell with correct parameter order for Godot TileMap
			tile_map_layer.set_cell(
				Vector2i(x, y), # Cell coordinates
				source_id,      # Atlas source ID
				Vector2i(tile_x, tile_y)  # Atlas coordinates
			)

func clear_tiles(x_from: int, x_to: int, y_from: int, y_to: int):
	if Engine.is_editor_hint() or tile_map_layer == null:
		return
		
	for x in range(x_from, x_to):
		for y in range(y_from, y_to):
			# Corrected method call for erase_cell
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
