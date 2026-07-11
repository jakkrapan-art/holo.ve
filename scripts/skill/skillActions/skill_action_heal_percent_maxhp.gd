extends SkillAction
class_name SkillActionHealPercentMaxHp

# Heals each target for stats.maxHp x percent (instant half of the heal pair;
# the interval half is the `hot` effect kind - see rest_recovery). Enemy-only
# hosts for now; mirrors SkillActionDamagePercentMaxHp's target normalize.

@export var percent: float = 0.0

func execute(context: SkillContext):
	if context.target == null:
		return
	for target in context.target:
		if not is_instance_valid(target):
			continue
		var enemy: Enemy = null
		if target is Enemy:
			enemy = target
		elif target is Area2D and target.get_parent() is Enemy:
			enemy = target.get_parent()
		if enemy == null or enemy.stats == null:
			continue
		var amount: int = int(enemy.stats.maxHp * percent)
		if amount > 0:
			enemy.heal(amount)
