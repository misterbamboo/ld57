extends Control

@onready var torpedo_label:Label = $TorpedoAmountLabel
	
func _process(delta: float) -> void:
	torpedo_label.text = str(Submarine.instance.torpedo_amount_upgrade)
