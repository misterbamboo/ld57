class_name Torpedo extends RigidBody2D

@export var explosionTarget: Node2D
@export var explosion: PackedScene

var launched: bool = false
var traveling: bool = false

var max_accel_force := 1500
var accel_t := 0.0

var _anim: AnimationPlayer 
func _ready() -> void:
	_anim = $Node2D/AnimationLaunch
	freeze = true
	$CollisionPolygon2D.disabled = true
	
	contact_monitor = true
	max_contacts_reported = 10

func launch():
	_anim.play("launch")
	launched = true
	
func travel():
	traveling = true
	freeze = false
	$CollisionPolygon2D.disabled = false
	accel_t = 0.5
	
func _process(delta: float) -> void:
	if launched and !traveling:
		waitForTravel()
	elif launched and traveling:
		move(delta)
	else:
		pass
		
func waitForTravel():
	if _anim.current_animation != "":
		var animT = _anim.current_animation_position / _anim.current_animation_length
	elif launched:
		travel()
	
func move(delta: float):
	accel_t += delta
	var t = accel_t * accel_t
	var accel = max_accel_force * t
	linear_velocity = Vector2.RIGHT.rotated(rotation) * accel
	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		for i in state.get_contact_count():
			var collision_point = state.get_contact_local_position(i)
			var collider = state.get_contact_collider_object(i)
			var normal = state.get_contact_local_normal(i)
			_spawn_explosion(collision_point)
			queue_free()
			break
			
func _spawn_explosion(pos: Vector2):
	var instance = explosion.instantiate() as Node2D
	instance.position = pos
	get_tree().root.add_child(instance)
