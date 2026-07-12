class_name SkillActionAftershock
extends SkillAction

# "aftershock" execution pattern (tower_skill.md): the cast plants a delayed
# re-hit of the SAME area and returns immediately - the tower resumes normal
# behavior while the bomb waits. Everything resolves at EXPLOSION time: fresh
# target query at the snapshotted cast-time center, live Total Attack, live
# crit chance, live stack bonus (e.g. Calliope Souls raised by the first
# hit's kills). First user: Mori Calliope evolved skill.

@export var delay: float = 0.5
@export var width: int = 3
@export var height: int = 3
# Inner actions built at parse time from the same data block (skill_utility.gd)
# so the explosion reuses the full find/attack pipelines.
var find_action: SkillActionFindMultipleInRange
var attack_action: SkillActionAttack

func execute(context: SkillContext):
	var tower: Tower = context.user as Tower
	if tower == null or find_action == null or attack_action == null:
		return
	var timer := AftershockTimer.new()
	timer.setup(self, tower, tower.skill_lock_generation, tower.global_position,
			context.extra.get("parameter", {}), context.skillName)
	tower.add_child(timer)
	# No await: the cast finishes normally while the bomb counts down.

# One-shot countdown node. The _process delta freezes with pause and scales
# with x2 speed (same clock as the effect system); a SceneTree create_timer
# keeps counting while paused - do not swap this for one.
class AftershockTimer:
	extends Node2D

	var action: SkillActionAftershock
	var tower: Tower
	var gen: int
	var center: Vector2
	var params: Dictionary
	var skill_name: String
	var elapsed: float = 0.0
	var fired: bool = false

	func setup(p_action: SkillActionAftershock, p_tower: Tower, p_gen: int,
			p_center: Vector2, p_params: Dictionary, p_skill_name: String) -> void:
		action = p_action
		tower = p_tower
		gen = p_gen
		center = p_center
		params = p_params
		skill_name = p_skill_name

	func _process(delta: float) -> void:
		# resetForWave() bumps skill_lock_generation, so a bomb pending at wave
		# end (or from any stale cast) drops silently instead of exploding into
		# the next wave.
		if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
			queue_free()
			return
		if fired:
			return
		elapsed += delta
		if elapsed >= action.delay:
			# Must flip BEFORE _fire's awaits: _process keeps ticking during the
			# Hitbox physics-frame await and would re-enter = double explosion.
			fired = true
			_fire()

	func _fire() -> void:
		var ctx := SkillContext.new()
		ctx.user = tower
		ctx.skillName = skill_name
		ctx.extra["parameter"] = params
		# Snapshotted cast-time center -> the finder's centered override path
		# (axis-aligned box, same query the Staff player-aim uses).
		ctx.extra["target_position"] = center
		await action.find_action.execute(ctx)
		if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
			queue_free()
			return
		if not ctx.target.is_empty():
			await action.attack_action.execute(ctx)
		queue_free()
