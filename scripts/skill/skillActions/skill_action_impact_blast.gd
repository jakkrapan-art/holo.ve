class_name SkillActionImpactBlast
extends SkillAction

# "impact blast" delivery + the optional "multicast" repeat, in one action.
# A card homes to the caster's locked enemy and its payload is a blast BOX at
# the impact point (terminal effect), not single-target damage. With an
# extra_casts table the whole cast can repeat 1-N extra times off one roll.
# First user: Gavis Bettel.
#
# Delivery rules:
# - The card is a carrier only: it deals no damage itself, so the blast resolves
#   at LANDING time with a fresh target query, live Total Attack and live crit
#   gate (same resolve-late rule as aftershock/channel).
# - explode_on_target_lost: a kill mid-flight does NOT waste the cast - the card
#   flies on to where the target last stood and bursts there. Deliberately
#   unlike the normal-attack bullet, which vanishes (Director 2026-07-24).
#
# Multicast rules:
# - ONE roll against one cumulative table, walked highest-first, outcomes
#   mutually exclusive (Dota Ogre Magi model), so the authored chances ARE the
#   odds the player reads in the desc.
# - Every cast plays the clip again and re-reads the tower's live lock, so a
#   repeat re-targets. If no target turns up within search_time the WHOLE cast
#   ends - never a per-repeat wait that could stack into seconds of standing.
# - Energy: a cast that threw nothing cancels (fizzle keeps Energy, the standard
#   rule); once a card is airborne the cast must reach onSuccess and pay.

@export var width: int = 1
@export var height: int = 1
@export var speed: float = 4.0          # card travel, tiles/sec
@export var lifetime: float = 5.0       # self-free safety net; expiry fires no blast
@export var searchTime: float = 1.0     # patience for re-acquiring a target, seconds
@export var animation: String = "skill"
@export var castTime: float = 0.0
@export var projectileTemplate: PackedScene
# Multicast table, authored highest-extra first: [{ extra: int, chance: float }].
# Empty = a plain single cast.
var extra_casts: Array = []
# Inner actions built at parse time from the same data block (skill_utility.gd)
# so the blast reuses the full find/attack pipelines and the clip reuses the
# per-beat cast_time scaling.
var find_action: SkillActionFindMultipleInRange
var attack_action: SkillActionAttack
var anim_action: SkillActionPlayAnimation

func execute(context: SkillContext):
	var tower: Tower = context.user as Tower
	if tower == null or find_action == null or attack_action == null or projectileTemplate == null:
		return

	var gen: int = tower.skill_lock_generation
	var casts: int = 1 + _roll_extra_casts()
	var thrown: int = 0

	for _i in casts:
		var target: Enemy = await _acquire_target(tower, gen)
		if target == null:
			# Acquire runs BEFORE the clip on purpose: a fizzle here has played no
			# animation, so cancelling cannot strand the tower in a skill pose.
			if thrown == 0:
				context.cancel = true
			return

		if anim_action != null:
			await anim_action.execute(context)
			# The beat's own cancel flag (set when a different clip reported in) is
			# not our cancel signal - a real cancel is a generation bump. Clear it
			# so the next repeat and the skill's trailing idle beat still run.
			context.cancel = false

		if not is_instance_valid(tower):
			context.cancel = true
			return
		if tower.skill_lock_generation != gen:
			return

		# The locked enemy can die during the clip and Projectile.setupTarget
		# dereferences it, so re-pick from the live lock. No second wait here -
		# the patience budget was already spent above.
		if not is_instance_valid(target):
			target = tower.enemy if is_instance_valid(tower.enemy) else null
			if target == null:
				return

		_throw_card(tower, target, context, gen)
		thrown += 1
		# Each extra thrown card counts as a full cast for on-cast synergies
		# (Robotic stacks, Myth energy). The FIRST card is covered by the
		# skill-end cast_succeeded emit; only repeats re-emit here, and a
		# fizzled repeat (no card) counts nothing.
		if thrown > 1:
			tower.notify_extra_cast()

