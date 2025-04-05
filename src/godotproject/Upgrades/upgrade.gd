extends Node

class_name Upgrade

const UT = preload("res://Upgrades/upgrade_type.gd")

static func get_cost(upgrade_type: UT.UpgradeType) -> int:
	match upgrade_type:
		UT.UpgradeType.HEALTH_UPGRADE:
			return 10
		UT.UpgradeType.LIGHT_UPGRADE:
			return 25
		UT.UpgradeType.OXYGEN_UPGRADE:
			return 50
		UT.UpgradeType.SPEED_UPGRADE:
			return 40
		UT.UpgradeType.HOOK_UPGRADE:
			return 40
		UT.UpgradeType.HULL_UPGRADE:
			return 20
		_:
			return 10

static func get_sprite(upgrade_type: UT.UpgradeType) -> Texture2D:
	match upgrade_type:
		UT.UpgradeType.HEALTH_UPGRADE:
			return GameAssets.instance.health_upgrade_image
		UT.UpgradeType.LIGHT_UPGRADE:
			return GameAssets.instance.light_upgrade_image
		UT.UpgradeType.OXYGEN_UPGRADE:
			return GameAssets.instance.oxygen_upgrade_image
		UT.UpgradeType.SPEED_UPGRADE:
			return GameAssets.instance.speed_upgrade_image
		UT.UpgradeType.HOOK_UPGRADE:
			return GameAssets.instance.hook_upgrade_image
		UT.UpgradeType.HULL_UPGRADE:
			return GameAssets.instance.hull_upgrade_image
		_:
			return GameAssets.instance.health_upgrade_image
