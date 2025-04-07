extends Node
class_name NoisePreviewContainer

@export var yOffset: VSlider
@export var noisePreview: Sprite2D

var scanLineY: int = 0

var previewSum: int
var noiseGenLayers: Array[NoiseGenLayer] = []

var noises: Array[FastNoiseLite] = []
var curves: Array[Curve] = []

var size = 275
var img := Image.create(size, size, false, Image.FORMAT_RGBA8) # .FORMAT_L8 grayscale

func _on_noise_gen_configs_noise_gen_layers_changed(newLayers: Array[NoiseGenLayer], curvesDef: Array[Curve]) -> void:
	noiseGenLayers = newLayers
	curves = curvesDef
	refreshAllNoises()
	
func refreshAllNoises():
	noises.clear()
	for noiseGenLayer in noiseGenLayers:
		noises.append(noiseGenLayer.toNoise())

func _process(time: float):
	updatePreview()
		
func updatePreview():
	for x in size:
		for y in size:
			if y >= scanLineY and y < scanLineY + 10 :
				var color = _get_noise_color(x, y + yOffset.value)
				img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	noisePreview.texture = tex
	scanLineY += 10
	if scanLineY >= size:
		scanLineY = 0

func _get_noise_color(x: float, y: float) -> Color:
	var best_color: Color = Color(0, 0, 0)
	var color_in_first_layer: bool = false
	for i in range(noises.size()):
		var value = noises[i].get_noise_2d(x, y)
		value = (value + 1.0) / 2.0
		if value <= 0:
			continue
		var layer := noiseGenLayers[i]
		var curve = _find_curve(layer.CurveName)
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

func _find_curve(curveName: String) -> Curve:
	for curve in curves:
		if curve.resource_name == curveName:
			return curve
	return null
