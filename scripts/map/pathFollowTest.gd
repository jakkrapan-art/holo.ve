extends PathFollow2D

func _process(delta):
	if(progress_ratio == 1):
		queue_free()

func _physics_process(delta):
	progress_ratio += 0.1 * delta
