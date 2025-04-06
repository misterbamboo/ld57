class_name Money extends Node

var money: float = 100

func getTotal() -> float:
	return money

func addMoney(value: float):
	money += value
