class_name SubmarineSprite extends Sprite2D

@export var flip_animation_time: float = 0.5
@export var max_tilt_angle: float = 15.0
@export var tilt_animation_time: float = 0.5
@export var propeller_min_speed: float = 1.0  # Minimum animation speed
@export var propeller_max_speed: float = 5  # Maximum animation speed
@export var propeller_accel_rate: float = 2.0  # How quickly the propeller speeds up
@export var propeller_decel_rate: float = 1.0  # How quickly the propeller slows down
@export var bubbles_min_emission: float = 5  # Minimum bubble emission rate
@export var bubbles_max_emission: float = 40  # Maximum bubble emission rate
@export var tiered_emitter_count: int = 5  # Number of tiered emitters

@onready var propeller: AnimatedSprite2D = $PropellerSprite

# Tiered particle emitters - set these up in the editor with increasing emission rates
# For example, BubbleTier1 might emit 5 particles, BubbleTier2 another 10, etc.
var bubble_emitters = []

var target_scale_x: float = 1.0
var target_rotation: float = 0.0
var current_propeller_speed: float = propeller_min_speed
var is_moving: bool = false
var last_active_tier: int = 0

func _ready():
	# Make sure propeller is playing on start
	if propeller:
		propeller.play()
		propeller.speed_scale = propeller_min_speed
	
	# Gather all the tiered emitters
	_initialize_tiered_emitters()

func _initialize_tiered_emitters():
	# Find all the tiered emitters that follow the naming convention
	for i in range(1, tiered_emitter_count + 1):
		var emitter_path = "BubbleTier" + str(i)
		if has_node(emitter_path):
			var emitter = get_node(emitter_path)
			bubble_emitters.append(emitter)
			
			# Start all emitters as inactive
			emitter.emitting = false

func _process(delta):
	_update_direction_from_input()
	_update_sprite_flip(delta)
	_update_sprite_tilt(delta)
	_update_propeller_speed(delta)
	
	# Update which emitters should be active
	_update_tiered_emitters()

func _update_direction_from_input():
	var up_strength = Input.get_action_strength("sub_up")
	var down_strength = Input.get_action_strength("sub_down")
	var right_strength = Input.get_action_strength("sub_right")
	var left_strength = Input.get_action_strength("sub_left")
	
	# Determine if submarine is moving based on any input
	is_moving = up_strength > 0 or down_strength > 0 or right_strength > 0 or left_strength > 0
	
	# Set horizontal direction
	if right_strength > 0:
		target_scale_x = 1.0
	elif left_strength > 0:
		target_scale_x = -1.0
	
	# Set vertical tilt based on input
	target_rotation = (down_strength - up_strength) * deg_to_rad(max_tilt_angle)
	
	# Correct tilt direction when facing left
	if target_scale_x < 0:
		target_rotation = -target_rotation

func _update_sprite_flip(delta: float) -> void:
	var lerp_weight = clamp(delta / flip_animation_time * 3.0, 0.0, 1.0)
	self.scale.x = lerp(self.scale.x, target_scale_x, lerp_weight)

func _update_sprite_tilt(delta: float) -> void:
	var lerp_weight = clamp(delta / tilt_animation_time * 3.0, 0.0, 1.0)
	self.rotation = lerp(rotation, target_rotation, lerp_weight)

func _update_propeller_speed(delta: float) -> void:
	if not propeller:
		return
		
	# Calculate target speed based on movement
	var target_speed = propeller_max_speed if is_moving else propeller_min_speed
	
	# Determine acceleration or deceleration rate
	var rate = propeller_accel_rate if is_moving else propeller_decel_rate
	
	# Smoothly adjust current speed
	current_propeller_speed = lerp(current_propeller_speed, target_speed, delta * rate)
	
	# Apply to propeller animation
	propeller.speed_scale = current_propeller_speed

func _update_tiered_emitters() -> void:
	if bubble_emitters.is_empty():
		return
	
	# Calculate which tiers should be active based on propeller speed
	# Normalize speed to 0.0-1.0 range
	var speed_range = propeller_max_speed - propeller_min_speed
	var speed_factor = (current_propeller_speed - propeller_min_speed) / speed_range
	speed_factor = clamp(speed_factor, 0.0, 1.0)
	
	# Calculate how many tiers should be active (0 to tiered_emitter_count)
	# We subtract 1 from the bubble_emitters.size() since the first one is always on
	var active_additional_tiers = 0
	if bubble_emitters.size() > 1:
		active_additional_tiers = int(round(speed_factor * (bubble_emitters.size() - 1)))
	
	# Total active tiers is the first one plus any additional ones
	var active_tier = 1 + active_additional_tiers
	
	# Only make changes if the active tier has changed
	if active_tier != last_active_tier:
		# Update which emitters are active
		for i in range(bubble_emitters.size()):
			if i == 0:
				# First tier is always on
				bubble_emitters[i].emitting = true
			else:
				# Other tiers depend on speed
				bubble_emitters[i].emitting = (i < active_tier)
		
		# Remember the current active tier
		last_active_tier = active_tier
