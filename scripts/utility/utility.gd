class_name Utility

static func ConnectSignal(target: Node2D, signalName: String, callable: Callable):
	if(target.has_signal(signalName)):
		target.connect(signalName, callable)
