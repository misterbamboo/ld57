extends Node

@export var coperUI: InventoryItemUI
@export var diamondUI: InventoryItemUI
@export var goldUI: InventoryItemUI
@export var ironUI: InventoryItemUI
@export var platnumUI: InventoryItemUI

func _process(delta: float) -> void:
	if coperUI.count != Inventory.copper_quantity:
		coperUI.updateItemCount(Inventory.copper_quantity)
		
	if diamondUI.count != Inventory.diamond_quantity:
		diamondUI.updateItemCount(Inventory.diamond_quantity)
		
	if goldUI.count != Inventory.gold_quantity:
		goldUI.updateItemCount(Inventory.gold_quantity)
		
	if ironUI.count != Inventory.iron_quantity:
		ironUI.updateItemCount(Inventory.iron_quantity)
		
	if platnumUI.count != Inventory.platinum_quantity:
		platnumUI.updateItemCount(Inventory.platinum_quantity)
