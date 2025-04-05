extends HBoxContainer

@export var bubble_graphics: Texture2D

const BUBBLE_COUNT = 10
const FLASH_INTERVAL = 0.1  # Time in seconds between flashes
const MIN_OPACITY = 0.2  # Minimum opacity during flash

var bubbles = []
var flashing_bubble_index = -1  # Index of the currently flashing bubble (last visible)
var flash_timer = 0.0
var flash_direction = -1  # -1 fading out, 1 fading in

func _ready() -> void:
	_initialize_bubbles()
	_update_display()
	set_process(true)

func _process(delta: float) -> void:
	_update_display()
	_handle_flashing_bubble(delta)

func _initialize_bubbles() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	
	for i in range(BUBBLE_COUNT):
		var bubble = TextureRect.new()
		bubble.texture = bubble_graphics
		bubble.expand = true
		bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(bubble)
		bubbles.append(bubble)

func _handle_flashing_bubble(delta: float) -> void:
	if flashing_bubble_index >= 0:
		flash_timer -= delta
		if flash_timer <= 0:
			flash_direction *= -1
			flash_timer = FLASH_INTERVAL
			
			_set_bubble_opacity(flashing_bubble_index, 
				MIN_OPACITY if flash_direction < 0 else 1.0)

func _update_display() -> void:
	var oxygen_percent = _get_oxygen_percentage()
	
	var visible_count = _calculate_visible_bubble_count(oxygen_percent)
	var should_flash = _should_bubble_flash(oxygen_percent)
	
	_update_bubble_visibility(visible_count)
	_update_flashing_bubble(should_flash, visible_count)

func _get_oxygen_percentage() -> float:
	return (Oxygen.get_quantity() / Oxygen.get_capacity()) * 100

func _calculate_visible_bubble_count(oxygen_percent: float) -> int:
	return ceil(oxygen_percent / 10.0)

func _should_bubble_flash(oxygen_percent: float) -> bool:
	# Flash in the x0 to x4 range (e.g., 80-84%), but never at 100% oxygen
	var remainder = fmod(oxygen_percent, 10.0)
	return remainder < 5.0 and remainder >= 0.0 and oxygen_percent > 0 and oxygen_percent < 100.0

func _update_bubble_visibility(visible_count: int) -> void:
	for i in range(BUBBLE_COUNT):
		if i == flashing_bubble_index:
			continue
			
		var opacity = 1.0 if i < visible_count else 0.0
		_set_bubble_opacity(i, opacity)

func _set_bubble_opacity(index: int, opacity: float) -> void:
	bubbles[index].modulate.a = opacity

func _update_flashing_bubble(should_flash: bool, visible_count: int) -> void:
	if should_flash and visible_count > 0:
		var new_flashing_index = visible_count - 1
		
		if new_flashing_index != flashing_bubble_index:
			_start_new_flashing_bubble(new_flashing_index)
	elif flashing_bubble_index != -1:
		flashing_bubble_index = -1

func _start_new_flashing_bubble(index: int) -> void:
	flashing_bubble_index = index
	flash_timer = FLASH_INTERVAL
	flash_direction = -1  
	
	_set_bubble_opacity(flashing_bubble_index, 1.0)
