class_name Money extends Node

var money: float = 0

func getTotal() -> float:
	return money

func addMoney(value: float):
	money += value
	
func tryRemoveMoney(value: float) -> bool:
	if(money >= value):
		money -= value
		return true
	return false
