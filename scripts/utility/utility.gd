class_name Utility

static func ConnectSignal(target: Node2D, signalName: String, callable: Callable):
	if(target.has_signal(signalName)):
		target.connect(signalName, callable)

static func DisconnectSignal(target: Node2D, signalName: String, callable: Callable):
	if(target.has_signal(signalName)):
		target.disconnect(signalName, callable)
