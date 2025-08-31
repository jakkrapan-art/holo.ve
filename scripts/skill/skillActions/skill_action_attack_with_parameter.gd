extends SkillAction
class_name SkillActionAttackWithParameter

@export var parameterName := "x"
@export var damageType := Damage.DamageType.PHYSIC

func execute(context: SkillContext):
	var tower: Tower = context.user as Tower
	var damageMultiplier: float = context.getParameter(parameterName, tower.data.level)

	for target in context.target:
		if is_instance_valid(target) && target.has_method("recvDamage"):
			var finalDamage = tower.data.getDamage(target);
			finalDamage.damage *= damageMultiplier;
			target.recvDamage(finalDamage);
