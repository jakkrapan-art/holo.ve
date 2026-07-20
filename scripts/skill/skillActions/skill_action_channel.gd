class_name SkillActionChannel
extends SkillAction

# "channel" execution pattern: the cast locks the aimed zone
# and holds the tower busy for `cast_time` seconds while re-striking that zone
# every `tick_interval`. BLOCKING - execute() awaits until the channel ends, so
# the controller keeps usingSkill true and Energy drains only at onSuccess
# (a wave-end cancel keeps Energy). Each tick resolves fresh: live target
# query at the locked center, live Total Attack, effects re-applied (REFRESH).
# First user: Ninomae Ina'nis evolved skill.

@export var castTime: float = 3.0
@export var tick_interval: float = 0.25
@export var width: int = 3
@export var height: int = 3
@export var animation: String = "skill"
# Inner actions built at parse time from the same data block (skill_utility.gd)
# so every tick reuses the full find/attack pipelines.
var find_action: SkillActionFindMultipleInRange
var attack_action: SkillActionAttack
# Optional per-tick VFX hook (parity with aftershock); unset = the find's red
# Hitbox rect is the visible tick flash.
var effect_action: SkillActionPlayEffect

func execute(context: SkillContext):
	var tower: Tower = context.user as Tower
	if tower == null or find_action == null or attack_action == null:
		return
	# Zone center locked at cast start: the skill's first find_multi_enemy
	# published the world center of the box it queried. Fallbacks mirror the
	# finder's own aimed-mode math in case the key is ever absent.
	var center: Vector2 = tower.global_position
	var area_center = context.extra.get("area_center", null)
	if area_center is Vector2:
		center = area_center
	else:
		var aim_dir = context.extra.get("aim_dir", null)
		if aim_dir is Vector2:
			var rot: float = aim_dir.angle() - PI / 2
			var actual_height: float = height * GridHelper.CELL_SIZE + (GridHelper.CELL_SIZE * 0.5)
			center = tower.global_position + Vector2(0, actual_height * 0.5).rotated(rot)
	# Cast clip plays once, no await - a looping clip (the base tower "skill"
	# clip loops) runs for the whole channel; the skill's trailing idle
	# play_animation action restores idle after.
	if tower.has_animation(animation):
		tower.play_animation(animation)
	var ticker := ChannelTicker.new()
	ticker.setup(self, tower, tower.skill_lock_generation, center,
			context.extra.get("parameter", {}), context.skillName)
	tower.add_child(ticker)
	# The blocking hold: every ticker exit path emits finished exactly once,
	# so this await can never hang.
	await ticker.finished

# Tick clock node. The _process delta freezes with pause and scales with x2
# speed (same clock as aftershock/the effect system); a SceneTree create_timer
# keeps counting while paused - do not swap this for one.
class ChannelTicker:
	extends Node2D

	var action: SkillActionChannel
	var tower: Tower
	var gen: int
	var center: Vector2
	var params: Dictionary
	var skill_name: String
	var elapsed: float = 0.0
	var ticks_fired: int = 0
	var total_ticks: int = 0
	var in_flight: int = 0
	var done: bool = false

	signal finished

	func setup(p_action: SkillActionChannel, p_tower: Tower, p_gen: int,
			p_center: Vector2, p_params: Dictionary, p_skill_name: String) -> void:
		action = p_action
		tower = p_tower
		gen = p_gen
		center = p_center
		params = p_params
		skill_name = p_skill_name
		total_ticks = int(round(action.castTime / action.tick_interval))

	func _process(delta: float) -> void:
		if done:
			return
		# resetForWave() bumps skill_lock_generation, so a wave-end cancel
		# stops the ticks immediately; the emit releases the awaiting cast,
		# whose controller then skips onSuccess (Energy kept).
		if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
			_finish()
			return
		elapsed += delta
		# Tick k fires at k * interval (first tick at one interval, never t=0).
		# ticks_fired increments BEFORE the fire: _process keeps running during
		# the tick's Hitbox physics-frame await and would re-enter = double tick.
		while ticks_fired < total_ticks and elapsed >= float(ticks_fired + 1) * action.tick_interval:
			ticks_fired += 1
			_fire_tick()
		if ticks_fired >= total_ticks:
			_finish()

	func _fire_tick() -> void:
		# in_flight defers queue_free while this coroutine is suspended in the
		# Hitbox await - freeing on _finish() the same frame as the final tick
		# would kill the suspended coroutine and lose that tick's attack.
		in_flight += 1
		var ctx := SkillContext.new()
		ctx.user = tower
		ctx.skillName = skill_name
		ctx.extra["parameter"] = params
		# Locked cast-time center -> the finder's centered override path
		# (axis-aligned box, same query the aftershock explosion uses).
		ctx.extra["target_position"] = center
		if action.effect_action != null:
			action.effect_action.execute(ctx)
		await action.find_action.execute(ctx)
		if is_instance_valid(tower) and tower.skill_lock_generation == gen:
			# Empty zone = whiff tick: no damage, the channel continues.
			if not ctx.target.is_empty():
				await action.attack_action.execute(ctx)
		in_flight -= 1
		if done and in_flight == 0:
			queue_free()

	func _finish() -> void:
		if done:
			return
		done = true
		finished.emit()
		if in_flight == 0:
			queue_free()

	func _exit_tree() -> void:
		# Freed externally (e.g. the tower node was freed mid-channel): still
		# release the awaiting execute() so the skill controller never hangs.
		if not done:
			done = true
			finished.emit()
