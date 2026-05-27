class_name SkillCreateDirectionalProjectile
extends SkillActionProjectile

# Forward-moving projectile spawned from caster, traveling toward the primary
# target picked by an upstream find_multi_enemy (or tower.enemy as fallback).
# First user: Kiara evolved "Hinotori" projectile (3×5 forward AOE).
#
# YAML knobs (all designer-tunable):
#   speed:       tiles per second (converted to pixels at setup)
#   max_range:   tiles; -1 = unlimited (use lifetime only). When > 0, the
#                effective lifetime is min(lifetime, max_range / speed).
#   lifetime:    seconds (inherited from SkillActionProjectile)
#   damage_multiplier / damage_multiplier_param_name / damage_type /
#   status_effects / projectile (scene) — all inherited from base

@export var speed: float = 12.0     # tiles/sec
@export var max_range: float = -1.0 # tiles; -1 = unlimited

func setupProjectile(projectile: Projectile, i: int, context: SkillContext):
	var tower: Tower = context.user as Tower
	var multi: float = getDamageMultiplier(context)
	var damage: Damage = Damage.new(tower, multi * tower.data.getDamage(null, null).damage, damageType)

	# Direction = from tower toward primary target. Prefer the first target
	# picked by find_multi_enemy (closest-to-path-end after sorting). Fall
	# back to the tower's normal-attack target. Final fallback: face up.
	var direction: Vector2 = Vector2.UP
	if not context.target.is_empty() and is_instance_valid(context.target[0]):
		direction = (context.target[0].global_position - tower.global_position).normalized()
	elif is_instance_valid(tower.enemy):
		direction = (tower.enemy.global_position - tower.global_position).normalized()

	# Cap travel by range if specified. Pierce projectiles can have a long
	# configured lifetime but should stop at the AOE corridor edge.
	var effective_lifetime: float = lifetime
	if max_range > 0:
		var range_lifetime: float = max_range / speed
		effective_lifetime = min(lifetime, range_lifetime)

	projectile.speed = speed * GridHelper.CELL_SIZE
	projectile.prevent_rehit = true
	projectile.setup_direction(tower, direction, damage, effective_lifetime,
			ProjectileCallback.new(Callable(self, "onHit"), Callable(), Callable()))
	super.setupProjectile(projectile, i, context)
