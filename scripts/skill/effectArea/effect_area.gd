extends Area2D
class_name EffectArea

func _base_setup(shape: Shape2D, callback: EffectAreaCallback = null):
	Utility.ConnectSignal(self, "area_entered", callback.onEnter)
	Utility.ConnectSignal(self, "area_exited", callback.onExit)

	var shape_node: CollisionShape2D = $CollisionShape2D
	if shape_node:
		shape_node.shape = shape

func _process(delta):
	queue_redraw()
