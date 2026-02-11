extends Button
@onready var background_image: TextureRect = $"../../../BackgroundImage"

func _ready():
	pressed.connect(_on_button_pressed)
	
	# Make the button circular by setting equal dimensions
	custom_minimum_size = Vector2(100, 100)
	
	# Optional: Create a circular shape for click detection
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50
	
	
func _on_button_pressed():
	# Get the background TextureRect and trigger the transition
	var background = background_image  # Adjust path as needed
	if background and background.has_method("brighten"):
		background.brighten()
