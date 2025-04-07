class_name NoiseGenerator

var _noiseLayers: Array[FastNoiseLite] = []
var noise_weight: Array[float] = []
var noise_y_gradient: Array[float] = []
var noise_seed: Array[float] = []
var noise_frequency: Array[float] = []
var noise_fractal_octaves: Array[float] = []
var noise_fractal_lacunarity: Array[float] = []
var noise_fractal_gain: Array[float] = []

func _init(layer_count: int = 5):
	for i in range(layer_count):
		_noiseLayers.append(FastNoiseLite.new())
		noise_weight.append(0.0)
		noise_y_gradient.append(0.0)
		noise_seed.append(0.0)
		noise_frequency.append(0.0)
		noise_fractal_octaves.append(0.0)
		noise_fractal_lacunarity.append(0.0)
		noise_fractal_gain.append(0.0)

func set_noise_params(layer_index: int, weight: float, y_gradient: float, 
					 seed_value: float, frequency: float, 
					 fractal_octaves: float, fractal_lacunarity: float, 
					 fractal_gain: float):
	# Set noise parameters for a specific layer
	noise_weight[layer_index] = weight
	noise_y_gradient[layer_index] = y_gradient
	noise_seed[layer_index] = seed_value
	noise_frequency[layer_index] = frequency
	noise_fractal_octaves[layer_index] = fractal_octaves
	noise_fractal_lacunarity[layer_index] = fractal_lacunarity
	noise_fractal_gain[layer_index] = fractal_gain
	
func get_noise_value_at(x: float, y: float) -> float:
	if ExplosionMap.hasExploded(Vector2i(x, y)):
		return 0
		
	# Get blended noise value for coordinates
	var blended_value: float = 0
	for i in range(_noiseLayers.size()):
		var val = _get_noise_value_at_layer(i, x, y)
		var weight = noise_weight[i]
		var weighted_value = val * weight
		if blended_value == 0:
			blended_value = weighted_value
		elif weighted_value > 0:
			blended_value *= weighted_value
	return blended_value
	
func _get_noise_value_at_layer(layer_index: int, x: float, y: float) -> float:
	# Implementation from original code
	var noise = _get_noise(layer_index)
	var raw_value = noise.get_noise_2d(x, y)
	var y_gradient = noise_y_gradient[layer_index]
	if y_gradient <= 0:
		return raw_value
	else:
		var percent = y / y_gradient
		return raw_value * percent
		
func _get_noise(layer_index: int) -> FastNoiseLite:
	# Configure and return noise layer
	_noiseLayers[layer_index].seed = noise_seed[layer_index]
	_noiseLayers[layer_index].noise_type = FastNoiseLite.TYPE_PERLIN
	_noiseLayers[layer_index].frequency = noise_frequency[layer_index]
	_noiseLayers[layer_index].fractal_octaves = noise_fractal_octaves[layer_index]
	_noiseLayers[layer_index].fractal_lacunarity = noise_fractal_lacunarity[layer_index]
	_noiseLayers[layer_index].fractal_gain = noise_fractal_gain[layer_index]
	return _noiseLayers[layer_index]
