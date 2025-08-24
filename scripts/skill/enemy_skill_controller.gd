class_name EnemySkillController

var skillList: Array[Skill] = [];
var delayUse := 3;

func _init(skills: Array[Skill]):
	pass

func executeSkill():
	if skillList.is_empty():
		return;
