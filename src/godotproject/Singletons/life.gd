extends Node

var life_quantity: float
var life_capacity: float

func _get_life_capacity() -> float:
	return life_capacity

var starting_quantity := 100.0
var starting_capacity := 100.0
var reduction_per_sec_when_no_oxy := 5.0 # 20 seconds

func _ready() -> void:
	life_quantity = starting_quantity
	life_capacity = starting_capacity

func _process(delta: float) -> void:
	if Oxygen.quantity <= 0 and not Game.instance.invincible:
		life_quantity -= delta * reduction_per_sec_when_no_oxy

	life_quantity = clamp(life_quantity, 0, _get_life_capacity())

func refill(amount: float):
	life_quantity = clamp(life_quantity + amount, 0, _get_life_capacity())

func hit(damage: float) -> void:
	# Apply the percentage-based damage resistance using the formula: Dm = Du / (1 + R/100)
	# la formule est assez intuitive, basically + 1 d'armure = + 1% de effective health
	var armor = Submarine.instance.hull_capacity_upgrade
	var damageAfterResistance = damage / (1 + armor / 100.0)
	print("BANG! Taking %s damage reduced to %s after armor upgrades!" % [damage, damageAfterResistance])

	life_quantity = clamp(life_quantity - damageAfterResistance, 0, _get_life_capacity())

func is_dead() -> bool:
	return life_quantity <= 0

func get_quantity() -> float:
	return life_quantity

func get_capacity() -> float:
	return _get_life_capacity()
