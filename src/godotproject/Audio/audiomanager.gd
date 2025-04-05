class_name AudioManager extends Node

const MusicNames = preload("res://Audio/musicname.gd")
const SoundNames = preload("res://Audio/soundname.gd")
const Music = preload("res://Audio/music.gd")
const Sound = preload("res://Audio/sound.gd")

static var instance: AudioManager = null

@export var sounds: Array[Sound]
@export var musics: Array[Music]

var music_player: AudioStreamPlayer = null
var current_music: MusicNames.MusicName = MusicNames.MusicName.NONE

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	randomize()

	# Création du lecteur pour la musique
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# Préparation des sons
	for s in sounds:
		s.source = AudioStreamPlayer.new()
		s.source.stream = s.clip
		s.source.volume_db = linear_to_db(s.volume)
		s.source.pitch_scale = s.pitch
		s.source.bus = "SFX"
		s.source.loop = s.loop
		add_child(s.source)

	play_music(current_music)

func play_music(name: MusicNames.MusicName):
	if current_music == name:
		return

	if name == MusicNames.MusicName.NONE:
		music_player.stop()
		return

	for m in musics:
		if m.name == name:
			_set_music_settings(m)
			music_player.play()
			current_music = m.name
			break

func _set_music_settings(music: Music):
	music_player.stream = music.clip
	music_player.volume_db = linear_to_db(music.volume)
	music_player.pitch_scale = music.pitch

func play_sound(name: SoundNames.SoundName):
	for s in sounds:
		if s.name == name:
			s.source.play()
			break
