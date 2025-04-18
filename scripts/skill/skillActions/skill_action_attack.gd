extends SkillAction
class_name SkillActionAttack

@export var damage := 10

func execute(context: SkillContext):
	if context.target && context.target.has_method("recvDamage"):
		context.target.recvDamage(damage)
