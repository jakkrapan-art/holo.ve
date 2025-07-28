class_name ProjectileCallback
extends RefCounted

var onHit: Callable = Callable()
var onExpire: Callable = Callable()
var onMove: Callable = Callable()

func _init(onHit: Callable = Callable(), onExpire: Callable = Callable(), onMoving: Callable = Callable()):
	self.onHit = onHit
	self.onExpire = onExpire
	self.onMove = onMoving