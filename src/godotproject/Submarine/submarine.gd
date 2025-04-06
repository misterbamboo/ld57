class_name Submarine extends Node2D

const SoundNames = preload("res://Audio/soundname.gd")

static var rb : RigidBody2D = null

var map := MapGenerator.instance

static var instance: Submarine
	
func _ready():
	instance = self
	rb = get_node_or_null("..") # RigidBody should be parent

func get_deepness() -> int:
	return int(get_sensitive_deepness())

func get_sensitive_deepness() -> float:
	if(rb == null):
		return 0
	
	if(map == null)	:
		map = MapGenerator.instance
		
	return clamp(rb.position.y / map.cell_size, 0, INF)

func _on_Submarine_body_entered(body: Node) -> void:
	var collider := body.get_node_or_null("CollisionPolygon2D")
	
	if collider and rb.linear_velocity.length() >= 1:
		var damage = (rb.linear_velocity.length() - 1) * 2
		Life.hit(damage)

var oxygen_capacity_upgrade: float
func increase_oxygen(amount: float):
	oxygen_capacity_upgrade += amount

var health_capacity_upgrade: float
func increase_health(amount: float):
	health_capacity_upgrade += amount

var light_capacity_upgrade: float
func increase_light(amount: float):
	light_capacity_upgrade += amount

var speed_capacity_upgrade: float
func increase_speed(amount: float):
	speed_capacity_upgrade += amount

var hook_capacity_upgrade: float
func increase_hook(amount: float):
	hook_capacity_upgrade += amount
	
var hull_capacity_upgrade: float
func increase_hull(amount: float):
	hull_capacity_upgrade += amount
