class_name Submarine extends Node2D

const UT = preload("res://Upgrades/upgrade_type.gd")
const SoundNames = preload("res://Audio/soundname.gd")

var speed_upgrade_bought := false
var oxygen_upgrade_bought := false
var life_upgrade_bought := false
var light_upgrade_bought := false
var hook_upgrade_bought := false
var hull_upgrade_bought := false

static var instance : Submarine = null
static var rb : RigidBody2D = null

var map := MapGenerator.instance

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

# Fonctions pour appliquer les améliorations
func increase_oxygen():
	oxygen_upgrade_bought = true

func increase_health():
	life_upgrade_bought = true

func increase_light():
	light_upgrade_bought = true

func increase_speed():
	speed_upgrade_bought = true

func increase_hook():
	hook_upgrade_bought = true

func increase_hull():
	hull_upgrade_bought = true

func bought_upgrade(upgrade_type):
	match upgrade_type:
		UT.UpgradeType.OXYGEN_UPGRADE:
			increase_oxygen()
		UT.UpgradeType.HEALTH_UPGRADE:
			increase_health()
		UT.UpgradeType.LIGHT_UPGRADE:
			increase_light()
		UT.UpgradeType.SPEED_UPGRADE:
			increase_speed()
		UT.UpgradeType.HOOK_UPGRADE:
			increase_hook()
		UT.UpgradeType.HULL_UPGRADE:
			increase_hull()
	
	AudioManager.instance.play_sound(SoundNames.SoundName.UPGRADE1)

func try_spend_money_amount(amount: int) -> bool:
	if InventoryManager.instance.inventory_reward >= amount:
		InventoryManager.instance.inventory_reward -= amount
		return true
	return false
