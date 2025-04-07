class_name ExplosionMapHandler extends Node

signal on_explosion(indexPos: Vector2i, radiusIdx: float)

@export var pxToIndexRatio: float = 32

var explosionData := {}

func _ready() -> void:
	pass

func addExplosionAt(pos: Vector2, radius: float) -> void:
	var xIdx = pos.x / pxToIndexRatio
	var yIdx = pos.y / pxToIndexRatio
	var radiusIdx = radius / pxToIndexRatio
	
	var indexPos = Vector2i(xIdx, yIdx)
	explosionData[indexPos] = radiusIdx
	
	emit_signal("on_explosion", indexPos, radiusIdx)
	
func hasExploded(checkPoint: Vector2i):
	for indexPos in explosionData.keys():
		var circlePos = indexPos as Vector2i
		var circleRadiusIdx: float = explosionData[indexPos]
		if pointInCercle(checkPoint, circlePos, circleRadiusIdx):
			return true

func pointInCercle(checkPoint: Vector2i, circlePos: Vector2i, circleRadiusIdx: float) -> bool:
	return checkPoint.distance_to(circlePos) <= circleRadiusIdx
