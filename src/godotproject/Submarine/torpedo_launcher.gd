extends Node2D

@export var torpedoTemplace: PackedScene

var currentTorpedo: Torpedo = null

func _process(delta: float) -> void:
	if currentTorpedo == null:
		spawnTorpedo()

func spawnTorpedo():
	if torpedoTemplace != null:
			currentTorpedo = torpedoTemplace.instantiate() as Torpedo
			add_child(currentTorpedo)

func _input(event: InputEvent) -> void:

	if currentTorpedo == null:
		return

	# follow mouse to look toward the pointer
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var direction = (mouse_pos - global_position).normalized()
		currentTorpedo.look_at(mouse_pos)

	# launch torpedo on left click
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		currentTorpedo.reparent(get_tree().root)
		currentTorpedo.launch()
		currentTorpedo = null
