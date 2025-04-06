class_name SubmarineSprite extends Sprite2D

@export var flip_animation_time: float = 0.5
@export var max_tilt_angle: float = 15.0
@export var tilt_animation_time: float = 0.5

var target_scale_x: float = 1.0
var target_rotation: float = 0.0

func _process(delta):
	_update_direction_from_input()
	_update_sprite_flip(delta)
	_update_sprite_tilt(delta)

func _update_direction_from_input():
	var up_strength = Input.get_action_strength("sub_up")
	var down_strength = Input.get_action_strength("sub_down")
	var right_strength = Input.get_action_strength("sub_right")
	var left_strength = Input.get_action_strength("sub_left")
	
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
