class_name SubmarineMovement extends RigidBody2D

@export var move_speed: float = 200.0
@export var point_light: Light2D

func _physics_process(delta):
	_outside_water_force()
	if Game.instance.get_state() == Game.GameState.IN_ACTION or Game.instance.get_state() == Game.GameState.IN_SHOP:
		_move()

func _move():
	if global_position.y < 0:
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

func _outside_water_force():
	if global_position.y < 0:
		gravity_scale = 1
		linear_damp = 0.1 # less friction in air
	else:
		gravity_scale = 0
		linear_damp = 1 # more friction in water
		#var force := Vector2(0, +20)
		#apply_central_force(force)
