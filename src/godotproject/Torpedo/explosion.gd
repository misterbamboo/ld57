extends Node2D

var _exploded: bool = false

func _ready() -> void:
	$Node2D/AnimationLaunch.play("launch")
	
func _process(delta: float) -> void:
	if !_exploded:
		ExplosionMap.addExplosionAt(global_position, 100)
		_exploded = true
