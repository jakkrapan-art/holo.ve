extends Area2D
class_name EffectArea

func _base_setup(shape: Shape2D,callback: EffectAreaCallback = null):
	Utility.ConnectSignal(self, "area_entered", callback.onEnter)
	Utility.ConnectSignal(self, "area_exited", callback.onExit)

	var children = get_children()
	if children.size() > 0:
		for child in children:
			if child is CollisionShape2D:
				child.shape = shape
			elif child is CollisionPolygon2D:
				child.polygon = shape.get_polygon()

func _process(delta):
	queue_redraw()
