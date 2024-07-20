extends Resource
class_name SkillActionHeal

@export var healMultiplier: float = 1

func active(actor, target):
	var heal: int = 0
	if actor:
		heal = actor.getDamage()

	target.recvHeal(heal * healMultiplier)
