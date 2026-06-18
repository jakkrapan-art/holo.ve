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
	elif context.extra.has("aim_dir"):
		# Snapshotted at find_multi_enemy time — survives the enemy dying mid-cast.
		direction = context.extra["aim_dir"]

	# Push the spawn out from the tower center toward the aim direction (muzzle
	# offset) so the projectile/VFX leaves the character edge, not its belly.
	# execute() spawned it at the center before the direction was known; now that
	# direction is resolved, override the origin before setup_direction reads it.
	projectile.global_position = Utility.muzzle_origin(tower.global_position, direction)

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

# Override base execute so mana lockout doesn't block the action sequence.
# Base SkillActionProjectile awaits `lifetime` inside execute, which freezes
# the following action (`play_animation idle`) until after the lockout —
# causing a visible animation glitch where the skill animation finishes and
# starts to loop before idle finally fires. Amelia avoids this because her
# non-projectile actions don't await.
#
# Fix: spawn projectile, set lockout flags, then schedule the re-enable via
# a separate non-blocking coroutine. execute() returns immediately so the
# action sequence proceeds to `play_animation idle` right after the cast.
# Wave-end resetForWave still invalidates the in-flight callback via
# skill_lock_generation (see tower.gd:354-368).
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
		tower.enableRegenMana = false
		tower.usingSkill = false
		tower.skillController.currentMana = 0
		# Fire-and-forget unlock — does NOT await, so the action sequence
		# (play_animation idle next) can run immediately.
		_unlock_mana_after_delay(tower, tower.skill_lock_generation, effective_lifetime)

# Background coroutine that re-enables mana regen after the projectile's
# effective travel time. Skipped if a wave-end resetForWave has bumped the
# skill_lock_generation since this cast started (stale callback guard).
func _unlock_mana_after_delay(tower: Tower, saved_gen: int, delay: float) -> void:
	await tower.get_tree().create_timer(delay).timeout
	if is_instance_valid(tower) and tower.skill_lock_generation == saved_gen:
		tower.enableRegenMana = true
