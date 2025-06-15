extends SkillAction
class_name SkillActionAttack

@export var damage := 10

func execute(context: SkillContext):
	if is_instance_valid(context.target) && context.target.has_method("recvDamage"):
		context.target.recvDamage(damage)
