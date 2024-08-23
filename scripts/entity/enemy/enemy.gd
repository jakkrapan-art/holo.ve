extends Entity
class_name Enemy

@export var pathFollow: PathFollow2D = null

func _process(_delta):
	if(pathFollow.progress_ratio == 1):
		onReachEndPoint.emit();
		queue_free()

func _physics_process(delta):
	pathFollow.progress_ratio += 0.1 * delta

signal onReachEndPoint();
