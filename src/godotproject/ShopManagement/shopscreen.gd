class_name ShopScreen extends Control

@export var shopDefinitions: Array[ShopItemDef] = []

@export var moneyDisplayLabel: Label

@export var buyButton: Button
@export var titleLabel: Label
@export var descriptionLabel: RichTextLabel
@export var priceLabel: Label
@export var shopItemsContainer: GridContainer
@export var shopItemComponent: PackedScene
var shopItems : Array[ShopItem] = []

var selectedPrice: float = 0

@export var temp_oxy_icon: Texture2D

func _ready() -> void:
	visible = false
	_reset_ui()
	
	for shopDef in shopDefinitions:
		_add_item_to_shop(shopDef.key, shopDef.title, shopDef.icon, shopDef.description, shopDef.price)
	#_add_item_to_shop("oxy2", "Super Oxy", temp_oxy_icon, "Give you a LOT of oxygen for deap dives", 499.99)
	#_add_item_to_shop("oxy3", "AwesOxy", temp_oxy_icon, "Awsome oxy can bring you to the MOON", 59999.99)

func _reset_ui():
	titleLabel.text = "Select an item"
	descriptionLabel.text = ""
	priceLabel.text = ""
	_updateItemState(false)
	
func _add_item_to_shop(key: String, title: String, icon: Texture2D, description: String, price: float):
	var item = shopItemComponent.instantiate() as ShopItem
	item.build(key, title, icon, description, price)
	item.shop_item_selected.connect(_shop_item_selected)
	shopItems.append(item)
	shopItemsContainer.add_child(item)
	
func displayScreen():
	_reset_ui()
	visible = true
	moneyDisplayLabel.text = ("%.2f" % MoneyBag.getTotal()) + " $"
	Oxygen.inactive()
	Game.instance.change_state(Game.GameState.IN_SHOP)

func _shop_item_selected(key: String, title: String, icon: Texture2D, description: String, price: float):
	titleLabel.text = title
	descriptionLabel.text = description
	priceLabel.text = ("%.2f" % price) + " $"
	selectedPrice = price
	_updateItemState(true)

func _updateItemState(itemSelected: bool):
	buyButton.disabled = !itemSelected or MoneyBag.getTotal() < selectedPrice
	titleLabel.visible = itemSelected
	descriptionLabel.visible = itemSelected
	priceLabel.visible = itemSelected 

func _on_exit_button_up() -> void:
	visible = false
	Oxygen.active()
	Game.instance.change_state(Game.GameState.IN_ACTION)
