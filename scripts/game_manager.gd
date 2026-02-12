extends Node
class_name GameManager

var is_game_over: bool = false

@onready var game_over_ui: Control = $"../GameOverUI"
@onready var player: Player = $"../Player"

func _ready() -> void:
	add_to_group("game_manager")
	if game_over_ui:
		game_over_ui.visible = false

func game_over() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	print("GAME OVER!")
	
	# Stop player movement
	if player:
		player.set_physics_process(false)
	
	# Show game over screen
	if game_over_ui:
		game_over_ui.visible = true
	
	# Release mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func restart_game() -> void:
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if is_game_over and event.is_action_pressed("ui_accept"):
		restart_game()
