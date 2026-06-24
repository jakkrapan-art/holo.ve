class_name EffectAreaCallback
extends RefCounted

var onEnter: Callable = Callable()
var onExit: Callable = Callable()

func _init(p_onEnter: Callable = Callable(), p_onExit: Callable = Callable()):
	self.onEnter = p_onEnter
	self.onExit = p_onExit
