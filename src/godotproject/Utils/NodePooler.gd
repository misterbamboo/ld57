extends Node
class_name NodePooler

# Import PoolableNode2D class
const PoolableNode2DScript = preload("res://Utils/PoolableNode2D.gd")

# Configuration
@export_category("Pool Configuration")
@export var auto_expand := true
@export var expansion_amount := 10
@export var scene: PackedScene
@export var preload_amount := 10

# Internal storage
var _available_instances := []
var _active_instances := []

# Signals
signal pool_expanded(new_amount)
signal instance_retrieved(instance)
signal instance_released(instance)

func _ready() -> void:
	_initialize_pool()

## Initialize the pool with the preloaded amount
func _initialize_pool() -> void:
	if scene:
		_expand_pool(preload_amount)

## Expand the pool by creating new instances
func _expand_pool(amount: int) -> void:
	if not scene:
		push_error("NodePooler: No scene assigned to the pool")
		return
		
	for i in range(amount):
		var instance = scene.instantiate()
		add_child(instance)
		instance.visible = false
		instance.pooler = self
		instance.reset()
			
		_available_instances.append(instance)
	
	pool_expanded.emit(_available_instances.size())

## Get a node instance from the pool
func get_instance():
	# Get instance from pool or expand if needed
	var instance = null
	
	if _available_instances.size() > 0:
		instance = _available_instances.pop_back()
	elif auto_expand:
		_expand_pool(expansion_amount)
		if _available_instances.size() > 0:
			instance = _available_instances.pop_back()
	
	if instance:
		instance.visible = true
		_active_instances.append(instance)
		
		# Call retrieve method on PoolableNode2D
		if instance is PoolableNode2DScript:
			instance._on_retrieve_from_pool(self)
			
		instance_retrieved.emit(instance)
		return instance
	
	push_error("NodePooler: Failed to get instance")
	return null

## Release a node back to the pool
func release_instance(instance: Node) -> void:
	if not instance in _active_instances:
		push_warning("NodePooler: Attempted to release an instance not managed by this pool")
		return
	
	# Hide and reset the instance
	instance.visible = false
	if instance.has_method("reset"):
		instance.reset()
	
	# Move from active to available pool
	_active_instances.erase(instance)
	_available_instances.append(instance)
	
	instance_released.emit(instance)

## Get count of available instances
func get_available_count() -> int:
	return _available_instances.size()

## Get count of active instances
func get_active_count() -> int:
	return _active_instances.size()

## Get total instances (available + active)
func get_total_count() -> int:
	return get_available_count() + get_active_count()

## Clear the pool and remove all instances
func clear_pool() -> void:
	for instance in _available_instances:
		instance.queue_free()
	
	for instance in _active_instances:
		instance.queue_free()
	
	_available_instances.clear()
	_active_instances.clear()
