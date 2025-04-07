class_name GrapplingRope extends Node2D

@export var precision = 40
@export var straighten_line_speed = 50.0
@export var rope_animation_curve: Curve
@export var start_wave_size = 2
@export var rope_progression_curve: Curve
@export_range(1, 50) var rope_progression_speed = 1
@export var start_straightening_progress = 0.3  # Start straightening when 30% extended

@onready var line: Line2D = $Line2D
@onready var grapple: Grapple = get_parent() as Grapple

var wave_size = 0
var move_time = 0.0
var is_grappling = true
var straight_line = true
var initialized = false
var debug_mode = false  # Set to false to disable debug prints

var default_animation_curve: Curve
var default_progression_curve: Curve

func _ready():
	line.width = 2.0
	line.default_color = Color(1, 1, 1)
	
	line.visible = false
	visible = false
	
	if rope_animation_curve == null:
		default_animation_curve = Curve.new()
		default_animation_curve.add_point(Vector2(0, 0))
		default_animation_curve.add_point(Vector2(0.5, 1))
		default_animation_curve.add_point(Vector2(1, 0))
		rope_animation_curve = default_animation_curve
	
	initialized = true

func _process(delta):
	if visible and initialized:
		move_time += delta
		draw_rope()

func enable():
	if initialized:
		initialize_rope()
		visible = true
	else:
		call_deferred("enable")

func disable():
	visible = false
	is_grappling = false
	line.visible = false

func initialize_rope():
	move_time = 0.0
	
	line.clear_points()
	for i in range(precision):
		line.add_point(Vector2.ZERO)
	
	wave_size = start_wave_size
	straight_line = false
	
	line_points_to_fire_point()
	
	line.visible = true
	is_grappling = true
	
	if debug_mode:
		print("Rope initialized with wave_size: ", wave_size)

func get_last_position():
	if line.get_point_count() > 0:
		var line_pos = line.get_point_position(line.get_point_count() - 1)
		return line.global_position + line_pos
	
	return Vector2.ZERO

func draw_rope():
	if !straight_line:
		var last_point = line.get_point_position(precision - 1)
		var target_point = grapple.get_grapple_point() - global_position
		
		var distance = last_point.distance_to(target_point)
		if debug_mode:
			print("Distance to target: ", distance)
		
		# Get current extension progress
		var extension_progress = get_extension_progress()
		
		# Start reducing wave size once we've reached a certain extension progress
		if extension_progress > start_straightening_progress:
			var reduction_factor = (extension_progress - start_straightening_progress) / (1.0 - start_straightening_progress)
			var decrease_amount = get_process_delta_time() * straighten_line_speed * reduction_factor
			wave_size = max(0, wave_size - decrease_amount)
			
			if debug_mode and Engine.get_frames_drawn() % 30 == 0:
				print("Extension progress: ", extension_progress, ", Reducing wave by: ", decrease_amount)
		
		if distance < 1.0:
			if debug_mode:
				print("SWITCHING TO STRAIGHT LINE MODE")
			straight_line = true
		
		draw_rope_waves()
	else:
		if !is_grappling:
			is_grappling = true
		
		if wave_size > 0:
			var decrease_amount = get_process_delta_time() * straighten_line_speed
			wave_size -= decrease_amount
			
			if debug_mode and Engine.get_frames_drawn() % 30 == 0:  
				print("Wave size: ", wave_size, " Decrease amount: ", decrease_amount)
			
			if wave_size < 0.1:
				wave_size = 0
				
			draw_rope_waves()
		else:
			wave_size = 0
			
			if debug_mode:
				print("Drawing straight rope")
				
			line.clear_points()
			line.add_point(grapple.get_fire_point() - global_position)
			line.add_point(grapple.get_grapple_point() - global_position)

# Calculate how far along the rope has extended (0 to 1)
func get_extension_progress() -> float:
	# Use progression_value from draw_rope_waves
	var progress = min(move_time * rope_progression_speed, 1.0)
	if rope_progression_curve:
		progress = rope_progression_curve.sample(progress)
	return progress

func line_points_to_fire_point():
	var fire_point_local = grapple.get_fire_point() - global_position
	for i in range(precision):
		line.set_point_position(i, fire_point_local)

func draw_rope_waves():
	for i in range(precision):
		var delta = float(i) / (float(precision) - 1.0)
		
		var perpendicular = Vector2(-grapple.get_grappling_distance().y, grapple.get_grappling_distance().x).normalized()
		
		var animation_value = delta
		if rope_animation_curve:
			animation_value = rope_animation_curve.sample(delta)
			
		var progression_value = min(move_time * rope_progression_speed, 1.0)
		if rope_progression_curve:
			progression_value = rope_progression_curve.sample(progression_value)
		
		var offset = perpendicular * animation_value * wave_size
		
		var fire_point_local = grapple.get_fire_point() - global_position
		var grapple_point_local = grapple.get_grapple_point() - global_position
		
		var target_position = fire_point_local.lerp(grapple_point_local, delta) + offset
		var current_position = fire_point_local.lerp(target_position, progression_value)
		
		line.set_point_position(i, current_position)

func draw_rope_no_waves():
	line.clear_points()
	line.add_point(grapple.get_fire_point() - global_position)
	line.add_point(grapple.get_grapple_point() - global_position)
