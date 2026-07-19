extends SkillAction
class_name SkillActionDamagePercentMaxHp

# Applies TRUE damage = enemy.stats.maxHp × { boss_percent | non_boss_percent } per target.
# First caller: A-Chan staff skill "Hard Worker Ghost Release!!!" — boss=0.25, non_boss=1.0.
# TRUE damage bypasses armor/MR + ΣAmp + ΣRed (see Enemy.recvDamage Damage.DamageType.TRUE branch).

@export var boss_percent: float = 0.25
@export var non_boss_percent: float = 1.0

func execute(context: SkillContext):
	if context.target == null:
		return
	# Source: TRUE damage skips ΣAmp regardless, but pass context.user along for death-cause tracking.
	var damage_source: Node2D = null
	if context.user is Node2D:
		damage_source = context.user as Node2D

	for target in context.target:
		if not is_instance_valid(target):
			continue

		# Defensive normalize — context.target may contain Enemy (PathFollow2D) or EnemyArea
		# (Area2D child, when find_multi_enemy hasn't normalized post-hitbox).
		var enemy: Enemy = null
		if target is Enemy:
			enemy = target
		elif target is Area2D and target.get_parent() is Enemy:
			enemy = target.get_parent()
		if enemy == null or enemy.stats == null:
			continue

		var percent: float = boss_percent if enemy.enemyType == Enemy.EnemyType.Boss else non_boss_percent
		var damage_amount: int = int(enemy.stats.maxHp * percent)
		if damage_amount <= 0:
			continue

		var dmg := Damage.new(damage_source, damage_amount, Damage.DamageType.TRUE)
		dmg.isSkillDamage = true
		enemy.recvDamage(dmg)
