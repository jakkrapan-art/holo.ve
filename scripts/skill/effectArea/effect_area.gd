extends Area2D
class_name EffectArea

func _base_setup(callback: EffectAreaCallback = null):
	Utility.ConnectSignal(self, "area_entered", callback.onEnter)
	Utility.ConnectSignal(self, "area_exited", callback.onExit)

func _process(delta):
	queue_redraw()
