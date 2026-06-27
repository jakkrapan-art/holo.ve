class_name ProjectileCallback
extends RefCounted

var onHit: Callable = Callable()
var onExpire: Callable = Callable()
var onMove: Callable = Callable()

func _init(p_onHit: Callable = Callable(), p_onExpire: Callable = Callable(), onMoving: Callable = Callable()):
	self.onHit = p_onHit
	self.onExpire = p_onExpire
	self.onMove = onMoving