extends Camera2D

@export var target: RigidBody2D
@export var smoothing: float = 0.1 
@export var targetoffset: Vector2 = Vector2(0, 0) 

var current_page := -1
var rows_per_page := 20.0

var current_background_page := 1
var background_rows_per_page := 10.0

func _process(_delta: float) -> void:
	if target == null:
		return

	var target_position = target.position + targetoffset
	position = position.lerp(target_position, smoothing)

	_check_if_should_reload_map_viewport_page()
	_chech_if_should_reload_map_background()

func _check_if_should_reload_map_viewport_page():
	var deepness = 0 if Submarine.instance == null else Submarine.instance.get_deepness()
	var deepness_viewport_page = int(deepness / rows_per_page)
	
	if(current_page != deepness_viewport_page):
		load_page(deepness_viewport_page, MapLayers.LEVEL, rows_per_page)
		current_page = deepness_viewport_page
		
func _chech_if_should_reload_map_background():
	var deepness = 0 if Submarine.instance == null else Submarine.instance.get_special_deepness(128)
	var deepness_viewport_page = int(deepness / background_rows_per_page)
	if(current_background_page != deepness_viewport_page):
		load_page(deepness_viewport_page, MapLayers.BACKGROUND, background_rows_per_page)
		current_background_page = deepness_viewport_page

func load_page(page: int, map_layer: int, rows_per_page: float):
	var row = page * rows_per_page
	var viewport_start = row - rows_per_page
	var viewport_end = row + rows_per_page * 2
	EventBus.raise(LoadMapPageEvent.new(map_layer, 0, 0, viewport_start, viewport_end))
