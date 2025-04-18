class_name Submarine extends Node2D

@export var cell_size: int = 50
const UT = preload("res://Upgrades/upgrade_type.gd")
const SoundNames = preload("res://Audio/soundname.gd")

static var instance: Submarine = null
static var rb : RigidBody2D = null
func use_torpedo():
	torpedo_amount_upgrade -= 1

func _ready():
	instance = self
	rb = get_node_or_null("..") # RigidBody should be parent

func get_deepness() -> int:
	return int(get_sensitive_deepness())

func get_sensitive_deepness() -> float:
	if(rb == null):
		return 0
		
	return clamp(rb.position.y / cell_size, 0, INF)

func get_special_deepness(special_cell_size: int) -> int:
	if(rb == null):
		return 0
		
	return int(clamp(rb.position.y / special_cell_size, 0, INF))


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

var hook_length_upgrade: float = 100
func increase_hook_length(amount: float):
	hook_length_upgrade += amount

var hook_capacity_upgrade: float = 1
func increase_hook_capacity(amount: float):
	hook_capacity_upgrade += amount

var hull_capacity_upgrade: float = 50
func increase_hull(amount: float):
	hull_capacity_upgrade += amount

var torpedo_amount_upgrade: int
func increase_torpedo_amount(amount: int):
	torpedo_amount_upgrade += amount
