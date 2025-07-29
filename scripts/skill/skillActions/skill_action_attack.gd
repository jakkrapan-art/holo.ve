extends SkillAction
class_name SkillActionAttack

@export var damage := 10

func execute(context: SkillContext):
	for target in context.target:
		if is_instance_valid(target) && target.has_method("recvDamage"):
			target.recvDamage(Damage.new(context.user, damage, Damage.DamageType.PHYSIC));

