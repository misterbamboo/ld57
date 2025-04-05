extends Node

class_name GameAssets

static var instance: GameAssets = null

@export var health_upgrade_image: Texture2D
@export var light_upgrade_image: Texture2D
@export var oxygen_upgrade_image: Texture2D
@export var speed_upgrade_image: Texture2D
@export var hook_upgrade_image: Texture2D
@export var hull_upgrade_image: Texture2D

func _ready():
	instance = self
