class_name ShopItemDef extends Resource

const UpgradeType = preload("res://Upgrades/upgrade_type.gd").UpgradeType

@export var key: String
@export var requirement_key: String
@export var title: String
@export var description: String
@export var repeatable: bool = false
@export var price: float
@export var icon: Texture2D

@export var upgradeType: UpgradeType = UpgradeType.NONE
@export var upgradeValue: float = 0.0

@export var upgradeType2: UpgradeType = UpgradeType.NONE
@export var upgradeValue2: float = 0.0
