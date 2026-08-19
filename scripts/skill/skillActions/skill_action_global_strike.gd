class_name SkillActionGlobalStrike
extends SkillAction

# "global strike" delivery: pick ONE RANDOM live enemy anywhere on the map and
# drop a carrier onto it from a far diagonal spawn point; the payload is a
# blast BOX at the impact point (terminal effect), resolved at landing time
# with a fresh target query, live Total Attack and live crit gate - same
# resolve-late rule as impact_blast/aftershock/channel.
# First user: Machina X Flayon "Funnel".
#
# Delivery rules (Director 2026-07-31):
# - The blast anchors at the TARGET with a constant time-to-impact: the carrier
#   spawns at a fixed distance from the target (spawn_distance / speed), so
#   every strike lands the same beat after fire wherever the enemy stands.
#   A carrier flying from the tower was rejected - map-wide targets would make
#   the damage delay swing by seconds.
# - The spawn point sits on a DIAGONAL above the target, never straight
#   overhead (imperfection rule): spawn_angle_deg off vertical, the side picked
#   at random, plus an angle_jitter_deg wobble per strike. The travel direction
#   rides the impact-callback binds so a future funnel/beam VFX can orient its
#   head along it without touching this mechanic.
# - The carrier deals no damage itself; explode_on_target_lost keeps a
#   mid-flight kill from wasting the strike (bursts where the target last
#   stood - the impact_blast rule).
# - Invincible enemies are never picked (same skip as the EnemyDetector lock),
#   but the blast box still hits whoever stands in it.

@export var width: int = 1
@export var height: int = 1
@export var speed: float = 4.0            # carrier travel, tiles/sec
@export var lifetime: float = 5.0         # self-free safety net; expiry fires no blast
@export var spawn_distance: float = 6.0   # tiles from target to the carrier spawn point
@export var spawn_angle_deg: float = 45.0 # diagonal off vertical; 0 = straight overhead
@export var angle_jitter_deg: float = 10.0
@export var animation: String = ""        # optional embedded cast clip ("" = none, e.g. inside a channel tick)
@export var castTime: float = 0.0
@export var impactFrame: int = 0
@export var projectileTemplate: PackedScene
# Inner actions built at parse time from the same data block (skill_utility.gd)
# so the blast reuses the full find/attack pipelines and the clip reuses the
# per-beat cast_time scaling + impact_frame.
var find_action: SkillActionFindMultipleInRange
var attack_action: SkillActionAttack
var anim_action: SkillActionPlayAnimation
var sound_action: SkillActionPlaySound

func execute(context: SkillContext):
	var tower: Tower = context.user as Tower
	if tower == null or find_action == null or attack_action == null or projectileTemplate == null:
		return

	var gen: int = tower.skill_lock_generation
	var target: Enemy = pick_global_target(tower)
	if target == null:
		# Pick runs BEFORE the clip on purpose: a fizzle here has played no
		# animation, so cancelling cannot strand the tower in a skill pose
		# (Energy kept - the standard fizzle rule).
		context.cancel = true
		return

	if anim_action != null:
		await anim_action.execute(context)
		# The beat's own cancel flag (set when a different clip reported in) is
		# not our cancel signal - a real cancel is a generation bump. Clear it
		# so the skill's trailing idle beat still runs.
		context.cancel = false

	if not is_instance_valid(tower):
		context.cancel = true
		return
	if tower.skill_lock_generation != gen:
		return

	# The random mark can die during the clip; re-roll once. None left = the
	# cast whiffs after a visible clip and pays (matches impact_blast).
	if not is_instance_valid(target):
		target = pick_global_target(tower)
		if target == null:
			return

	if sound_action != null:
		sound_action.execute(context)
	_launch_strike(tower, target, context.extra.get("parameter", {}), context.skillName, gen)

