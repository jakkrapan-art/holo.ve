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

# Override base execute to use effective_lifetime (not configured lifetime) for
# the mana lockout window. Without this override, Kiara Hinotori (lifetime=1.5
# cap but max_range/speed=0.42 actual travel) would lock mana regen + idle
# animation for the full 1.5s, causing visible cast delay + skill animation
# loop after the projectile already despawned.
#
# Also adds a skill_lock_generation guard so a stale post-await callback can't
# re-enable mana regen after a wave-end resetForWave (see tower.gd:354-368).
func execute(context: SkillContext):
	for i in count:
		var projectile: Projectile = projectileTemplate.instantiate() as Projectile
		projectile.global_position = context.user.global_position
		context.user.get_tree().root.add_child(projectile)
		setupProjectile(projectile, i, context)

	# Effective lockout = min(lifetime, max_range/speed) — mirrors
	# setupProjectile's projectile lifetime so tower lockout ends when the
	# projectile actually despawns, not after the configured ceiling.
	var effective_lifetime: float = lifetime
	if max_range > 0:
		effective_lifetime = min(lifetime, max_range / speed)

	if effective_lifetime > 0 and context.user is Tower:
		var tower: Tower = context.user as Tower
		if not is_instance_valid(tower):
			return
		var saved_gen: int = tower.skill_lock_generation
		tower.enableRegenMana = false
		tower.usingSkill = false
		tower.skillController.currentMana = 0

		await context.user.get_tree().create_timer(effective_lifetime).timeout

		# Wave-end guard: skip re-enable if resetForWave fired during the await.
		if is_instance_valid(tower) and tower.skill_lock_generation == saved_gen:
			tower.enableRegenMana = true
