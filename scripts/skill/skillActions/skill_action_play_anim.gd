extends SkillAction
class_name SkillActionPlayAnimation

@export var animationName: String = ""
@export var animationSpeed: float = 1.0
@export var castTime: float = 0.0
@export var impactFrame: int = 0

func execute(context: SkillContext):
	if animationName == "":
		context.cancel = true;

	if !context.user.has_method("play_animation"):
		context.cancel = true;

	if(context.cancel):
		return

	# Missing clip: skip this beat instead of hanging the await. Skip without
	# cancelling so the rest of the combo runs.
	if context.user.has_method("has_animation") and !context.user.has_animation(animationName):
		push_warning("SkillActionPlayAnimation: missing animation '" + animationName + "' - skipping beat");
		return

	# Settle the previous beat's tail first: its clip still owns the remainder
	# of that beat's cast_time (the end-pose frames past the impact point).
	await settle_tail(context)
	if not is_instance_valid(context.user):
		context.cancel = true
		return

	var timed := true
	if context.user.has_method("is_animation_looping") and context.user.is_animation_looping(animationName):
		if castTime > 0.0:
			# Authoring error (artist left the clip looping): pacing still works,
			# but the clip can neither hold its end pose nor finish for the tail.
			push_warning("SkillActionPlayAnimation: '" + animationName + "' loops but has cast_time - turn the clip's loop off");
		else:
			# Looping clip with no cast_time = a state switch (the trailing idle
			# beat): play it and return, never await a clip that has no end.
			timed = false

	# cast_time (seconds) stretches/compresses the whole clip to fit - per-frame
	# durations weight the frames inside it, so artist frame edits never change
	# the beat's wall time. Falls back to animationSpeed when unset.
	var speed: float = animationSpeed
	if castTime > 0.0 and context.user.has_method("get_animation_duration"):
		var native: float = context.user.get_animation_duration(animationName)
		if native > 0.0:
			speed = native / castTime

	if !context.user.play_animation(animationName, speed):
		context.cancel = true;

	if(context.cancel || !timed):
		return

	if !context.user.has_method("wait_animation_frame"):
		return

	# Following actions (damage/VFX) fire when the clip reaches its impact frame:
	# authored impact_frame (1-based), else the 80%-weighted fallback.
	var impact_idx: int = context.user.resolve_impact_frame(animationName, impactFrame)
	var reached: bool = await context.user.wait_animation_frame(animationName, impact_idx)
	if not is_instance_valid(context.user):
		context.cancel = true
		return
	if not reached:
		# Clip was switched away mid-beat (wave-end reset) - cancel the beat.
		context.cancel = true
		return

	# The frames past the impact point still occupy the rest of cast_time; the
	# next beat / BaseSkillController's pre-recovery settle waits them out.
	context.extra["anim_tail"] = animationName

# Waits out a pending tail recorded by an earlier beat. Also called by
# BaseSkillController before the recovery hold, so the final beat's end pose
# visibly completes. State-poll underneath - safe on already-finished,
# switched-away, and looping clips alike.
static func settle_tail(context: SkillContext) -> void:
	var tail: String = context.extra.get("anim_tail", "")
	if tail == "":
		return
	context.extra["anim_tail"] = ""
	if is_instance_valid(context.user) and context.user.has_method("wait_animation_end"):
		await context.user.wait_animation_end(tail)
