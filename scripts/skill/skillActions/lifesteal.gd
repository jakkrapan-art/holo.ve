extends Resource
class_name SkillActionLifeSteal

@export var damageMultiplier: float = 1
@export var healMultiplier: float = 0.5

func active(actor, target):
	var dmg: int = 0
	if actor:
		dmg = actor.getDamage()

	var doingDamage = dmg * damageMultiplier
	var damageDone = target.recvDamage(doingDamage)
	target.recvHeal(damageDone * healMultiplier)
