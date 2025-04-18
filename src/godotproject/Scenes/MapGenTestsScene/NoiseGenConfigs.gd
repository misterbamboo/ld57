extends Control
class_name NoiseGenConfigs

signal noiseGenLayersChanged()

@export var layerNameSelect: OptionButton
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

var current_layer: NoiseGenLayer = NoiseGenLayer.new()

func _ready() -> void:
	NoiseGenService.loadAll()
	_refresh_ItemList_layers()
	_loadLayerNamesDropDown()
	_loadCurvesDropDown()
	_bind_editors()

func _refresh_ItemList_layers():
	$HBoxContainer/VBoxContainer/ItemList.clear()
	for i in range(NoiseGenService.get_layer_count()):
		var layerName: String = NoiseGenService.get_layer_name(i)
		$HBoxContainer/VBoxContainer/ItemList.add_item(layerName)
		_fire_noiseGenLayersChanged()

func _loadLayerNamesDropDown():
	$VBoxContainer/GridContainer/OptionButton_LayerName_0.clear()
	for i in range(NoiseGenService.get_layer_count()):
		var layerName: String = NoiseGenService.get_layer_name(i)
		$VBoxContainer/GridContainer/OptionButton_LayerName_0.add_item(layerName, i)
		$VBoxContainer/GridContainer/OptionButton_LayerName_0.set_item_text(i, layerName)
	
func _loadCurvesDropDown():
	$VBoxContainer/GridContainer/OptionButton_Curve_0.clear()
	for i in range(NoiseGenService.get_curve_count()):
		var curvesName: String = NoiseGenService.get_curve_name(i)
		$VBoxContainer/GridContainer/OptionButton_Curve_0.add_item(curvesName, i)
		$VBoxContainer/GridContainer/OptionButton_Curve_0.set_item_text(i, curvesName)
		
func _bind_editors():
	layerNameSelect.item_selected.connect(func(idx: int):
		current_layer.Name = NoiseGenService.get_layer_name(idx)
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
		current_layer.CurveName = NoiseGenService.get_curve_name(idx)
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
	var name: String = NoiseGenService.get_layer_name(layerNameSelect.get_selected_id())
	var color := layerColorEdit.color
	var seed := layerSeedEdit.value
	var frequency := layerFrequencyEdit.value
	var fractalOctaves := layerFractalOctavesEdit.value
	var fractalLacunarity := layerFractalLacunarityEdit.value
	var fractalGain := layerFractalGainEdit.value
	var curveId := layerCurveSelect.get_selected_id()
	var curveName := NoiseGenService.get_curve_name(curveId)
	var breakPointActive := breakPointActiveCheck.button_pressed
	var breakPoint := breakPointSlider.value
	
	var layer = NoiseGenLayer.Create(name, color, seed, frequency, fractalOctaves, fractalLacunarity, fractalGain, curveName, breakPointActive, breakPoint)
	layer._save_to_disk()
	NoiseGenService.loadLayers()
	_refresh_ItemList_layers()

func _fire_noiseGenLayersChanged():
	emit_signal("noiseGenLayersChanged")

func _on_item_list_item_selected(index: int) -> void:
	var itemtext = $HBoxContainer/VBoxContainer/ItemList.get_item_text(index)
	var layer := NoiseGenService.get_layer_with_name(itemtext)
	_load_layer_in_grid(layer)
			
func _load_layer_in_grid(layer: NoiseGenLayer):
	current_layer = layer
	
	var foundId := 0
	for i in range(layerNameSelect.item_count):
		var itemName = layerNameSelect.get_item_text(i)
		if itemName == layer.Name:
			foundId = i
			break		
	layerNameSelect.select(foundId)
	layerColorEdit.color = layer.LayerColor
	layerSeedEdit.value = layer.Seed
	layerFrequencyEdit.value = layer.Frequency
	layerFractalOctavesEdit.value = layer.FractalOctaves
	layerFractalLacunarityEdit.value = layer.FractalLacunarity
	layerFractalGainEdit.value = layer.FractalGain
	var curveIndex := NoiseGenService.get_curve_index_from_layer(layer)
	layerCurveSelect.select(curveIndex)
	breakPointActiveCheck.button_pressed = layer.BreakPointActive
	breakPointSlider.value = layer.BreakPoint
