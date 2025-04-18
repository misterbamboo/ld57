class_name ShopScreen extends Control

const UpgradeType = preload("res://Upgrades/upgrade_type.gd").UpgradeType

@export var shopDefinitions: Array[ShopItemDef] = []

@export var moneyDisplayLabel: Label

@export var buyButton: Button
@export var titleLabel: Label
@export var descriptionLabel: RichTextLabel
@export var priceLabel: Label
@export var messageLabel: Label

@export var shopItemsContainer: GridContainer
@export var shopItemComponent: PackedScene

var bought_upgrade_keys: Array[String] = []
var shopItems : Array[ShopItem] = []

var selectedItem: ShopItemDef = null
var displayMessage: String = ""

@export var temp_oxy_icon: Texture2D

func _ready() -> void:
	visible = false
	_reset_ui()

func _reset_ui():
	moneyDisplayLabel.text = "Money: " + ("%.2f" % MoneyBag.getTotal()) + " $"
	titleLabel.text = "Select an item"
	descriptionLabel.text = ""
	priceLabel.text = ""
	messageLabel.text = ""
	displayMessage = ""
	_updateItemState(false)
	_redraw_items()

func _redraw_items():
	for item in shopItems:
		item.queue_free()
	shopItems.clear()
	
	for shopDef in shopDefinitions:
		if shopDef.requirement_key != "" and shopDef.requirement_key not in bought_upgrade_keys: 
			print("Skipping item: " + shopDef.key + " (requirement not met)")
			continue
		
		if shopDef.key in bought_upgrade_keys:
			print("Skipping item: " + shopDef.key + " (already bought)")
			continue
		
		_add_item_to_shop(shopDef)
	
func _add_item_to_shop(itemDef: ShopItemDef):
	var item = shopItemComponent.instantiate() as ShopItem
	item.build(itemDef)
	item.shop_item_selected.connect(_shop_item_selected)
	shopItems.append(item)
	shopItemsContainer.add_child(item)
	
func displayScreen():
	_reset_ui()
	visible = true
	Oxygen.inactive()
	Game.instance.change_state(Game.GameState.IN_SHOP)

func _shop_item_selected(itemDef: ShopItemDef):
	selectedItem = itemDef
	titleLabel.text = selectedItem.title
	descriptionLabel.text = selectedItem.description
	priceLabel.text = ("%.2f" % selectedItem.price) + " $"
	_updateItemState(true)

func _updateItemState(itemSelected: bool):
	buyButton.disabled = !itemSelected or MoneyBag.getTotal() < selectedItem.price
	titleLabel.visible = itemSelected
	descriptionLabel.visible = itemSelected
	priceLabel.visible = itemSelected 
	var shouldDisplayMessage = displayMessage != null and displayMessage.length() > 0
	messageLabel.visible = shouldDisplayMessage
	messageLabel.text = displayMessage

func _on_exit_button_up() -> void:
	visible = false
	Oxygen.active()
	Game.instance.change_state(Game.GameState.IN_ACTION)

func _on_buy_button_button_up() -> void:
	var isBuyable = MoneyBag.getTotal() >= selectedItem.price
	if(!isBuyable):
		displayMessage = "Not enought money"
		_updateItemState(true)
		return
		
	if(!MoneyBag.tryRemoveMoney(selectedItem.price)):
		displayMessage = "Not more money"
		_updateItemState(true)
		return
		
	if(selectedItem.upgradeType != UpgradeType.NONE):
		bought_upgrade(selectedItem.upgradeType, selectedItem.upgradeValue)
		
	if(selectedItem.upgradeType2 != UpgradeType.NONE):
		bought_upgrade(selectedItem.upgradeType2, selectedItem.upgradeValue2)
	
	# repeatable items don't get stored this way they still show up
	# when the shop is reloaded
	if (!selectedItem.repeatable):
		bought_upgrade_keys.append(selectedItem.key)

	_reset_ui()

func bought_upgrade(upgrade_type: UpgradeType, value: float):
	var submarine = Submarine.instance
	match upgrade_type:
		UpgradeType.OXYGEN_UPGRADE:
			submarine.increase_oxygen(value)
		UpgradeType.HEALTH_UPGRADE:
			submarine.increase_health(value)
		UpgradeType.LIGHT_UPGRADE:
			submarine.increase_light(value)
		UpgradeType.SPEED_UPGRADE:
			submarine.increase_speed(value)
		UpgradeType.HOOK_LENGTH_UPGRADE:
			submarine.increase_hook_length(value)
		UpgradeType.HOOK_CAPACITY_UPGRADE:
			submarine.increase_hook_capacity(value)
		UpgradeType.HULL_UPGRADE:
			submarine.increase_hull(value)
		UpgradeType.LIFE_RECOVER:
			Life.refill(value)
		UpgradeType.TORPEDO_UPGRADE:
			submarine.increase_torpedo_amount(int(value))
	
	#AudioManager.instance.play_sound(SoundNames.SoundName.UPGRADE1)
