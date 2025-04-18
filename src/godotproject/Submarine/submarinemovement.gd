class_name SubmarineMovement extends RigidBody2D

@export var move_speed: float = 200.0
func _get_move_speed() -> float:
	return move_speed + Submarine.instance.speed_capacity_upgrade

@export var point_light: Light2D

@export var out_of_water_buffer_zone := 20.0

var linear_velocity_last := Vector2.ZERO

func _physics_process(_delta):
	var surface = 0 if Water.instance == null else Water.instance.surface_variation(global_position.x)
	_outside_water_force(surface)
	_keep_on_surface_when_near(surface)
	
	var state = Game.GameState.IN_SHOP if Game.instance == null else Game.instance.get_state()
	if state == Game.GameState.IN_ACTION:
		_move(surface)

func _move(surface: float):
	if global_position.y < surface - out_of_water_buffer_zone:
		return

	var force := Vector2.ZERO
	
	# Handle vertical movement
	var up_strength = Input.get_action_strength("sub_up")
	var down_strength = Input.get_action_strength("sub_down")

	if up_strength > 0:
		force.y -= _get_move_speed()

	if down_strength > 0:
		force.y += _get_move_speed()
	
	# Handle horizontal movement
	var right_strength = Input.get_action_strength("sub_right")
	var left_strength = Input.get_action_strength("sub_left")
	
	if right_strength > 0:
		force.x += _get_move_speed()
	
	if left_strength > 0:
		force.x -= _get_move_speed()

	apply_central_force(force)
	# save last velocity for collision detection
	linear_velocity_last = linear_velocity

func _outside_water_force(surface: float):
	if global_position.y < surface - out_of_water_buffer_zone:
		gravity_scale = 0.5
		linear_damp = 0.1
	else:
		gravity_scale = 0
		linear_damp = 1
		
func _keep_on_surface_when_near(surface: float):
	if Input.is_action_pressed("sub_up") or Input.is_action_pressed("sub_down"):
		return

	if global_position.y > surface - out_of_water_buffer_zone and global_position.y < surface + out_of_water_buffer_zone:
		var variation = surface - global_position.y
		apply_central_force(Vector2(0, variation * 2))

# use velocity from last frame because the signal gets called 
# after the collision set our current velocity to zero
func _on_body_entered(_body: Node) -> void:
	if linear_velocity_last.length() >= 1:
		Life.hit(linear_velocity_last.length()/2)
