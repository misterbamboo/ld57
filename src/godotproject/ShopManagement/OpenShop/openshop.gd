class_name OpenShop extends Control

@export var player: Node2D
@export var shopBoatMovement: ShopBoatMovement
@export var shopScreen: ShopScreen
@export var max_y_dist: float = 100.0

func _process(delta: float) -> void:
	if(player == null):
		return
		
	visible = false
		
	var diff = player.position - position
	var length = shopBoatMovement.boat_length
	var half = length/2
	var dist_x = abs(diff.x)
	var dist_y = abs(diff.y)
	if(dist_x < half and dist_y < max_y_dist):
		visible = true

func _input(event: InputEvent) -> void:
	if(!visible):
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			if shopScreen != null:
				shopScreen.displayScreen()
			
