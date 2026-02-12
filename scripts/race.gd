extends Node3D

const CREDITS = preload("res://scenes/credits.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(argument: String):
	if argument == "credits":
		print("End the game")
		get_tree().call_deferred("change_scene_to_packed", CREDITS)
