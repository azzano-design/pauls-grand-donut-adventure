extends Label

@onready var score_label: Label = $"."
@onready var track_generator: TrackGenerator = $"../../Track"

func _ready():
	track_generator.collectible_collected.connect(_update_score)
	track_generator.obstacle_hit.connect(_update_score)

func _update_score(new_value):
	score_label.text = str(new_value)
