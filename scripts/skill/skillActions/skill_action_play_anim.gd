extends SkillAction
class_name SkillActionPlayAnimation

@export var animationName: String = ""
@export var animationSpeed: float = 1.0
@export var duration: float = 0.0

func execute(context: SkillContext):
	if animationName == "":
		context.cancel = true;

	if !context.user.has_method("play_animation"):
		context.cancel = true;

	if(context.cancel):
		return

	# Missing clip: skip this beat instead of hanging the await. (anim_finish
	# also guards 1-frame/missing clips, but a missing clip may never emit
	# frame_changed.) Skip without cancelling so the rest of the combo runs.
	if context.user.has_method("has_animation") and !context.user.has_animation(animationName):
		push_warning("SkillActionPlayAnimation: missing animation '" + animationName + "' - skipping beat");
		return

	# duration (seconds) stretches/compresses the clip to fit; falls back to
	# animationSpeed when unset. The ~80% impact point scales automatically.
	var speed: float = animationSpeed
	if duration > 0.0 and context.user.has_method("get_animation_duration"):
		var native: float = context.user.get_animation_duration(animationName)
		if native > 0.0:
			speed = native / duration

	if !context.user.play_animation(animationName, speed):
		context.cancel = true;

	if(context.cancel):
		return

	var name = await context.user.on_animation_finished
	if not is_instance_valid(context.user):
		context.cancel = true
		return
	context.cancel = name != animationName
