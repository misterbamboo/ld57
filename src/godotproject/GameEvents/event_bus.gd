extends Node

var _registered_callbacks := {}

func register(eventName: String, callback: Callable) -> void:
	if !_registered_callbacks.has(eventName):
		_registered_callbacks[eventName] = Array()
		
	var callbacks: Array = _registered_callbacks[eventName]
	if !callbacks.has(callback):
		print_rich("[color=orange]registed callback for "  + eventName + "![/color]")
		callbacks.append(callback)

func raise(event: GameEvent) -> void:
	print_rich("[color=cyan]raised event "  + event.get_name() + "![/color]")
	if !_registered_callbacks.has(event.get_name()):
		print_rich("[color=cyan]🛑but no callbacks are registered🛑[/color]")
		return
	
	var callbacks: Array = _registered_callbacks[event.get_name()]
	for callback: Callable in callbacks:
		if callback != null:
			callback.call(event)
