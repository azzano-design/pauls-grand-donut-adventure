extends CharacterBody3D
class_name Player

# Player animation
@onready var player_animation: AnimationPlayer = $"VehicleMesh/Player/mixamo-player/AnimationPlayer"
@onready var voice_quips: Node = $VoiceQuips

# Movement settings
@export var forward_speed: float = 30.0
@export var lateral_speed: float = 8.0
@export var hop_force: float = 9.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.3

# Boost settings
@export var boost_speed_multiplier: float = 3.0
@export var boost_duration: float = 5.0
@export var boost_cooldown: float = 45.0
@export var double_tap_window: float = 0.5

# Track boundaries
@export var max_lateral_distance: float = 10.0

# Internal state
var is_grounded: bool = false
var lateral_position: float = 0.0

# Boost state
var is_boosting: bool = false
var boost_timer: float = 0.0
var cooldown_timer: float = 0.0
var last_space_press_time: float = 0.0
var pending_hop: bool = false
var hop_delay_timer: float = 0.0
const HOP_DELAY: float = 0.15  # Small delay to allow double-tap detection

@onready var mesh: MeshInstance3D = $VehicleMesh
@onready var ground_ray: RayCast3D = $GroundRay
@onready var boost_noise: AudioStreamPlayer = $BoostNoise

func _ready() -> void:
	player_animation.play("Armature|mixamo_com|Layer0")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")  # Add to group for obstacle detection
	print("=== Player initialized ===")
	print("Boost settings: multiplier=", boost_speed_multiplier, " duration=", boost_duration, "s cooldown=", boost_cooldown, "s")
	print("Double-tap window: ", double_tap_window, "s")
	print("Hop delay: ", HOP_DELAY, "s (allows time for double-tap)")
	print("=========================")

func _input(event: InputEvent) -> void:
	# Handle mouse movement for lateral control
	if event is InputEventMouseMotion:
		var mouse_delta = event.relative.x
		lateral_position += mouse_delta * mouse_sensitivity * get_physics_process_delta_time()
		lateral_position = clamp(lateral_position, -max_lateral_distance, max_lateral_distance)

func _physics_process(delta: float) -> void:
	# Check if grounded
	is_grounded = ground_ray.is_colliding()
	
	# Apply gravity
	if not is_grounded:
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0
	
	# Update boost timer
	if is_boosting:
		boost_timer -= delta
		if boost_timer <= 0:
			is_boosting = false
			cooldown_timer = boost_cooldown
			print("Boost ended! Cooldown started for ", boost_cooldown, "s")
	
	# Update cooldown timer
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			print("Boost ready! You can boost again!")
	
	# Handle pending hop with delay
	if pending_hop:
		hop_delay_timer -= delta
		if hop_delay_timer <= 0 and is_grounded:
			velocity.y = hop_force
			pending_hop = false
			print("Hop executed after delay")
	
	# Handle double-tap for boost
	var current_time = Time.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("ui_accept"):
		print("Space pressed! is_grounded: ", is_grounded)
		
		if is_grounded:
			# Check for double tap
			var time_since_last_press = current_time - last_space_press_time
			if time_since_last_press <= double_tap_window and last_space_press_time > 0:
				# Second press detected within window - activate boost!
				print("Double-tap detected! Time between presses: ", time_since_last_press, "s")
				attempt_boost()
				last_space_press_time = 0.0  # Reset to prevent triple-tap
				pending_hop = false  # Cancel any pending hop
				hop_delay_timer = 0.0
			else:
				# First press or too late - record time and schedule hop
				print("First tap registered at ", current_time, " - hop scheduled with delay")
				last_space_press_time = current_time
				pending_hop = true
				hop_delay_timer = HOP_DELAY
		else:
			print("Cannot hop/boost - not grounded!")
	
	# Calculate current speed with boost
	var current_forward_speed = forward_speed
	if is_boosting:
		current_forward_speed *= boost_speed_multiplier
		# Debug: Show we're applying boost speed
		if int(Time.get_ticks_msec()) % 500 == 0:  # Print every half second
			print("BOOSTING: Speed = ", current_forward_speed, " (base: ", forward_speed, " x ", boost_speed_multiplier, ")")
	
	# Forward movement
	velocity.z = -current_forward_speed
	
	# Lateral movement (mouse-based)
	var target_x = lateral_position
	var current_x = position.x
	var lateral_velocity = (target_x - current_x) * lateral_speed
	velocity.x = lateral_velocity
	
	# Apply movement
	move_and_slide()
	
	# Visual tilt based on lateral movement
	if mesh:
		var tilt_amount = -velocity.x * 0.05
		mesh.rotation.z = lerp(mesh.rotation.z, tilt_amount, delta * 5.0)
		
		# Slight hop animation
		if not is_grounded:
			mesh.rotation.x = lerp(mesh.rotation.x, -0.2, delta * 5.0)
		else:
			mesh.rotation.x = lerp(mesh.rotation.x, 0.0, delta * 5.0)
		
		# Boost visual effect - scale pulsing
		if is_boosting:
			var pulse = 1.0 + sin(Time.get_ticks_msec() / 100.0) * 0.1
			mesh.scale = Vector3.ONE * pulse
		else:
			mesh.scale = lerp(mesh.scale, Vector3.ONE, delta * 5.0)

func attempt_boost() -> void:
	print("--- attempt_boost called ---")
	print("  is_boosting: ", is_boosting)
	print("  cooldown_timer: ", cooldown_timer)
	print("  cooldown_timer <= 0: ", cooldown_timer <= 0)
	
	if cooldown_timer <= 0 and not is_boosting:
		is_boosting = true
		boost_timer = boost_duration
		boost_noise.play()
		print("✓ BOOST ACTIVATED! Duration: ", boost_duration, "s, Speed multiplier: ", boost_speed_multiplier, "x")
	elif cooldown_timer > 0:
		print("✗ Boost on cooldown! ", cooldown_timer, "s remaining (", int(cooldown_timer), "s rounded)")
	elif is_boosting:
		print("✗ Already boosting! ", boost_timer, "s remaining")
	print("---------------------------")

func _unhandled_input(event: InputEvent) -> void:
	# Release mouse on Escape
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().set_input_as_handled()


# Make Paul talk
func _on_timer_timeout() -> void:
	voice_quips.play_random_sound()
