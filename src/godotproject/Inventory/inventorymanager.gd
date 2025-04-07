class_name InventoryManager extends Node #Area2D

const SoundNames = preload("res://Audio/soundname.gd")

var copper_quantity: int = 5
var iron_quantity: int = 4
var gold_quantity: int = 3
var diamond_quantity: int = 2
var platinum_quantity: int = 1

var copper_price: float = 5
var iron_price: float = 15
var gold_price: float = 60
var diamond_price: float = 250
var platinum_price: float = 1500

var inventoryTotalQuantity: int:
	get:
		return gold_quantity \
			+ platinum_quantity \
			+ copper_quantity \
			+ diamond_quantity \
			+ iron_quantity

var has_inventory: bool:
	get:
		return inventoryTotalQuantity > 0
		
var can_sell: bool = false

func _ready():
	pass

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

	AudioManager.instance.play_sound(SoundNames.SoundName.MATERIAL1)

	# TODO: 
	# commenting this line out because resources are not implemented yet
	# and also map generator has changed and it not used globaly like that anymore
	# but this is where we should call to remove the resource that was gathered so
	# i'm leaving the line here for now
	#MapGenerator.instance.remove_ressource(obj)

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
	value += gold_quantity * gold_price
	value += platinum_quantity * platinum_price
	value += copper_quantity * copper_price
	value += diamond_quantity * diamond_price
	value += iron_quantity * iron_price
		
	MoneyBag.addMoney(value)
	AudioManager.instance.play_sound(SoundNames.SoundName.SELL_RESSOURCES)
	_reset_inventory()

func _reset_inventory():
	copper_quantity = 0
	diamond_quantity = 0
	gold_quantity = 0
	iron_quantity = 0
	platinum_quantity = 0
