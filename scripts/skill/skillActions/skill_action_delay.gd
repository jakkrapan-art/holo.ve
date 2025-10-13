class_name SkillActionDelay
extends SkillAction

@export var delay: float = 1.0

func execute(context: SkillContext):
	if(context.user == null):
		return;

	await context.user.get_tree().create_timer(delay).timeout
