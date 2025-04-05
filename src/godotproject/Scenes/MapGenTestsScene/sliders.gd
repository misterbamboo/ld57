extends Node

@onready var map: MapGenerator = $"../Map"

@export var yCam: VSlider

@export var sliderIndex: HSlider
@export var sliderWeight: HSlider
@export var sliderYGradient: HSlider
@export var labelIndex: Label
@export var labelWeight: Label
@export var labelYGradient: Label

@export var slider1: HSlider
@export var slider2: HSlider
@export var slider3: HSlider
@export var slider4: HSlider
@export var slider5: HSlider

@export var label1: Label
@export var label2: Label
@export var label3: Label
@export var label4: Label
@export var label5: Label

@export var noisePreview: Sprite2D
var previewSum: int

@export var mapGenerator: MapGenerator

func _ready() -> void:
	refreshSliders()

var checkSum: float = 0
var lastIndex = 0

func _process(time: float):
	if(map != null):
		map.position = Vector2(map.position.x, -yCam.value * map.cell_size)
	
	var indexVal = sliderIndex.value
	var index = int(indexVal)
	var weight = sliderWeight.value
	var yGradient = sliderYGradient.value
	checkSum = indexVal + weight + yGradient + slider1.value + slider2.value + slider3.value + slider4.value + slider5.value
	
	if(lastIndex != index):
		lastIndex = index
		refreshSliders()
		return
		
	mapGenerator.setNoise(index,weight,yGradient,slider1.value,slider2.value,slider3.value,slider4.value,slider5.value)
	labelIndex.text = "idx: " + str(index)
	labelWeight.text = "wght: " + str(weight)
	labelYGradient.text = "yGrad: " + str(yGradient)
	label1.text = "n1: " + str(slider1.value)
	label2.text = "n2: " + str(slider2.value)
	label3.text = "n3: " + str(slider3.value)
	label4.text = "n4: " + str(slider4.value)
	label5.text = "n5: " + str(slider5.value)
	
	if(checkSum != previewSum):
		updatePreview()
		previewSum = checkSum
		
func updatePreview():
	
	var size = 250
	var img := Image.create(size, size, false, Image.FORMAT_L8)
	for x in size:
		for y in size:
			var val = mapGenerator.getNoiseValueAt(x / 2.5, y / 2.5)
			var temp = clamp(val, 0, 1)
			img.set_pixel(x, y, Color(temp, temp, temp))
	var tex := ImageTexture.create_from_image(img)
	noisePreview.texture = tex
	
func refreshSliders():
	var indexVal = sliderIndex.value
	var index = int(indexVal)
	sliderWeight.value = mapGenerator.noise_weight[index]
	sliderYGradient.value = mapGenerator.noise_y_gradient[index]
	slider1.value = mapGenerator._noisesLayers[index].seed
	slider2.value = mapGenerator._noisesLayers[index].frequency
	slider3.value = mapGenerator._noisesLayers[index].fractal_octaves
	slider4.value = mapGenerator._noisesLayers[index].fractal_lacunarity
	slider5.value = mapGenerator._noisesLayers[index].fractal_gain
	checkSum = indexVal + sliderWeight.value + sliderYGradient.value + slider1.value + slider2.value + slider3.value + slider4.value + slider5.value
