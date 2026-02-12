extends Camera3D
class_name FollowCamera

@export var target: Node3D
@export var player: Player
@export var offset: Vector3 = Vector3(0, 5, 5.5)
@export var look_ahead: float = 2.0
@export var smoothness: float = 5.0

# Boost camera effects
@export var boost_fov_increase: float = 10.0
@export var boost_zoom_speed: float = 8.0
@export var boost_shake_intensity: float = 0.15
@export var boost_shake_speed: float = 30.0

var base_fov: float = 75.0
var shake_offset: Vector3 = Vector3.ZERO

@onready var speed_lines: ColorRect = $SpeedLines

func _ready() -> void:
	if not target:
		push_warning("FollowCamera: No target assigned!")
	
	base_fov = fov
	
	if speed_lines:
		speed_lines.visible = false

func _physics_process(delta: float) -> void:
	if not target:
		return
	
	# Boost effects
	var is_boosting = player and player.is_boosting
	
	# FOV effect
	var target_fov = base_fov
	if is_boosting:
		target_fov = base_fov + boost_fov_increase
	fov = lerp(fov, target_fov, delta * boost_zoom_speed)
	
	# Camera shake during boost
	if is_boosting:
		var shake_amount = boost_shake_intensity
		shake_offset = Vector3(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount),
			0
		)
	else:
		shake_offset = shake_offset.lerp(Vector3.ZERO, delta * 10.0)
	
	# Speed lines visibility
	if speed_lines:
		if is_boosting:
			speed_lines.visible = true
			speed_lines.modulate.a = lerp(speed_lines.modulate.a, 1.0, delta * 5.0)
		else:
			speed_lines.modulate.a = lerp(speed_lines.modulate.a, 0.0, delta * 5.0)
			if speed_lines.modulate.a < 0.01:
				speed_lines.visible = false
	
	# Calculate target position with offset and shake
	var target_position = target.global_position + offset + shake_offset
	
	# Smooth follow
	global_position = global_position.lerp(target_position, delta * smoothness)
	
	# Look at point slightly ahead of the player
	var look_at_point = target.global_position + Vector3(0, 0, -look_ahead)
	look_at(look_at_point, Vector3.UP)
