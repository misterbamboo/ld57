# Manages the camera following the submarine and handles map chunk loading
extends Node2D

# Import for explosion events
const ExplosionEvent = preload("res://GameEvents/explosion_event.gd")

# External references
## The node that the camera should follow (usually the submarine)
@export var target: Node2D
## How quickly the camera moves to follow the target (higher = faster)
@export var follow_speed: float = 10.0

# Chunk configuration
const CHUNK_SIZE := 16

# Tile size configuration 
## Size of a single terrain cell in pixels
@export var cell_size: int = 20
## Size of a background cell in pixels
@export var background_cell_size: int = 128

# Current chunk tracking
var current_x_chunk := 0
var current_y_chunk := 0
var current_background_x_chunk := 0
var current_background_y_chunk := 0


var shake_duration: float = 0.0
var shake_intensity: float = 0.0

# Screen shake configuration
@export_group("Screen Shake Configuration")
## Rate at which shake intensity diminishes (higher = faster fade)
@export var shake_decay: float = 5.0  # How quickly the shake effect diminishes
## Base frequency of the noise pattern (higher = more rapid oscillation)
@export var noise_frequency: float = 1.5
## Speed at which the noise position changes (higher = faster shake)
@export var noise_speed: float = 25.0
## Divisor for base intensity calculation (higher = subtler effect)
@export var intensity_divisor: float = 100.0
## Overall multiplier for shake intensity (higher = stronger shake)
@export var intensity_multiplier: float = 8.0
## Controls how long shakes last (higher = longer duration)
@export var duration_multiplier: float = 0.3
## How far away explosions can be felt (as a multiplier of radius)
@export var max_distance_multiplier: float = 5.0

var noise = FastNoiseLite.new()
var noise_pos: float = 0.0

func _ready() -> void:
	# Initialize the noise for screen shake
	noise.seed = randi()
	noise.frequency = noise_frequency
	
	# Find and connect to ExplosionMapHandler signal
	ExplosionMap.connect("on_explosion", _on_explosion)

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
	
	# Process screen shake if active
	process_screen_shake(delta)
	
	update_main_layer_chunks()
	update_background_layer_chunks()

# Handles the screen shake effect
func process_screen_shake(delta: float) -> void:
	if shake_duration > 0:
		# Update noise position - increase this value for faster shake frequency
		noise_pos += delta * noise_speed
		
		# Calculate shake offset using noise for a smoother effect
		var shake_offset = Vector2(
			noise.get_noise_2d(noise_pos, 0) * shake_intensity,
			noise.get_noise_2d(0, noise_pos) * shake_intensity
		)
		
		# Apply shake offset to the camera
		position += shake_offset
		
		# Reduce shake duration and intensity over time
		shake_duration -= delta
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		
		if shake_duration <= 0:
			# Ensure we reset completely when shake is done
			shake_duration = 0.0
			shake_intensity = 0.0

func update_main_layer_chunks():
	var submarine_position = target.position
	var chunk_coords = get_chunk_coordinates(submarine_position, cell_size)
	var x_chunk = int(chunk_coords.x)
	var y_chunk = max(0, int(chunk_coords.y))  
	
	if current_x_chunk != x_chunk or current_y_chunk != y_chunk:
		# Notify map generator of the submarine's current chunk
		load_chunk(x_chunk, y_chunk, MapLayers.LEVEL)
		
		current_x_chunk = x_chunk
		current_y_chunk = y_chunk

func update_background_layer_chunks():
	var submarine_position = target.position
	var chunk_coords = get_chunk_coordinates(submarine_position, background_cell_size)
	var x_chunk = int(chunk_coords.x)
	var y_chunk = max(0, int(chunk_coords.y))  
	
	if current_background_x_chunk != x_chunk or current_background_y_chunk != y_chunk:
		# Notify map generator of the submarine's current chunk
		load_chunk(x_chunk, y_chunk, MapLayers.BACKGROUND)
		
		current_background_x_chunk = x_chunk
		current_background_y_chunk = y_chunk

# Triggered when an explosion signal is received
func _on_explosion(indexPos: Vector2i, radiusIdx: float) -> void:
	# Convert index position and radius to world coordinates
	var explosion_ratio = 32.0  # This should match ExplosionMapHandler.pxToIndexRatio
	var world_pos = Vector2(indexPos) * explosion_ratio
	var world_radius = radiusIdx * explosion_ratio
	
	# Apply screen shake based on the explosion
	apply_screen_shake_from_explosion(world_pos, world_radius)

# Calculates and applies screen shake based on explosion parameters
func apply_screen_shake_from_explosion(explosion_pos: Vector2, explosion_radius: float) -> void:
	# Calculate distance from camera to explosion
	var distance_to_explosion = position.distance_to(explosion_pos)
	
	# Only shake if explosion is close enough
	var max_effect_distance = explosion_radius * max_distance_multiplier  # Maximum distance where shake is felt
	
	if distance_to_explosion <= max_effect_distance:
		# Calculate intensity based on distance (closer = stronger shake)
		var distance_factor = 1.0 - (distance_to_explosion / max_effect_distance)
		var base_intensity = explosion_radius / intensity_divisor  # Reduced from 50.0 to 100.0 for lower magnitude
		
		# Set shake parameters
		shake_duration = duration_multiplier * (explosion_radius / intensity_divisor + 1.0)  # Slightly shorter duration
		shake_intensity = base_intensity * distance_factor * intensity_multiplier  # Reduced from 15.0 to 8.0

# This function is now simplified - just notify the MapGenerator of the current center chunk
func load_chunk(chunk_x: int, chunk_y: int, map_layer: int):
	chunk_y = max(0, chunk_y)  
	EventBus.raise(LoadMapChunkEvent.new(map_layer, chunk_x, chunk_y))
