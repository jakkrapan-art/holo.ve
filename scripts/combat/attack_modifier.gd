class_name AttackModifier

var damage: int = 0

func _init(p_damage: int = 10):
	self.damage = p_damage

func active(target):
	if(target != null && target.has_method("recvDamage")):
		target.recvDamage(damage);
