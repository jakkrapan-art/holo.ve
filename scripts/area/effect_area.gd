extends Area2D
class_name EffectArea

var collisionShape = null

func _base_setup(shape: Shape2D,callback: EffectAreaCallback = null):
	Utility.ConnectSignal(self, "area_entered", callback.onEnter)
	Utility.ConnectSignal(self, "area_exited", callback.onExit)

	if(collisionShape == null):
		collisionShape = CollisionShape2D.new()
		collisionShape.shape = shape
		add_child(collisionShape)

func _process(_delta):
	queue_redraw()
