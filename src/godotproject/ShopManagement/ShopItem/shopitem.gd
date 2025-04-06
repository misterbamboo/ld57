class_name ShopItem extends Panel

signal shop_item_selected(key: String, title: String, icon: Texture2D, description: String, price: float)

@export var titleLabel: Label
@export var iconTextureRect: TextureRect
@export var priceLabel: Label

var _key: String = ""
var _title: String = ""
var _description: String = ""
var _price: float = 0.0
var _icon: Texture2D = null

func build(key: String, title: String, icon: Texture2D, description: String, price: float):
	_key = key
	_title = title
	_icon = icon
	_description = description
	_price = price
	
	titleLabel.text = _title
	priceLabel.text = ("%.2f" % _price) + " $"
	iconTextureRect.texture = _icon

func _on_button_button_up() -> void:
	emit_signal("shop_item_selected", _key, _title, _icon, _description, _price)
