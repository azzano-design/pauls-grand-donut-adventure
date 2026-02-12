extends TextureRect

@export var dim_color: Color = Color(0.15, 0.15, 0.15, 1.0)
@export var normal_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var transition_duration: float = 2.0

func _ready():
	modulate = dim_color

func brighten():
	var tween = create_tween()
	tween.tween_property(self, "modulate", normal_color, transition_duration)
	tween.set_ease(Tween.EASE_IN_OUT)
