class_name Grapple extends Node2D

#@export var grapple_sound: Node # Assuming you have a GrappleSound node in Godot
@onready var hook: Hook = $GrappleHook
@onready var grappling_rope: GrapplingRope = $GrappleRope

var pull_speed = 5.0
var is_pulling = false
var object_to_pull = null

var grapple_point = Vector2.ZERO
var grappling_distance = Vector2.ZERO

var _attachedOres: Array[PoolableOre] = []

func _ready():
	reset_grappling_requirement()
	hook.onOreAttached.connect(_on_ore_attached)

func _on_ore_attached(ore: PoolableOre):
	_attachedOres.append(ore)
	
	# Check if we've reached capacity and set the flag
	if _attachedOres.size() >= Submarine.instance.hook_capacity_upgrade:
		hook.set_capacity_reached(true)
	
	check_auto_reel()

func get_hook_distance() -> float:
	return Submarine.instance.hook_length_upgrade

func _process(delta):
	handle_grapple()

func handle_grapple():
	if is_clicking() and not is_pulling:
		set_grappling_requirement()
		start_hooking()
	elif release_click():
		start_pulling()
	
	if is_pulling:
		move_toward_submarine()
		
		if have_reach_submarine():
			# Only collect ores here, and then reset
			getOreToInventory()
			reset_grappling_requirement()
	
	move_hook_tip_of_rope()

func start_pulling():
	is_pulling = true

func is_clicking():
	return Input.is_action_just_pressed("fire_hook") and Game.instance.state == Game.instance.GameState.IN_ACTION

func release_click():
	return Input.is_action_just_released("fire_hook") and Game.instance.state != Game.instance.GameState.GAME_OVER

func pull_target():
	is_pulling = true

func get_grappling_distance():
	return grappling_distance

func get_grapple_point():
	return grapple_point

func get_fire_point():
	return global_position

func start_hooking():
	grappling_rope.enable()
	hook.set_target(grapple_point)
	hook.active(true)
	#grapple_sound.play_random_sound()

func move_hook_tip_of_rope():
	if hook.is_active():
		hook.global_position = grappling_rope.get_last_position()

func move_toward_submarine():
	grapple_point = grapple_point.lerp(global_position, get_process_delta_time() * pull_speed)
	
	if object_to_pull != null:
		object_to_pull.global_position = grapple_point

func reset_grappling_requirement():
	is_pulling = false
	grappling_rope.disable()
	hook.active(false)
	
	object_to_pull = null
	grapple_point = Vector2.ZERO
	grappling_distance = Vector2.ZERO
	_attachedOres.clear()

func have_reach_submarine():
	var hook_pos = hook.global_position
	var distance_remaining = global_position.distance_to(hook_pos)
	
	return distance_remaining < 15

func set_grappling_requirement():
	var click_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var direction_vector = (click_pos - global_position).normalized()
	
	# Debug visualization in Godot
	# DrawLine3D equivalent might be needed for visualization
	
	# Godot raycasting
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction_vector * get_hook_distance())
	query.collision_mask = 0b00000000_00000000_00000000_00000100 # Layer 4 (Resource layer)
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is PoolableOre:
		object_to_pull = result.collider
		grapple_point = result.position
	else:
		var new_pos = global_position + (direction_vector * get_hook_distance())
		grapple_point = new_pos
	
	grappling_distance = global_position - grapple_point
	grappling_rope.enable()

func getOreToInventory():
	var size = _attachedOres.size()
	for i in size:
		if _attachedOres.size() > 0:  # Double-check size before popping
			var ore = _attachedOres.pop_back()
			if ore != null:  # Make sure the ore exists
				Inventory.addOre(ore)
				ore.release()
	
	# Ensure the array is empty after processing
	_attachedOres.clear()

func check_auto_reel():
	if _attachedOres.size() >= Submarine.instance.hook_capacity_upgrade and hook.is_active() and not is_pulling:
		start_pulling()
