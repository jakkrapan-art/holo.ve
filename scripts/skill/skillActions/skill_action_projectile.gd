class_name SkillActionProjectile
extends SkillAction

@export var lifetime: float = 5.0
@export var count: int = 1
@export var damageMultiplier: float = 1;
@export var damageMultiplierParamName: String = "";
@export var damageType: Damage.DamageType = Damage.DamageType.PHYSIC
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
		enemy.recvDamage(projectile.damage)

		if not is_instance_valid(enemy):
			return

	if projectile.lifetime < 0:
		projectile.queue_free()

func getDamageMultiplier(context: SkillContext):
	var tower: Tower = context.user as Tower
	return context.getParameter(damageMultiplierParamName, tower.data._level - 1) if damageMultiplierParamName != "" else damageMultiplier

func onKilled(_projectile: Projectile, _enemy: Enemy):
	pass
