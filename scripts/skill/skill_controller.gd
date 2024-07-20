extends Node
class_name SkillController

@export var skillList: Array[Resource] = []

func useSkill(index: int, actor, target):
	if skillList[index]:
		var skill: Skill = skillList[index]
		for act in skill.actions:
			if act == null:
				continue

			act.active(actor, target)
