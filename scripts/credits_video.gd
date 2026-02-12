extends VideoStreamPlayer


func _ready():
	finished.connect(_on_video_finished)
	play()

func _on_video_finished():
	queue_free()
