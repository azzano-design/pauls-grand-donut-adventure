extends Control
class_name BoostUI

@export var player: Player

@onready var boost_status_label: Label = $MarginContainer/VBoxContainer/BoostStatusLabel
@onready var cooldown_bar: ProgressBar = $MarginContainer/VBoxContainer/CooldownBar
@onready var boost_bar: ProgressBar = $MarginContainer/VBoxContainer/BoostBar

func _ready() -> void:
	if not player:
		push_warning("BoostUI: No player assigned!")

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Update boost status
	if player.is_boosting:
		boost_status_label.text = "BOOSTING!"
		boost_status_label.add_theme_color_override("font_color", Color.YELLOW)
		boost_bar.value = (player.boost_timer / player.boost_duration) * 100.0
		boost_bar.visible = true
		cooldown_bar.visible = false
	elif player.cooldown_timer > 0:
		boost_status_label.text = "Boost Ready In: " + str(int(player.cooldown_timer)) + "s"
		boost_status_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		cooldown_bar.value = ((player.boost_cooldown - player.cooldown_timer) / player.boost_cooldown) * 100.0
		cooldown_bar.visible = true
		boost_bar.visible = false
	else:
		boost_status_label.text = "Boost Ready! (Double-tap Space)"
		boost_status_label.add_theme_color_override("font_color", Color.GREEN)
		boost_bar.visible = false
		cooldown_bar.visible = false
