extends Node3D

@onready var animation_player: AnimationPlayer = $"mixamo-player/AnimationPlayer"

func _ready() -> void:
	animation_player.play("Armature|mixamo_com|Layer0")