# One animation-free strike (per channel tick). Returns false on a whiff
# (no live enemy anywhere); the carrier resolves its blast async on landing.
func fire_strike(tower: Tower, params: Dictionary, skill_name: String, gen: int) -> bool:
	if not is_instance_valid(tower) or projectileTemplate == null:
		return false
	var target: Enemy = pick_global_target(tower)
	if target == null:
		return false
	_launch_strike(tower, target, params, skill_name, gen)
	return true

# Uniform random pick over every live enemy on the map. Both the PathFollow2D
# enemy and its child EnemyArea sit in the "enemy" group, so the `as Enemy` +
# `initialized` filter is mandatory (the game_scene._pick_enemy_at pattern).
# Also the cast-gate probe for `cast_target: global` (tower.gd _hasCastTarget).
static func pick_global_target(tower: Tower) -> Enemy:
	var candidates: Array = []
	for node in tower.get_tree().get_nodes_in_group("enemy"):
		var e := node as Enemy
		if e != null and e.initialized and not e.isInvincible():
			candidates.append(e)
	if candidates.is_empty():
		return null
	return candidates.pick_random()

func _launch_strike(tower: Tower, target: Enemy, params: Dictionary, skill_name: String, gen: int) -> void:
	var projectile: Projectile = projectileTemplate.instantiate() as Projectile
	if projectile == null:
		return

	var angle: float = deg_to_rad(spawn_angle_deg + randf_range(-angle_jitter_deg, angle_jitter_deg))
	var side: float = -1.0 if randf() < 0.5 else 1.0
	var offset: Vector2 = Vector2(0, -spawn_distance * GridHelper.CELL_SIZE).rotated(angle * side)
	tower.get_tree().root.add_child(projectile)
	projectile.global_position = target.global_position + offset
	projectile.speed = speed * GridHelper.CELL_SIZE
	projectile.explode_on_target_lost = true
	# Carrier damage is 0: the blast is the entire payload.
	var carrier := Damage.new(tower, 0, tower.data.attackType)
	var onImpact := Callable(self, "_on_strike_impact").bind(
			params, skill_name, gen, -offset.normalized())
	projectile.setupTarget(tower, target, carrier, lifetime,
			ProjectileCallback.new(onImpact, Callable(), Callable()))

# Terminal payload: an axis-aligned blast box centered on where the carrier
# landed. `_hit_enemy` is null on the target-lost arrival path - never
# dereference it. `_travel_dir` is the funnel/beam VFX hook (unused today).
func _on_strike_impact(projectile: Projectile, _hit_enemy, params: Dictionary, skill_name: String, gen: int, _travel_dir: Vector2) -> void:
	if not is_instance_valid(projectile):
		return
	# Snapshot BEFORE any await: the projectile frees itself the moment this
	# coroutine first suspends.
	var impact: Vector2 = projectile.global_position
	var tower: Tower = projectile.shooter
	if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
		return

	# This callback runs synchronously from area_entered, i.e. INSIDE the
	# physics flush - Hitbox.create() would trip "Can't change this state while
	# flushing queries". Defer one frame before any physics work; the pause
	# hold keeps a paused game from resolving the blast.
	await tower.get_tree().process_frame
	while is_instance_valid(tower) and tower.get_tree().paused:
		await tower.get_tree().process_frame
	if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
		return

	var ctx := SkillContext.new()
	ctx.user = tower
	ctx.skillName = skill_name
	ctx.extra["parameter"] = params
	# Landing point -> the finder's centered override path (axis-aligned box,
	# the same query the aftershock explosion uses).
	ctx.extra["target_position"] = impact
	ctx.target = []
	# find_targets_in_rotated_range directly, NOT find_action.execute(): the
	# channel-tick path can leave several carriers in the air at once and
	# execute() mutates the shared `attempt` counter on this one action
	# instance. Everything below is per-context state.
	await find_action.find_targets_in_rotated_range(ctx)
	if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
		return
	# Empty box = whiff, never an error.
	if not ctx.target.is_empty():
		await attack_action.execute(ctx)
