class_name SkillActionSetSpeed
extends SkillAction

@export var speed: float = 1.0

func execute(context: SkillContext):
	if(context.user == null):
		return;

	if(!context.user.has_method("setSpeed")):
		return;

	context.user.setSpeed(speed)