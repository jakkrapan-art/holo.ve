extends SkillAction
class_name SkillActionShout

@export var message := ""

func execute(context: SkillContext):
	print(message)
