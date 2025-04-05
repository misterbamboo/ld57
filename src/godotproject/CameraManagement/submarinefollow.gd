extends Camera2D

@export var target: RigidBody2D
@export var subdetails: Submarine
@export var smoothing: float = 0.1 
@export var targetoffset: Vector2 = Vector2(0, 0) 

var current_page := -1
var rows_per_page := 10.0

func _process(delta: float) -> void:
	if target == null:
		return

	var target_position = target.position + targetoffset
	position = position.lerp(target_position, smoothing)

	_check_if_should_reload_map_viewport_page()

func _check_if_should_reload_map_viewport_page():
	var deepness = subdetails.get_deepness()
	var deepness_viewport_page = int(deepness / rows_per_page)
	
	if(current_page != deepness_viewport_page):
		load_page(deepness_viewport_page)
		current_page = deepness_viewport_page

func load_page(page: int):
	var row = page * rows_per_page
	var viewport_start = row - rows_per_page
	var viewport_end = row + rows_per_page * 2
	MapGenerator.instance.build(viewport_start, viewport_end)
