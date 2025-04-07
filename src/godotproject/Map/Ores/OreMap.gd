extends Node

# signal on_explosion(indexPos: Vector2i)

@export var pxToIndexRatio: float = 32

var oreData := {}

func _ready() -> void:
	pass

func moveOreAt(pos: Vector2) -> void:
	var xIdx = pos.x / pxToIndexRatio
	var yIdx = pos.y / pxToIndexRatio
	
	var indexPos = Vector2i(xIdx, yIdx)
	oreData[indexPos] = true
	
func hasMoved(checkPoint: Vector2i):
	return oreData.has(checkPoint)
