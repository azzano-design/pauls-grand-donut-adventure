extends Node3D
class_name ParticleEffects

@export var player: Player

# Particle nodes
@onready var drift_smoke_left: GPUParticles3D = $DriftSmokeLeft
@onready var drift_smoke_right: GPUParticles3D = $DriftSmokeRight
@onready var boost_trail: GPUParticles3D = $Boost

# Drift smoke settings
var drift_threshold: float = 5.0  # Velocity threshold to trigger smoke

func _ready() -> void:
	if drift_smoke_left:
		drift_smoke_left.emitting = false
	if drift_smoke_right:
		drift_smoke_right.emitting = false
	if boost_trail:
		boost_trail.emitting = false

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Handle drift smoke based on lateral velocity
	var lateral_velocity = abs(player.velocity.x)
	
	if lateral_velocity > drift_threshold:
		if player.velocity.x > 0:  # Moving right, smoke on left
			if drift_smoke_left:
				drift_smoke_left.emitting = true
			if drift_smoke_right:
				drift_smoke_right.emitting = false
		else:  # Moving left, smoke on right
			if drift_smoke_left:
				drift_smoke_left.emitting = false
			if drift_smoke_right:
				drift_smoke_right.emitting = true
	else:
		if drift_smoke_left:
			drift_smoke_left.emitting = false
		if drift_smoke_right:
			drift_smoke_right.emitting = false
	
	# Handle boost trail
	if boost_trail:
		boost_trail.emitting = player.is_boosting
