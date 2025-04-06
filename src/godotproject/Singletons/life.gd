extends Node

var life_quantity: float
var life_capacity: float
func _get_life_capacity() -> float:
	var upg_capacity = 0 if Submarine.instance == null else Submarine.instance.hull_capacity_upgrade
	return life_capacity + upg_capacity
	
var losing_life := false

var starting_quantity := 100.0
var starting_capacity := 100.0
var reduction_per_sec_when_no_oxy := 20.0 # 5 seconds

func _ready() -> void:
	life_quantity = starting_quantity
	life_capacity = starting_capacity

func _process(delta: float) -> void:
	var is_losing = false
	if Oxygen.quantity <= 0 and not Game.instance.invincible:
		life_quantity -= delta * reduction_per_sec_when_no_oxy
		is_losing = true

	losing_life = is_losing
	life_quantity = clamp(life_quantity, 0, _get_life_capacity())

func refill(amount: float):
	life_quantity = clamp(life_quantity + amount, 0, _get_life_capacity())

func hit(damage: float) -> void:
	life_quantity = clamp(life_quantity - damage, 0, _get_life_capacity())
	losing_life = true

func is_dead() -> bool:
	return life_quantity <= 0

func get_quantity() -> float:
	return life_quantity

func get_capacity() -> float:
	return _get_life_capacity()

func is_losing_life() -> bool:
	return losing_life
