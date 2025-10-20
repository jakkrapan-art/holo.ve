class_name SkillActionSetTargetSelf
extends SkillAction

func execute(context: SkillContext):
	context.target.append(context.user);
