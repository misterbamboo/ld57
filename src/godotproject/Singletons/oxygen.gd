extends Node

var quantity: float
var capacity: float

@export var starting_quantity: float = 100.0
@export var starting_capacity: float = 100.0
@export var reduction_per_sec: float = 3.333 # 3 + 1/3
@export var recuperation_per_sec: float = 20.0

func _ready():
	quantity = starting_quantity
	capacity = starting_capacity

func _process(delta: float) -> void:
	if Submarine.instance.get_deepness() > 0 and not Game.instance.invincible:
		quantity -= delta * reduction_per_sec
	else:
		quantity += delta * recuperation_per_sec

	quantity = clamp(quantity, 0, capacity)

	_update_oxygen()

func _update_oxygen():
	if Submarine.instance.oxygen_upgrade_bought:
		capacity += 50
		Submarine.instance.oxygen_upgrade_bought = false

# Méthodes pour garder compatibilité avec interface
func get_quantity() -> float:
	return quantity

func get_capacity() -> float:
	return capacity
