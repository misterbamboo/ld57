extends Node
class_name NoisePreviewContainer

@export var yOffset: VSlider
@export var noisePreview: Sprite2D

var scanLineY: int = 0

var previewSum: int

var size = 275
var img := Image.create(size, size, false, Image.FORMAT_RGBA8) # .FORMAT_L8 grayscale

func _on_noise_gen_configs_noise_gen_layers_changed() -> void:
	NoiseGenService.refreshAllNoises()

func _process(time: float):
	updatePreview()
		
func updatePreview():
	for x in size:
		for y in size:
			if y >= scanLineY and y < scanLineY + 10 :
				var color = NoiseGenService.get_noise_color(x, y + yOffset.value)
				img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	noisePreview.texture = tex
	scanLineY += 10
	if scanLineY >= size:
		scanLineY = 0
