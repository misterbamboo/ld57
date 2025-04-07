class_name LoadMapChunkEvent extends GameEvent

static var event_name := "LoadMapChunkEvent"

var map_layer: int
var chunk_x: int
var chunk_y: int

# We use a simplified approach - just the chunk coordinates
func _init(p_map_layer: int, p_chunk_x: int, p_chunk_y: int):
	self.chunk_x = p_chunk_x
	self.chunk_y = p_chunk_y
	self.map_layer = p_map_layer

func get_name() -> String:
	return event_name
