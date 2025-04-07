class_name LoadMapPageEvent extends GameEvent

static var event_name := "LoadMapPageEvent"

var map_layer: int
var x_from: int
var x_to: int
var y_from: int
var y_to: int

func _init(map_layer:int, x_from: int, x_to: int, y_from: int, y_to: int):
	self.x_from = x_from
	self.x_to = x_to
	self.y_from = y_from
	self.y_to = y_to
	self.map_layer = map_layer

func get_name() -> String:
	return event_name
