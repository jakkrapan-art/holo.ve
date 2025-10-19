class_name EnemySkillController
extends BaseSkillController

func _init(user: Node, skills: Array[Skill]):
	super._init(user, skills);
	for s in skills:
		(s as EnemySkill).initCooldown();

func onSuccess(skill: Skill):
	super.onSuccess(skill);
	print("Enemy used skill: ", skill.name);
	if skill is EnemySkill:
		(skill as EnemySkill).startCooldown();