# One roll, cumulative table, highest-first. Returns 0 when the roll lands in the
# tail (no multicast) or when no table was authored.
func _roll_extra_casts() -> int:
	if extra_casts.is_empty():
		return 0

	var roll: float = randf()
	var acc: float = 0.0
	for entry in extra_casts:
		acc += float(entry.get("chance", 0.0))
		if roll < acc:
			return int(entry.get("extra", 0))
	return 0

# Wait up to searchTime for the tower's own lock to hold a live enemy. The
# EnemyDetector already re-acquires on death/exit with closest-to-path-end
# priority, so this is patience, not a second targeting system.
func _acquire_target(tower: Tower, gen: int) -> Enemy:
	var waited: float = 0.0
	while waited <= searchTime:
		if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
			return null
		if is_instance_valid(tower.enemy):
			return tower.enemy

		await tower.get_tree().process_frame
		# process_frame keeps emitting while paused, so hold here - a paused game
		# must not burn the search budget (same guard as find_multi_enemy).
		while is_instance_valid(tower) and tower.get_tree().paused:
			await tower.get_tree().process_frame
		if not is_instance_valid(tower):
			return null
		waited += tower.get_process_delta_time()
	return null

func _throw_card(tower: Tower, target: Enemy, context: SkillContext, gen: int) -> void:
	var projectile: Projectile = projectileTemplate.instantiate() as Projectile
	if projectile == null:
		return

	var aim: Vector2 = (target.global_position - tower.global_position).normalized()
	tower.get_tree().root.add_child(projectile)
	# Leave the character edge, not its belly - same muzzle knob as the other
	# directional/homing spawn sites.
	projectile.global_position = Utility.muzzle_origin(tower.global_position, aim)
	projectile.speed = speed * GridHelper.CELL_SIZE
	projectile.explode_on_target_lost = true
	# Carrier damage is 0: the blast is the entire payload.
	var carrier := Damage.new(tower, 0, tower.data.attackType)
	var onImpact := Callable(self, "_on_card_impact").bind(
			context.extra.get("parameter", {}), context.skillName, gen)
	projectile.setupTarget(tower, target, carrier, lifetime,
			ProjectileCallback.new(onImpact, Callable(), Callable()))

# Terminal payload: an axis-aligned blast box centered on where the card landed.
# `_hit_enemy` is null on the target-lost arrival path - never dereference it.
func _on_card_impact(projectile: Projectile, _hit_enemy, params: Dictionary, skill_name: String, gen: int) -> void:
	if not is_instance_valid(projectile):
		return
	# Snapshot BEFORE any await: the projectile frees itself the moment this
	# coroutine first suspends.
	var impact: Vector2 = projectile.global_position
	var tower: Tower = projectile.shooter
	if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
		return

	# This callback runs synchronously from area_entered, i.e. INSIDE the physics
	# flush - Hitbox.create() would trip "Can't change this state while flushing
	# queries". Defer one frame before any physics work; the impact point is
	# already snapshotted so nothing drifts. The pause hold keeps a paused game
	# from resolving the blast (process_frame keeps emitting while paused).
	await tower.get_tree().process_frame
	while is_instance_valid(tower) and tower.get_tree().paused:
		await tower.get_tree().process_frame
	if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
		return

	var ctx := SkillContext.new()
	ctx.user = tower
	ctx.skillName = skill_name
	ctx.extra["parameter"] = params
	# Landing point -> the finder's centered override path (axis-aligned box, the
	# same query the aftershock explosion uses).
	ctx.extra["target_position"] = impact
	ctx.target = []
	# find_targets_in_rotated_range directly, NOT find_action.execute(): multicast
	# can leave several cards in the air at once and execute() mutates the shared
	# `attempt` counter on this one action instance. Everything below is
	# per-context state.
	await find_action.find_targets_in_rotated_range(ctx)
	if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
		return
	# Empty box = whiff, never an error.
	if not ctx.target.is_empty():
		await attack_action.execute(ctx)
