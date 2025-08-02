class_name EffectAreaCallback
extends RefCounted

var onEnter: Callable = Callable()
var onExit: Callable = Callable()

func _init(onEnter: Callable = Callable(), onExit: Callable = Callable()):
	self.onEnter = onEnter
	self.onExit = onExit
