class_name SkillActionProjectile
extends SkillAction

@export var lifetime: float = 5.0
@export var count: int = 1
@export var damageMultiplier: Array[float] = []
@export var damageType: Damage.DamageType = Damage.DamageType.physical
@export var projectileTemplate: PackedScene;

func execute(context: SkillContext):
	for i in count:
		var projectile: Projectile = projectileTemplate.instantiate() as Projectile

		projectile.global_position = context.user.global_position
		context.user.get_tree().root.add_child(projectile)

		setupProjectile(projectile, i, context)

func setupProjectile(_projectile: Projectile, _i: int, _context: SkillContext):
	pass

func onHit(projectile: Projectile, target: Enemy):
	if target is Enemy:
		var enemy: Enemy = target as Enemy
		enemy.recvDamage(projectile.damage)

		if not is_instance_valid(enemy):
			return

	if projectile.lifetime < 0:
		projectile.queue_free()

func onKilled(_projectile: Projectile, _enemy: Enemy):
	pass
