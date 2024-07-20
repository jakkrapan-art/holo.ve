extends Resource
class_name SkillActionAttack

@export var damageMultiplier: float = 1

func active(actor, target):
	var damage: int = 0
	if actor.has_method("getDamage"):
		damage = actor.getDamage()
	if target.has_method("recvDamage"):
		target.recvDamage(damage * damageMultiplier)
