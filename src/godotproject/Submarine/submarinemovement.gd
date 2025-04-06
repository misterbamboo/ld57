class_name SubmarineMovement extends RigidBody2D

@export var move_speed: float = 200.0
@export var point_light: Light2D

@export var out_of_water_buffer_zone := 20.0

func _physics_process(delta):
	var surface = Water.instance.surface_variation(global_position.x)
	_outside_water_force(surface)
	_keep_on_surface_when_near(surface)
	if Game.instance.get_state() == Game.GameState.IN_ACTION:
		_move(surface)

func _move(surface: float):
	if global_position.y < surface - out_of_water_buffer_zone:
		return

	var force := Vector2.ZERO

	if Input.get_action_strength("sub_up") > 0:
		force.y -= move_speed

	if Input.get_action_strength("sub_down") > 0:
		force.y += move_speed

	if Input.get_action_strength("sub_right") > 0:
		force.x += move_speed

	if Input.get_action_strength("sub_left") > 0:
		force.x -= move_speed

	apply_central_force(force)
	_update_speed()

func _update_speed():
	if Submarine.instance.speed_upgrade_bought:
		move_speed += 2
		Submarine.instance.speed_upgrade_bought = false

func _outside_water_force(surface: float):
	if global_position.y < surface - out_of_water_buffer_zone:
		gravity_scale = 0.5
		linear_damp = 0.1 # less friction in air
	else:
		gravity_scale = 0
		linear_damp = 1 # more friction in water
		
func _keep_on_surface_when_near(surface: float):
	# if user doesn't press any key ans is near the surface, apply a force to keep it on the surface so it follows the water
	# like if a magnet lerp to the surface

	if(Input.is_action_pressed("sub_up") or Input.is_action_pressed("sub_down")):
		return

	if global_position.y > surface - out_of_water_buffer_zone and global_position.y < surface + out_of_water_buffer_zone:
		var variation = surface - global_position.y
		var force = Vector2(0, variation * 2)
		apply_central_force(force)
