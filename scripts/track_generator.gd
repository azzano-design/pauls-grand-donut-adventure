extends Node3D
class_name TrackGenerator

@export var track_length: float = 500.0
@export var track_width: float = 20.0
@export var segment_length: float = 20.0
@export var collectible_scene: PackedScene = preload("res://scenes/donut-positive.tscn") # First item - max 12
@export var obstacle_scene: PackedScene = preload("res://scenes/donut-negative.tscn")   # Second item - unlimited
@export var max_collectibles: int = 10
@export var min_obstacle_spacing: float = 30.0  # Minimum distance between obstacles
@export var extra_track_length: float = 00.0  # Track after finish line
@export var fade_duration: float = 2.0  # Duration of fade to black

const CREDITS = preload("res://scenes/credits.tscn")

signal race_finished
signal collectible_collected
signal obstacle_hit

var finish_line_position: float = 0.0
var counter: int = 0
var game_ended: bool = false

func _ready() -> void:
	generate_track()

func generate_track() -> void:
	var segments = int(track_length / segment_length)
	var extra_segments = int(extra_track_length / segment_length)
	var total_segments = segments + extra_segments
	
	for i in range(total_segments):
		var segment = create_track_segment(i)
		add_child(segment)
	
	# Spawn items after track is generated (only on main track, not extra)
	spawn_collectibles()
	spawn_obstacles()
	
	# Create finish line at the end of the main track (before extra segments)
	create_finish_line(segments - 1)

func create_track_segment(index: int) -> Node3D:
	var segment = Node3D.new()
	segment.position = Vector3(0, 0, -index * segment_length)
	
	# Create the floor mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(track_width, 0.5, segment_length)
	mesh_instance.mesh = box_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	if index % 2 == 0:
		material.albedo_color = Color(0.3, 0.3, 0.35)
	else:
		material.albedo_color = Color(0.25, 0.25, 0.3)
	mesh_instance.material_override = material
	
	segment.add_child(mesh_instance)
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(track_width, 0.5, segment_length)
	collision_shape.shape = shape
	
	static_body.add_child(collision_shape)
	segment.add_child(static_body)
	
	# Add side barriers
	create_barrier(segment, -track_width / 2 - 1, index)
	create_barrier(segment, track_width / 2 + 1, index)
	
	return segment

func create_barrier(parent: Node3D, x_position: float, _index: int) -> void:
	var barrier = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 3, segment_length)
	barrier.mesh = box_mesh
	barrier.position = Vector3(x_position, 1.5, 0)
	
	# Create barrier material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.3, 0.3)
	barrier.material_override = material
	
	parent.add_child(barrier)
	
	# Add collision to barrier
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 3, segment_length)
	collision_shape.shape = shape
	collision_shape.position = Vector3(x_position, 1.5, 0)
	
	static_body.add_child(collision_shape)
	parent.add_child(static_body)

func spawn_collectibles() -> void:
	if collectible_scene == null:
		print("Warning: No collectible scene assigned")
		return
	
	# Generate random positions along the track (avoiding start and finish areas)
	var safe_start = segment_length * 3  # Skip first few segments
	var safe_end = track_length - (segment_length * 3)  # Skip last few segments
	var available_length = safe_end - safe_start
	
	var positions = []
	for i in range(max_collectibles):
		var z_pos = -safe_start - randf() * available_length
		positions.append(z_pos)
	
	# Spawn collectibles at random positions
	for z_pos in positions:
		var collectible = collectible_scene.instantiate()
		
		# Random x position within track bounds (with some margin from edges)
		var x_pos = randf_range(-track_width / 2 + 3, track_width / 2 - 3)
		
		collectible.position = Vector3(x_pos, 2, z_pos)
		collectible.add_to_group("collectibles")
		
		# Connect signal if the collectible has an Area3D
		if collectible.has_signal("body_entered"):
			collectible.body_entered.connect(_on_collectible_body_entered.bind(collectible))
		elif collectible.has_node("Area3D"):
			var area = collectible.get_node("Area3D")
			area.body_entered.connect(_on_collectible_body_entered.bind(collectible))
		
		add_child(collectible)

