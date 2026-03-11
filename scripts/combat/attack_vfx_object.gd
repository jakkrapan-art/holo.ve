extends AnimatedSprite2D
class_name AttackVFXObject

func play_animation(direction: Global.DIRECTION):
	flip_h = direction == Global.DIRECTION.LEFT

	play()
	animation_finished.connect(_on_finished)

func _on_finished():
	queue_free()
