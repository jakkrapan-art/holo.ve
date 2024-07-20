class_name AttackModifier

var damage: int = 0

func _init(damage: int = 10):
	self.damage = damage

func active(target):
	if(target != null && target.has_method("recvDamage")):
		target.recvDamage(damage);
