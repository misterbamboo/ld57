extends Node2D
class_name PoolableNode2D

# Reference to the pooler that created this instance
var pooler: NodePooler = null

## Called by the pooler when this node is about to be returned to the pool
## Override this in derived classes to reset state
func reset() -> void:
	pass

## Release this node back to its pooler
func release() -> void:
	if pooler:
		pooler.release_instance(self)
	else:
		push_warning("PoolableNode2D: Cannot release - no pooler reference")
		
## Called by the pooler when retrieving this node from the pool
func _on_retrieve_from_pool(pooler: NodePooler) -> void:
	pooler = pooler
