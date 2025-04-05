class_name Sound extends Resource

@export var name: int                 # Enum SoundName (ex: SoundName.UPGRADE1)
@export var clip: AudioStream
@export_range(0.0, 1.0) var volume: float = 1.0
@export_range(0.1, 3.0) var pitch: float = 1.0
@export var loop: bool = false

var source: AudioStreamPlayer = null  # Assigné dynamiquement par AudioManager
