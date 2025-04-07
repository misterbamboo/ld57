extends Node2D
class_name Ore

@export var copperTex: Texture2D
@export var ironTex: Texture2D
@export var goldTex: Texture2D
@export var diamondTex: Texture2D
@export var platinumTex: Texture2D

@export var sprite: Sprite2D

@export var color: Color

var _oreName: String = "copper"
func getOreName() -> String: return _oreName

func _ready() -> void:
	if !NoiseGenService.loaded:
		NoiseGenService.loadAll()
	setColor(color)

func setColor(newcolor: Color):
	if newcolor == NoiseGenService.getIronColor():
		sprite.texture = ironTex
		_oreName = NoiseGenService.IronKey
	elif newcolor == NoiseGenService.getGoldColor():
		sprite.texture = goldTex
		_oreName = NoiseGenService.GoldKey
	elif newcolor == NoiseGenService.getDiamondColor():
		sprite.texture = diamondTex
		_oreName = NoiseGenService.DiamondKey
	elif newcolor == NoiseGenService.getPlatinumColor():
		sprite.texture = platinumTex
		_oreName = NoiseGenService.PlatinumKey
	else:
		sprite.texture = copperTex
		_oreName = NoiseGenService.CopperKey
	color = newcolor
