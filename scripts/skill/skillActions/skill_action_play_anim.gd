extends SkillAction
class_name SkillActionPlayAnimation

@export var animationName: String = ""
@export var animationSpeed: float = 1.0

func execute(context: SkillContext):
	if animationName == "":
		context.cancel = true;

	if !context.user.has_method("play_animation"):
		context.cancel = true;

	if !context.user.play_animation(animationName, animationSpeed):
		context.cancel = true;

	if(context.cancel):
		return

	var name = await context.user.on_animation_finished
	context.cancel = name != animationName
