class_name SkillActionProjectile
extends SkillAction

@export var lifetime: float = 5.0
@export var count: int = 1
@export var damageMultiplier: float = 1;
@export var damageMultiplierParamName: String = "";
@export var damageType: Damage.DamageType = Damage.DamageType.PHYSIC
@export var projectileTemplate: PackedScene;
@export var statusEffects: Array[StatusEffect] = [];

func execute(context: SkillContext):
	for i in count:
		var projectile: Projectile = projectileTemplate.instantiate() as Projectile

		projectile.global_position = context.user.global_position
		context.user.get_tree().root.add_child(projectile)

		setupProjectile(projectile, i, context)

	if(lifetime > 0 && context.user is Tower):
		var tower: Tower = context.user as Tower

		tower.enableRegenMana = false;
		tower.usingSkill = false;
		tower.skillController.currentMana = 0;

		await context.user.get_tree().create_timer(lifetime).timeout
		tower.enableRegenMana = true

func setupProjectile(_projectile: Projectile, _i: int, _context: SkillContext):
	addStatusEffects(_projectile);

func addStatusEffects(projectile: Projectile):
	if not statusEffects || !is_instance_valid(projectile):
		return

	for effect in statusEffects:
		var e = effect.duplicate() as StatusEffect
		if is_instance_valid(effect):
			projectile.statusEffects.append(e)

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
	return context.getParameter(damageMultiplierParamName, tower.data.level - 1) if damageMultiplierParamName != "" else damageMultiplier

func onKilled(_projectile: Projectile, _enemy: Enemy):
	pass
