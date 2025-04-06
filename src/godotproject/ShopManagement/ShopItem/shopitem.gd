class_name ShopItem extends Panel

signal shop_item_selected(itemDef: ShopItemDef)

@export var titleLabel: Label
@export var iconTextureRect: TextureRect
@export var priceLabel: Label

var _itemDef: ShopItemDef

func build(itemDef: ShopItemDef):
	_itemDef = itemDef
	
	titleLabel.text = _itemDef.title
	priceLabel.text = ("%.2f" % _itemDef.price) + " $"
	iconTextureRect.texture = _itemDef.icon

func _on_button_button_up() -> void:
	emit_signal("shop_item_selected", _itemDef)
