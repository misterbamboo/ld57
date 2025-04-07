extends Node
class_name NoiseGen
# SEE: Global NoiseGenService

#########
# Layers
#########
var _noiseGenLayers: Array[NoiseGenLayer] = []
var _layerNames := {}
func get_layer_count() -> int:
	return _noiseGenLayers.size()
func get_layer_name(index: int) -> String:
	return _layerNames[index]
func get_layer_with_name(name: String) -> NoiseGenLayer:
	for layer in _noiseGenLayers:
		if layer.Name == name:
			return layer
	return null
	
#########
# Curves
#########
var _curves: Array[Curve] = []
var _curvesNames := {}
var _layerIndex_to_curve_index := {}
func get_curve_count() -> int:
	return _curves.size()
func get_curve_name(index: int) -> String:
	return _curvesNames[index]
func get_curve_index_from_layer(layer: NoiseGenLayer) -> int:
	for curve in _curves:
		if curve.resource_name == layer.CurveName:
			for curveId in _curvesNames.keys():
				var curveName = _curvesNames[curveId]
				if curveName == layer.CurveName:
					return curveId
	return 0

#########
# Noises
#########
var _noises: Array[FastNoiseLite] = []

func loadAll():
	loadLayers()
	loadCurves()
	refreshAllNoises()
	
func feedRandomSeeds():
	randomize()
	refreshAllNoises()
	for noise in _noises:
		noise.seed = int(randf() * 100000)
	
func loadLayers():
	var path := "res://Map/NoiseGen/Layers/"
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		_noiseGenLayers = []
		var layerI := 0
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = path + file_name
				var layer = load(full_path)
				if layer is NoiseGenLayer:
					_layerNames[layerI] = layer.Name
					_noiseGenLayers.append(layer)
					layerI += 1
			file_name = dir.get_next()
			
func loadCurves():
	var path := "res://Map/NoiseGen/Curves/"
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		_curves = []
		var curveI := 0
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = path + file_name
				var curve = load(full_path)
				if curve is Curve:
					_curves.append(curve)
					_curvesNames[curveI] = curve.resource_name
					curveI += 1
			file_name = dir.get_next()
			
func refreshAllNoises():
	_noises.clear()
	for noiseGenLayer in _noiseGenLayers:
		_noises.append(noiseGenLayer.toNoise())

func get_noise_terrain_value(x: float, y: float) -> float:
	var noise := _noises[0] ## first layer is always terrain
	var value = noise.get_noise_2d(x, y)
	value = (value + 1.0) / 2.0 # between -1 and 1 (clamp it in 0-1 range)
	var layer := _noiseGenLayers[0]
	var curve := _get_curve_from_layer_index(0)
	var curveVal = curve.sample(y)
	value = curveVal * value
	value = clamp(value, 0.0, 1.0)
	if layer.BreakPointActive:
		value = 0 if value < layer.BreakPoint else 1
	return value

func get_noise_color(x: float, y: float) -> Color:
	var best_color: Color = Color(0, 0, 0)
	var color_in_first_layer: bool = false
	for i in range(_noises.size()):
		var value = _noises[i].get_noise_2d(x, y)
		value = (value + 1.0) / 2.0
		if value <= 0:
			continue
		var layer := _noiseGenLayers[i]
		var curve := _get_curve_from_layer_index(i)
		var curveVal = curve.sample(y)
		value = curveVal * value
		value = clamp(value, 0.0, 1.0)
		if layer.BreakPointActive:
			value = 0 if value < layer.BreakPoint else 1
		if value > 0:
			if i == 0:
				color_in_first_layer = true
			if color_in_first_layer:
				best_color = Color(0, 0, 0).lerp(layer.LayerColor, value)
	return best_color

func _get_curve_from_layer_index(layerIndex: int) -> Curve:
	if _layerIndex_to_curve_index.keys().size() <= 0:
		_rebuild_layer_to_curve_index()
	var curveIndex = _layerIndex_to_curve_index[layerIndex]
	return _curves[curveIndex]

func _rebuild_layer_to_curve_index():
	_layerIndex_to_curve_index = {}
	for l in range(get_layer_count()):
		var layer := _noiseGenLayers[l]
		for c in range(_curves.size()):
			var curve := _curves[c]
			if curve.resource_name == layer.CurveName:
				_layerIndex_to_curve_index[l] = c
				break
