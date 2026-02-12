extends Node

var sounds = []
@onready var voice_player: AudioStreamPlayer = $"../VoicePlayer"

func _ready():
	# Load sounds dynamically
	sounds.append(load("res://assets/voice/ElevenLabs_Carefull.mp3"))
	sounds.append(load("res://assets/voice/ElevenLabs_WatchOut.mp3"))
	sounds.append(load("res://assets/voice/ElevenLabs_Woaa.mp3"))
	sounds.append(load("res://assets/voice/ElevenLabs_Yahoo.mp3"))

func play_random_sound():
	if sounds.is_empty():
		return
		
	# Use Godot's built-in randomization
	sounds.shuffle()
	voice_player.stream = sounds[0]
	voice_player.play()
