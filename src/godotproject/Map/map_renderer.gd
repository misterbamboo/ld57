class_name MapRenderer extends Node2D

# Function signature for 2D map generation
func render_map(_square_generator: MarchingSquaresGenerator, _x_from: int, _x_to: int, _y_from: int, _y_to: int):
	pass # Abstract method

# Function to apply pre-cached chunk data
func apply_cached_chunk(_chunk_data, _x_from: int, _y_from: int):
	pass # Abstract method - to be implemented by subclasses
