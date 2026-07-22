class_name SkillActionProjectile
extends SkillAction

@export var lifetime: float = 5.0
@export var count: int = 1
@export var damageMultiplier: float = 1;
@export var damageMultiplierParamName: String = "";
@export var damageType: Damage.DamageType = Damage.DamageType.PHYSIC
# Crit rule (YAML `crit_rule`, same values as the attack action). Parse-time
# constant, safe on the shared action instance; per-cast state must live on
# the Projectile instead (one action spawns every cast's projectiles).
@export var critRule: SkillActionAttack.CritRule = SkillActionAttack.CritRule.NO_CRIT
@export var projectileTemplate: PackedScene;
@export var statusEffects: Array[EffectSpec] = [];

func execute(context: SkillContext):
	for i in count:
		var projectile: Projectile = projectileTemplate.instantiate() as Projectile

		projectile.global_position = context.user.global_position
		context.user.get_tree().root.add_child(projectile)

		setupProjectile(projectile, i, context)

	if(lifetime > 0 && context.user is Tower):
		var tower: Tower = context.user as Tower
		var gen: int = 0
		if(is_instance_valid(tower)):
			tower.enableRegenMana = false;
			tower.usingSkill = false;
			tower.skillController.currentMana = 0;
			gen = tower.skill_lock_generation

		await context.user.get_tree().create_timer(lifetime, false).timeout
		# Only re-enable regen if this cast is still the live one. resetForWave() bumps
		# skill_lock_generation so a stale timer can't unblock energy during a fresh
		# skill cast on the next wave.
		if(is_instance_valid(tower) and tower.skill_lock_generation == gen):
			tower.enableRegenMana = true

func setupProjectile(_projectile: Projectile, _i: int, _context: SkillContext):
	addStatusEffects(_projectile);

func addStatusEffects(projectile: Projectile):
	if not statusEffects || !is_instance_valid(projectile):
		return

	# Specs are immutable templates; the projectile instantiates a fresh
	# EffectInstance per hit, so sharing the spec list is safe.
	for spec in statusEffects:
		if spec != null:
			projectile.statusEffects.append(spec)

func onHit(projectile: Projectile, target: Enemy):
	if target is Enemy:
		var enemy: Enemy = target as Enemy
		enemy.recvDamage(_build_hit_damage(projectile))

		if not is_instance_valid(enemy):
			return

	if projectile.lifetime < 0:
		projectile.queue_free()

# Per-hit crit roll: each enemy contact rolls independently, matching the
# attack action's per-hit rolls (a circle projectile's re-hits included).
# projectile.damage stays the non-crit base snapshot from spawn - it is the
# delivered value on a non-crit hit and the fallback when the shooter has
# been freed mid-flight.
func _build_hit_damage(projectile: Projectile) -> Damage:
	var base: Damage = projectile.damage
	var shooter: Tower = projectile.shooter
	if not is_instance_valid(shooter):
		return base
	# The skill_crit_unlock mark opens the roll from outside, overriding an
	# authored no_crit - same gate as the attack action, read live per hit.
	var critAllowed: bool = critRule == SkillActionAttack.CritRule.USE_CRIT_CHANCE \
			or shooter.data.effects.stacks_of("skill_crit_unlock") > 0
	var isCrit: bool = critRule == SkillActionAttack.CritRule.GUARANTEED_CRIT
	if not isCrit and critAllowed:
		var critChance: float = shooter.data.getCritChance()
		isCrit = critChance > 0 and randi_range(1, 100) <= critChance
	if not isCrit:
		return base
	var sigmaCD: float = shooter.data.getStat().critMultiplier \
			+ shooter.data.effects.aggregate(EffectTypes.Kind.CRIT_DAMAGE_BONUS)
	var dmg := Damage.new(shooter, int(base.damage * sigmaCD), base.type, true)
	dmg.isSkillDamage = true
	return dmg

func getDamageMultiplier(context: SkillContext):
	var tower: Tower = context.user as Tower
	return context.getParameter(damageMultiplierParamName, tower.data._level - 1) if damageMultiplierParamName != "" else damageMultiplier

func onKilled(_projectile: Projectile, _enemy: Enemy):
	pass
