extends SkillAction
class_name SkillActionShout

@export var message := ""

func execute(_context: SkillContext):
	print(message)
