@tool
extends Control
class_name InventoryItemUI

var _icon: Texture2D
@export var icon: Texture2D:
	set(value):
		_icon = value
		_refresh()
	get:
		return _icon

var _count: int
@export var count: int:
	set(value):
		_count = value
		_refresh()
	get:
		return _count
		
var _unitPrice: float
@export var unitPrice: float:
	set(value):
		_unitPrice = value
		_refresh()
	get:
		return _unitPrice

func _refresh():
	if has_node("Icon"):
		$Icon.texture = _icon
		$Icon.visible = _count != 0
	if has_node("Count"):
		$Count.text = str(count)
		$Count.visible = _count != 0
	if has_node("Price"):
		var price: float = float(_count) * _unitPrice
		$Price.text = " @ %.2f $/unit : %.2f $" % [ _unitPrice , price]
		$Price.visible = _unitPrice > 0

func updateItemCount(count: int):
	_count = count
	_refresh()
	
func updateItemUnitPrice(unitPrice: float):
	_unitPrice = unitPrice
	_refresh()