func spawn_obstacles() -> void:
	if obstacle_scene == null:
		print("Warning: No obstacle scene assigned")
		return
	
	# Generate random positions with spacing constraints
	var safe_start = segment_length * 3
	var safe_end = track_length - (segment_length * 3)
	
	var obstacle_positions = []
	var current_z = -safe_start
	
	while current_z > -safe_end:
		# Random spacing between obstacles
		var spacing = randf_range(min_obstacle_spacing, min_obstacle_spacing * 2)
		current_z -= spacing
		
		if current_z > -safe_end:
			obstacle_positions.append(current_z)
	
	# Spawn obstacles
	for z_pos in obstacle_positions:
		var obstacle = obstacle_scene.instantiate()
		
		# Random x position within track bounds
		var x_pos = randf_range(-track_width / 2 + 3, track_width / 2 - 3)
		
		obstacle.position = Vector3(x_pos, 2, z_pos)
		obstacle.add_to_group("obstacles")
		
		# Connect signal if the obstacle has an Area3D
		if obstacle.has_signal("body_entered"):
			obstacle.body_entered.connect(_on_obstacle_body_entered.bind(obstacle))
		elif obstacle.has_node("Area3D"):
			var area = obstacle.get_node("Area3D")
			area.body_entered.connect(_on_obstacle_body_entered.bind(obstacle))
		
		add_child(obstacle)

func _on_collectible_body_entered(body: Node3D, collectible: Node3D) -> void:
	# Check if it's the player
	if body.is_in_group("player") or body.name.contains("Player") or body.name.contains("Car"):
		counter += 1
		print("Collectible picked up! Counter: ", counter)
		emit_signal("collectible_collected", counter)
		collectible.queue_free()

func _on_obstacle_body_entered(body: Node3D, obstacle: Node3D) -> void:
	# Check if it's the player
	if body.is_in_group("player") or body.name.contains("Player") or body.name.contains("Car"):
		if counter > 0:
			counter -= 1
		print("Obstacle hit! Counter: ", counter)
		emit_signal("obstacle_hit", counter)

func create_finish_line(last_segment_index: int) -> void:
	var finish_line = Node3D.new()
	finish_line.name = "FinishLine"
	finish_line.position = Vector3(0, 0, -last_segment_index * segment_length)
	finish_line_position = finish_line.position.z
	
	# Create the checkered pattern posts
	create_finish_post(finish_line, -track_width / 2 - 0.5)
	create_finish_post(finish_line, track_width / 2 + 0.5)
	
	# Create the overhead banner
	var banner = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(track_width + 2, 0.5, 2)
	banner.mesh = box_mesh
	banner.position = Vector3(0, 5, 0)
	
	var banner_material = StandardMaterial3D.new()
	banner_material.albedo_color = Color(1, 1, 1)
	banner.material_override = banner_material
	
	finish_line.add_child(banner)
	
	# Create detection area
	var area = Area3D.new()
	area.name = "FinishLineArea"
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(track_width, 10, 3)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0, 5, 0)
	
	area.add_child(collision_shape)
	finish_line.add_child(area)
	
	# Connect the signal
	area.body_entered.connect(_on_finish_line_crossed)
	
	add_child(finish_line)

func create_finish_post(parent: Node3D, x_position: float) -> void:
	var post = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 10, 1)
	post.mesh = box_mesh
	post.position = Vector3(x_position, 5, 0)
	
	# Create checkered material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 0, 0)
	post.material_override = material
	
	parent.add_child(post)

func _on_finish_line_crossed(body: Node3D) -> void:
	# Check if it's the player and game hasn't ended yet
	if not game_ended and (body.is_in_group("player") or body.name.contains("Player") or body.name.contains("Car")):
		game_ended = true
		print("Race finished!")
		emit_signal("race_finished")
		end_game()

func end_game() -> void:
	print("Game Over - You finished the race!")
	print("Final score: ", counter)
	
	# Create fade overlay
	create_fade_overlay()

func create_fade_overlay() -> void:
	# Create a ColorRect for the fade effect
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color(0, 0, 0, 0)  # Start transparent
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Make it cover the entire screen
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.size = get_viewport().get_visible_rect().size
	
	# Add to the root of the scene tree so it's above everything
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to ensure it's on top
	canvas_layer.name = "FadeCanvasLayer"
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(fade_overlay)
	
	# Create and start the fade animation
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), fade_duration)

	tween.tween_callback(cleanup_scene)
	fade_overlay.queue_free();

func cleanup_scene() -> void:
	print("Cleaning up scene...")
	
	# Get the root node of the current scene
	var root = get_tree().current_scene
	
	if root:
		# Queue free the entire scene
		root.queue_free()
		
		# Optional: Load a new scene after cleanup
		get_tree().call_deferred("change_scene_to_packed", CREDITS)
	else:
		# If no current scene, just clear all children
		for child in get_tree().root.get_children():
			child.queue_free()
