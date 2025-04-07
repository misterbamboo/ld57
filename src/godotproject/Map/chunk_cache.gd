class_name ChunkCache

# Configurable cache properties
var max_cached_chunks: int = 100  # Maximum number of chunks to keep in cache

# Cache storage
var _chunk_data: Dictionary = {}  # Stores actual chunk data
var _last_accessed: Dictionary = {}  # Stores when each chunk was last accessed
var _current_player_chunk: Vector2i = Vector2i(0, 0)

# Stats
var cache_hits: int = 0
var cache_misses: int = 0

func _init(max_cache_size: int = 100):
	max_cached_chunks = max_cache_size

# Check if a chunk exists in the cache
func has_chunk(chunk_x: int, chunk_y: int) -> bool:
	var key = _make_key(chunk_x, chunk_y)
	return _chunk_data.has(key)

# Get cached chunk data if it exists
func get_chunk(chunk_x: int, chunk_y: int):
	var key = _make_key(chunk_x, chunk_y)
	
	if _chunk_data.has(key):
		# Update last accessed time for this chunk
		_last_accessed[key] = Time.get_ticks_msec()
		cache_hits += 1
		return _chunk_data[key]
	
	cache_misses += 1
	return null

# Store chunk data in the cache
func store_chunk(chunk_x: int, chunk_y: int, chunk_data) -> void:
	var key = _make_key(chunk_x, chunk_y)
	
	# Store the chunk data
	_chunk_data[key] = chunk_data
	_last_accessed[key] = Time.get_ticks_msec()
	
	# Prune cache if needed
	if _chunk_data.size() > max_cached_chunks:
		_prune_cache()

# Set current player chunk for distance-based cleanup
func set_player_position(chunk_x: int, chunk_y: int) -> void:
	_current_player_chunk = Vector2i(chunk_x, chunk_y)

# Invalidate (remove) a chunk from the cache
func invalidate_chunk(chunk_x: int, chunk_y: int) -> void:
	var key = _make_key(chunk_x, chunk_y)
	if _chunk_data.has(key):
		_chunk_data.erase(key)
		_last_accessed.erase(key)

# Invalidate all chunks in a radius around a specified world position (for explosions)
func invalidate_chunks_in_radius(world_x: float, world_y: float, 
								 radius: float, chunk_size: int, cell_size: int) -> Array:
	# Calculate affected chunks
	var min_chunk_x = floor((world_x - radius) / (chunk_size * cell_size))
	var max_chunk_x = ceil((world_x + radius) / (chunk_size * cell_size))
	var min_chunk_y = floor((world_y - radius) / (chunk_size * cell_size))
	var max_chunk_y = ceil((world_y + radius) / (chunk_size * cell_size))
	
	# Track which chunks were invalidated for re-generation
	var invalidated_chunks: Array[Vector2i] = []
	
	# Invalidate all affected chunks
	for y in range(min_chunk_y, max_chunk_y + 1):
		for x in range(min_chunk_x, max_chunk_x + 1):
			invalidate_chunk(x, y)
			invalidated_chunks.append(Vector2i(x, y))
	
	return invalidated_chunks

# Clear entire cache
func clear_cache() -> void:
	_chunk_data.clear()
	_last_accessed.clear()
	cache_hits = 0
	cache_misses = 0

# Create a unique key for each chunk
func _make_key(chunk_x: int, chunk_y: int) -> String:
	return "%d,%d" % [chunk_x, chunk_y]

# Remove least valuable chunks to stay under max cache size
func _prune_cache() -> void:
	# We'll use two strategies combined:
	# 1. LRU (Least Recently Used)
	# 2. Distance from player
	
	# Create scoring for each chunk
	var scores: Dictionary = {}
	var current_time = Time.get_ticks_msec()
	
	for key in _chunk_data.keys():
		var parts = key.split(",")
		var x = int(parts[0])
		var y = int(parts[1])
		
		# Get time-based score (older = higher score to remove)
		var time_score = current_time - _last_accessed[key]
		
		# Get distance-based score
		var chunk_pos = Vector2i(x, y)
		var distance = chunk_pos.distance_to(_current_player_chunk)
		var distance_score = distance * 10000  # Weight distance heavily
		
		# Combined score
		scores[key] = time_score + distance_score
	
	# Sort keys by score (highest first)
	var keys = _chunk_data.keys()
	keys.sort_custom(func(a, b): return scores[a] > scores[b])
	
	# Remove highest scoring chunks until under limit
	var to_remove = _chunk_data.size() - max_cached_chunks
	for i in range(to_remove):
		if i < keys.size():
			_chunk_data.erase(keys[i])
			_last_accessed.erase(keys[i])

# Get cache statistics
func get_stats() -> Dictionary:
	return {
		"size": _chunk_data.size(),
		"max_size": max_cached_chunks,
		"hits": cache_hits,
		"misses": cache_misses,
		"hit_ratio": (float(cache_hits) / (cache_hits + cache_misses)) if (cache_hits + cache_misses) > 0 else 0.0
	}
