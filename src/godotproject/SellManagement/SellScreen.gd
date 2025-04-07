extends Control
class_name SellScreen

@export var coperUI: InventoryItemUI
@export var diamondUI: InventoryItemUI
@export var goldUI: InventoryItemUI
@export var ironUI: InventoryItemUI
@export var platnumUI: InventoryItemUI

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	_reset_ui()
	
func _reset_ui():
	if coperUI.count != Inventory.copper_quantity:
		coperUI.updateItemCount(Inventory.copper_quantity)
		coperUI.updateItemUnitPrice(Inventory.copper_price)
		
	if ironUI.count != Inventory.iron_quantity:
		ironUI.updateItemCount(Inventory.iron_quantity)
		ironUI.updateItemUnitPrice(Inventory.iron_price)
		
	if goldUI.count != Inventory.gold_quantity:
		goldUI.updateItemCount(Inventory.gold_quantity)
		goldUI.updateItemUnitPrice(Inventory.gold_price)
		
	if diamondUI.count != Inventory.diamond_quantity:
		diamondUI.updateItemCount(Inventory.diamond_quantity)
		diamondUI.updateItemUnitPrice(Inventory.diamond_price)
		
	if platnumUI.count != Inventory.platinum_quantity:
		platnumUI.updateItemCount(Inventory.platinum_quantity)
		platnumUI.updateItemUnitPrice(Inventory.platinum_price)
		
func displayScreen():
	visible = true

func _on_sell_button_pressed() -> void:
	Inventory._sell_inventory()
	visible = false

func _on_exit_button_pressed() -> void:
	visible = false
