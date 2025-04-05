extends Node
@onready var icon: TextureRect = $TextureRect

@export var healthy_color: Color
@export var mid_color: Color
@export var damaged_color: Color

const FLASH_INTERVAL = 0.2  # Time in seconds between flashes
const MIN_OPACITY = 0.4  # Minimum opacity during flash
const CRITICAL_HEALTH = 15.0  # Health percentage below which icon will flash

var flash_timer = 0.0
var flash_direction = -1  # -1 fading out, 1 fading in
var is_critical = false

func _ready() -> void:
	_update_display()

func _process(delta: float) -> void:
	_update_display()
	_handle_flashing(delta)

func _handle_flashing(delta: float) -> void:
	if is_critical:
		flash_timer -= delta
		if flash_timer <= 0:
			flash_direction *= -1
			flash_timer = FLASH_INTERVAL
			
			_set_icon_opacity(MIN_OPACITY if flash_direction < 0 else 1.0)

func _update_display() -> void:
	var life_percent = _get_life_percentage()
	_update_critical_state(life_percent)
	_update_icon_color(life_percent)

func _get_life_percentage() -> float:
	return (Life.get_quantity() / Life.get_capacity()) * 100

func _update_critical_state(life_percent: float) -> void:
	var was_critical = is_critical
	is_critical = life_percent < CRITICAL_HEALTH
	
	if is_critical and !was_critical:
		_initialize_flashing()
	elif !is_critical:
		_reset_icon_opacity()

func _initialize_flashing() -> void:
	flash_timer = FLASH_INTERVAL
	flash_direction = -1

func _reset_icon_opacity() -> void:
	icon.modulate.a = 1.0

func _set_icon_opacity(opacity: float) -> void:
	icon.modulate.a = opacity

func _update_icon_color(life_percent: float) -> void:
	var color = _calculate_color_for_health(life_percent)
	
	# Apply color while preserving opacity if flashing
	var current_opacity = icon.modulate.a
	icon.modulate = color
	
	if is_critical:
		icon.modulate.a = current_opacity

func _calculate_color_for_health(life_percent: float) -> Color:
	if life_percent > 66:
		# Transition from healthy to mid color (100%-66%)
		var t = (life_percent - 66) / 34
		return mid_color.lerp(healthy_color, t)
	else:
		# Transition from damaged to mid color (0%-66%)
		var t = life_percent / 66
		return damaged_color.lerp(mid_color, t)
