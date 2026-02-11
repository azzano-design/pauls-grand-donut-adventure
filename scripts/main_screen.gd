extends Control

@onready var background: TextureRect = $BackgroundImage
@onready var ui_container: VBoxContainer = $CenterContainer/VBoxContainer
@onready var button: Button = $CenterContainer/VBoxContainer/Button

@export var transition_duration: float = 2.0

func _ready():
	button.pressed.connect(_on_button_pressed)
	
	# Make the Control node fill the entire viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Initial setup
	_setup_background()

func _setup_background():
	if background:
		# Make background fill the entire screen
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_SCALE

func _on_viewport_size_changed():
	# This will be called whenever the browser window is resized
	_setup_background()


func _on_button_pressed():
	button.disabled = true
	
	# Brighten background
	if background and background.has_method("brighten"):
		background.brighten()
	
	# Fade out entire UI container (logo and button together)
	var tween = create_tween()
	tween.tween_property(ui_container, "modulate:a", 0.0, transition_duration)
