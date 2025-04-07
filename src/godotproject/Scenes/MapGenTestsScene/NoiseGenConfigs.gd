extends Control
class_name NoiseGenConfigs

signal noiseGenLayersChanged(noiseGenLayers: Array[NoiseGenLayer], curves: Array[Curve])

@export var layerNameEdit: TextEdit
@export var layerColorEdit: ColorPickerButton
@export var layerSeedEdit: SpinBox
@export var layerFrequencyEdit: SpinBox
@export var layerFractalOctavesEdit: SpinBox
@export var layerFractalLacunarityEdit: SpinBox
@export var layerFractalGainEdit: SpinBox
@export var layerCurveSelect: OptionButton
@export var curves: Array[Curve]
@export var breakPointActiveCheck: CheckButton
@export var breakPointSlider: HSlider

var curvesNames := {}

var noiseGenLayers: Array[NoiseGenLayer] = []
var current_layer: NoiseGenLayer = NoiseGenLayer.new()

func _ready() -> void:
	_loadLayers()
	_loadCurvesDropDown()
	_refresh_ItemList_layers()
	_bind_editors()
	
func _loadLayers():
	var path := "res://Map/NoiseGen/Layers/"
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = path + file_name
				var res = load(full_path)
				if res is NoiseGenLayer:
					noiseGenLayers.append(res)
			file_name = dir.get_next()
	
func _loadCurvesDropDown():
	var i := 0
	for curve in curves:
		$VBoxContainer/GridContainer/OptionButton_Curve_0.add_item(curve.resource_name, i)
		$VBoxContainer/GridContainer/OptionButton_Curve_0.set_item_text(i, curve.resource_name)
		curvesNames[i] = curve.resource_name
		i += 1
		
func _bind_editors():
	layerNameEdit.text_changed.connect(func():
		current_layer.Name = layerNameEdit.text
		_fire_noiseGenLayersChanged()
	)
	layerColorEdit.color_changed.connect(func(c: Color):
		current_layer.LayerColor = c
		_fire_noiseGenLayersChanged()
	) 
	layerSeedEdit.value_changed.connect(func(f: float):
		current_layer.Seed = f
		_fire_noiseGenLayersChanged()
	)
	layerFrequencyEdit.value_changed.connect(func(f: float):
		current_layer.Frequency = f
		_fire_noiseGenLayersChanged()
	)
	layerFractalOctavesEdit.value_changed.connect(func(f: float):
		current_layer.FractalOctaves = f
		_fire_noiseGenLayersChanged()
	)
	layerFractalLacunarityEdit.value_changed.connect(func(f: float):
		current_layer.FractalLacunarity = f
		_fire_noiseGenLayersChanged()
	)
	layerFractalGainEdit.value_changed.connect(func(f: float):
		current_layer.FractalGain = f
		_fire_noiseGenLayersChanged()
	)
	layerCurveSelect.item_selected.connect(func(idx: int):
		current_layer.CurveName = curvesNames[idx]
		_fire_noiseGenLayersChanged()
	)
	breakPointActiveCheck.pressed.connect(func():
		current_layer.BreakPointActive = breakPointActiveCheck.button_pressed
		_fire_noiseGenLayersChanged()
	)
	breakPointSlider.value_changed.connect(func(f: float):
		current_layer.BreakPoint = f
		_fire_noiseGenLayersChanged()
	)

func _on_button_pressed() -> void:
	var name := layerNameEdit.text
	var color := layerColorEdit.color
	var seed := layerSeedEdit.value
	var frequency := layerFrequencyEdit.value
	var fractalOctaves := layerFractalOctavesEdit.value
	var fractalLacunarity := layerFractalLacunarityEdit.value
	var fractalGain := layerFractalGainEdit.value
	var curveId := layerCurveSelect.get_selected_id()
	var curveName := curvesNames[curveId] as String
	var breakPointActive := breakPointActiveCheck.button_pressed
	var breakPoint := breakPointSlider.value
	
	var layer = NoiseGenLayer.Create(name, color, seed, frequency, fractalOctaves, fractalLacunarity, fractalGain, curveName, breakPointActive, breakPoint)
	noiseGenLayers.append(layer)
	layer._save_to_disk()
	_refresh_ItemList_layers()
	
func _refresh_ItemList_layers():
	$HBoxContainer/VBoxContainer/ItemList.clear()
	for layer in noiseGenLayers:
		$HBoxContainer/VBoxContainer/ItemList.add_item(layer.Name)
		_fire_noiseGenLayersChanged()

func _fire_noiseGenLayersChanged():
	emit_signal("noiseGenLayersChanged", noiseGenLayers, curves)

func _on_item_list_item_selected(index: int) -> void:
	var itemtext = $HBoxContainer/VBoxContainer/ItemList.get_item_text(index)
	for layer in noiseGenLayers:
		if layer.Name == itemtext:
			_load_layer_in_grid(layer)
			
func _load_layer_in_grid(layer: NoiseGenLayer):
	current_layer = layer
	layerNameEdit.text = layer.Name
	layerColorEdit.color = layer.LayerColor
	layerSeedEdit.value = layer.Seed
	layerFrequencyEdit.value = layer.Frequency
	layerFractalOctavesEdit.value = layer.FractalOctaves
	layerFractalLacunarityEdit.value = layer.FractalLacunarity
	layerFractalGainEdit.value = layer.FractalGain
	for curve in curves:
		if curve.resource_name == layer.CurveName:
			for curveId in curvesNames.keys():
				var curveName = curvesNames[curveId]
				if curveName == layer.CurveName:
					layerCurveSelect.select(curveId)
	breakPointActiveCheck.button_pressed = layer.BreakPointActive
	breakPointSlider.value = layer.BreakPoint
