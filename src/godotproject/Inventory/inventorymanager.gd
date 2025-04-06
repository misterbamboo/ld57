class_name InventoryManager extends Node #Area2D

const SoundNames = preload("res://Audio/soundname.gd")

static var instance: InventoryManager = null

var inventory: Array = []

var gold_quantity: float = 0
var platinum_quantity: float = 0
var copper_quantity: float = 0
var diamond_quantity: float = 0
var iron_quantity: float = 0

var cash: float = 0
var has_inventory: bool = false
var can_sell: bool = false

func _ready():
	instance = self
	_reset_inventory()

func _on_inventory_body_entered(body: Node2D) -> void:
	_check_ressource(body)

func _on_inventory_area_entered(area: Area2D) -> void:
	_check_ressource(area)

func _check_ressource(obj: Node) -> void:
	if not obj.has_method("get_name") or not obj.has_method("get_sell_price"):
		return
	
	var ressource_name = obj.get_name()

	has_inventory = true

	match ressource_name:
		"Gold":
			gold_quantity += 1
		"Platinum":
			platinum_quantity += 1
		"Copper":
			copper_quantity += 1
		"Diamond":
			diamond_quantity += 1
		"Iron":
			iron_quantity += 1

	inventory.append(obj)
	AudioManager.instance.play_sound(SoundNames.SoundName.MATERIAL1)

	MapGenerator.instance.remove_ressource(obj)
	obj.visible = false
	obj.set_physics_process(false)

func _process(_delta):
	if can_sell and has_inventory and Input.is_action_pressed("sell_inventory"):
		_sell_inventory()
		has_inventory = false

func _on_inventory_area_stay(area: Area2D):
	if area.is_in_group("BoatStore"):
		can_sell = true

func _on_inventory_area_exited(area: Area2D):
	if area.is_in_group("BoatStore"):
		can_sell = false

func _sell_inventory():
	var value := 0.0
	for res in inventory:
		value += res.get_sell_price()
		
	MoneyBag.addMoney(value)
	AudioManager.instance.play_sound(SoundNames.SoundName.SELL_RESSOURCES)
	_reset_inventory()

func _reset_inventory():
	inventory.clear()
	gold_quantity = 0
	platinum_quantity = 0
	copper_quantity = 0
	diamond_quantity = 0
	iron_quantity = 0
