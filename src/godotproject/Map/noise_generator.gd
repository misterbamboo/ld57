class_name NoiseGenerator

var generator: NoiseGen

func _init(layer_count: int = 5):
	generator = NoiseGen.new()
	generator.loadAll()
	generator.feedRandomSeeds()
	
func get_noise_value_at(x: float, y: float) -> float:
	if ExplosionMap.hasExploded(Vector2i(x, y)):
		return 0

	var value := generator.get_noise_terrain_value(x, y)
	return value

func get_noise_color_at(x: float, y: float) -> Color:
	if OreMap.hasBeenCollected(Vector2i(x, y)):
		return Color.BLACK
	var color := generator.get_noise_color(x, y)
	return color
