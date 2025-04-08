class_name Hook extends Node2D

signal onOreAttached(ore: Ore)

@onready var sprite: Sprite2D = $Sprite2D  # Reference to the Sprite2D node

var target_pos = Vector3.ZERO
var capacity_reached = false

func _physics_process(delta):
	update_rotation()

func set_target(target: Vector2):
	self.target_pos = Vector3(target.x, target.y, 0)

func active(value: bool):
	sprite.visible = value
	if value == false:
		capacity_reached = false

func is_active() -> bool:
	return sprite.visible

func set_capacity_reached(value: bool):
	capacity_reached = value

func update_rotation():
	if not is_active():
		return
	
	var dir = Vector2(target_pos.x, target_pos.y) - global_position
	if (abs(dir.x) > 0.1 or abs(dir.y) > 0.1):
		var angle = atan2(dir.y, dir.x)
		rotation = angle  # Godot uses radians directly for rotation

func _on_area_2d_area_entered(area: Area2D) -> void:
	if !is_active() or capacity_reached:
		return
	if area.name == "OreArea":
		if area.get_parent() is PoolableOre:
			var ore := area.get_parent() as PoolableOre
			call_deferred("_attach_ore", ore)
			
func _attach_ore(ore: PoolableOre):
	if ore.get_parent() != self:
		OreMap.collectOreAt(ore.global_position)
		ore.reparent(self)
		ore.position = Vector2.ZERO
		emit_signal("onOreAttached", ore)
