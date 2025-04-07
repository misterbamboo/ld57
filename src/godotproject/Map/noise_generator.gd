class_name NoiseGenerator

func _init(layer_count: int = 5):
	NoiseGenService.loadAll()
	NoiseGenService.feedRandomSeeds()
	
func get_noise_value_at(x: float, y: float) -> float:
	if ExplosionMap.hasExploded(Vector2i(x, y)):
		return 0

	var value := NoiseGenService.get_noise_terrain_value(x, y)
	return value
	
