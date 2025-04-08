extends PoolableNode2D
class_name PoolableOre

@export var copperTex: Texture2D
@export var ironTex: Texture2D
@export var goldTex: Texture2D
@export var diamondTex: Texture2D
@export var platinumTex: Texture2D

var color: Color = Color.WHITE
@onready var sprite = $Sprite2D

var _oreName: String = "copper"
func getOreName() -> String: return _oreName

func _on_retrieve_from_pool(pooler: NodePooler) -> void:
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

# Override the reset method from PoolableNode2D
func reset() -> void:
	# Reset ore state when returned to the pool
	color = Color.WHITE
	
	if sprite:
		sprite.modulate = Color.WHITE
		
	# Any other properties that need resetting
	visible = false

# If this ore gets destroyed or needs to be released
func _on_ore_destroyed() -> void:
	# This automatically returns the ore to the pool
	release()
	
# If you need ore to automatically return to pool when outside visible area
func _on_screen_exited() -> void:
	release()
