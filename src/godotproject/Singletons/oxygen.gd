extends Node

var quantity: float
var oxy_capacity: float
func _get_oxy_capacity() -> float:
	var upg_capacity = 0 if Submarine.instance == null else Submarine.instance.oxygen_capacity_upgrade
	return oxy_capacity + upg_capacity

@export var starting_quantity: float = 100.0
@export var starting_capacity: float = 100.0
@export var reduction_per_sec: float = 3.333 # 3 + 1/3
@export var recuperation_per_sec: float = 20.0

var isInactive: bool = false

func _ready() -> void:
	quantity = starting_quantity
	oxy_capacity = starting_capacity

func inactive():
	isInactive = true
	
func active():
	isInactive = false

func _process(delta: float) -> void:
	var deepness = 0 if Submarine.instance == null else Submarine.instance.get_deepness()
	var invincible = false if Game.instance == null else  Game.instance.invincible
	
	if(isInactive):
		quantity += delta * recuperation_per_sec
	elif deepness > 0 and not invincible:
		quantity -= delta * reduction_per_sec
	else:
		quantity += delta * recuperation_per_sec

	quantity = clamp(quantity, 0, _get_oxy_capacity())

# Méthodes pour garder compatibilité avec interface
func get_quantity() -> float:
	return quantity

func get_capacity() -> float:
	return _get_oxy_capacity()
