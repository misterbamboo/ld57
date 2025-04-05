class_name Life extends Node

var quantity: float
var capacity: float
var losing_life := false

var starting_quantity := 100.0
var starting_capacity := 100.0
var reduction_per_sec_when_no_oxy := 20.0 # 5 seconds

static var instance: Life = null

func _ready():
	instance = self
	quantity = starting_quantity
	capacity = starting_capacity

func _process(delta: float) -> void:
	var is_losing = false
	if Oxygen.instance.quantity <= 0 and not Game.instance.invincible:
		quantity -= delta * reduction_per_sec_when_no_oxy
		is_losing = true

	losing_life = is_losing
	quantity = clamp(quantity, 0, capacity)

	_update_life()

func _update_life():
	if Submarine.instance.life_upgrade_bought:
		quantity += 25
		Submarine.instance.life_upgrade_bought = false

	if Submarine.instance.hull_upgrade_bought:
		if quantity != capacity:
			capacity += 25
			quantity += 25
			Submarine.instance.hull_upgrade_bought = false
			print("Hull upgraded hheeeheee")

func hit(damage: float) -> void:
	quantity = clamp(quantity - damage, 0, capacity)
	losing_life = true

func is_dead() -> bool:
	return quantity <= 0

func get_quantity() -> float:
	return quantity

func get_capacity() -> float:
	return capacity

func is_losing_life() -> bool:
	return losing_life
