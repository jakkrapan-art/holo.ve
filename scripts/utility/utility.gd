class_name Utility

static func ConnectSignal(target, signalName: String, callable: Callable):
	if(target.has_signal(signalName)):
		target.connect(signalName, callable)
		return true;
	
	return false;

static func DisconnectSignal(target, signalName: String, callable: Callable):
	if(target.has_signal(signalName)):
		target.disconnect(signalName, callable)
