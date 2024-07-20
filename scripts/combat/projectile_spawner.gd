extends Node2D
class_name ProjectileSpawner

@export var projectile: PackedScene

func _process(delta):
	pass

func attack(target: Node2D):
	if(projectile == null):
		printerr("cannot shoot, projectile is null")
		return;
	var projectileInstance = projectile.instantiate();
	get_tree().root.add_child(projectileInstance)
	projectileInstance.position = get_parent().position
	if(projectileInstance.has_method("setTarget")):
		projectileInstance.setTarget(target)
	if(projectileInstance.has_signal("onTargetHit")):
		projectileInstance.connect("onTargetHit", Callable(self, "activeOnHit"))

func activeOnHit(target):
	onTargetHit.emit(target)

signal onTargetHit(target)
