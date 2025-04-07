class_name Hook extends Node2D

@onready var sprite: Sprite2D = $Sprite2D  # Reference to the Sprite2D node

var target_pos = Vector3.ZERO

func _physics_process(delta):
	update_rotation()

func set_target(target: Vector2):
	self.target_pos = Vector3(target.x, target.y, 0)

func active(value: bool):
	sprite.visible = value

func is_active() -> bool:
	return sprite.visible

func update_rotation():
	if not is_active():
		return
	
	var dir = Vector2(target_pos.x, target_pos.y) - global_position
	if (abs(dir.x) > 0.1 or abs(dir.y) > 0.1):
		var angle = atan2(dir.y, dir.x)
		rotation = angle  # Godot uses radians directly for rotation
